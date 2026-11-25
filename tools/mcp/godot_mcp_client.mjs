// Minimal stdio client for the locally installed leftos/godot-mcp.
// Usage:  node tools/mcp/godot_mcp_client.mjs --list
//         node tools/mcp/godot_mcp_client.mjs --script tools/mcp/session.json
//
// Env: GODOT_MCP_EXE (default: %LOCALAPPDATA%/godot-mcp/godot-mcp.exe)
//      GODOT_PATH    (default: <repo>/godot_engine/Godot_v4.7.2-stable_win64_console.exe)

import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import os from "node:os";

const HERE = dirname(fileURLToPath(import.meta.url));
export const REPO = resolve(HERE, "..", "..");

export const GODOT_EXE =
  process.env.GODOT_PATH || join(REPO, "godot_engine", "Godot_v4.7.2-stable_win64_console.exe");
export const SERVER_EXE =
  process.env.GODOT_MCP_EXE || join(os.homedir(), "AppData", "Local", "godot-mcp", "godot-mcp.exe");

export function startServer({ quietStderr = true } = {}) {
  const child = spawn(SERVER_EXE, [], {
    cwd: REPO,
    env: { ...process.env, GODOT_PATH: GODOT_EXE },
    stdio: ["pipe", "pipe", "pipe"],
    windowsHide: true,
  });
  let buf = "";
  let stderrLog = "";
  const pending = new Map();
  const notifications = [];
  let nextId = 1;

  child.stdout.on("data", (chunk) => {
    buf += chunk.toString("utf8");
    let idx;
    while ((idx = buf.indexOf("\n")) >= 0) {
      const line = buf.slice(0, idx).trim();
      buf = buf.slice(idx + 1);
      if (!line) continue;
      let msg;
      try {
        msg = JSON.parse(line);
      } catch {
        continue;
      }
      if (msg.id != null && pending.has(msg.id)) {
        pending.get(msg.id)(msg);
        pending.delete(msg.id);
      } else if (msg.method) {
        notifications.push(msg);
      }
    }
  });
  child.stderr.on("data", (chunk) => {
    const text = chunk.toString("utf8");
    stderrLog += text;
    if (!quietStderr) process.stderr.write(text);
  });
  child.on("exit", (code) => {
    for (const [, reject] of pending) reject(new Error(`server exited (${code})`));
    pending.clear();
  });

  function send(method, params, timeoutMs = 120000) {
    const id = nextId++;
    const payload = { jsonrpc: "2.0", id, method, params };
    return new Promise((res, rej) => {
      pending.set(id, res);
      child.stdin.write(JSON.stringify(payload) + "\n");
      const timer = setTimeout(() => {
        if (pending.has(id)) {
          pending.delete(id);
          rej(new Error(`timeout: ${method}`));
        }
      }, timeoutMs);
      const wrap = pending.get(id);
      pending.set(id, (msg) => {
        clearTimeout(timer);
        wrap(msg);
      });
    });
  }

  async function initialize() {
    const res = await send("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "gdx-play", version: "1.0.0" },
    });
    child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized", params: {} }) + "\n");
    return res.result;
  }

  async function listTools() {
    const res = await send("tools/list", {});
    return res.result?.tools ?? [];
  }

  async function callTool(name, args = {}, timeoutMs) {
    const res = await send("tools/call", { name, arguments: args }, timeoutMs);
    if (res.error) throw new Error(`${name}: ${JSON.stringify(res.error)}`);
    const result = res.result ?? {};
    // Unwrap the MCP content envelope: [{type:"text", text:"<json>"}]
    const texts = (result.content ?? []).filter((c) => c.type === "text").map((c) => c.text);
    let parsed = null;
    for (const t of texts) {
      try {
        parsed = JSON.parse(t);
      } catch {
        /* keep raw */
      }
    }
    return { raw: result, data: parsed, text: texts.join("\n") };
  }

  return { child, initialize, listTools, callTool, send, stop: () => child.kill(), stderr: () => stderrLog };
}

// ---------- CLI ----------
const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const argv = process.argv.slice(2);
  const server = startServer({ quietStderr: !argv.includes("--verbose") });
  try {
    const info = await server.initialize();
    if (argv.includes("--list")) {
      const tools = await server.listTools();
      console.log(`SERVER ${info?.serverInfo?.name} ${info?.serverInfo?.version} — ${tools.length} tools`);
      for (const t of tools) console.log(`- ${t.name}`);
    } else if (argv.includes("--schema")) {
      const wanted = argv[argv.indexOf("--schema") + 1];
      const tools = await server.listTools();
      for (const t of tools.filter((x) => wanted === "*" || x.name === wanted)) {
        console.log(`== ${t.name} ==\n${(t.description || "").slice(0, 500)}\n${JSON.stringify(t.inputSchema)}\n`);
      }
    } else if (argv.includes("--script")) {
      const scriptPath = argv[argv.indexOf("--script") + 1];
      const source = readFileSync(scriptPath, "utf8")
        .replaceAll("${REPO}", REPO.replaceAll("\\", "/"))
        .replaceAll("${GODOT}", GODOT_EXE.replaceAll("\\", "/"));
      const script = JSON.parse(source);
      const results = [];
      for (const step of script.calls) {
        const t0 = Date.now();
        try {
          const out = await server.callTool(step.tool, step.args ?? {}, step.timeoutMs ?? 180000);
          results.push({ tool: step.tool, ok: true, ms: Date.now() - t0, data: out.data, text: out.text });
          console.log(`[ok] ${step.tool} (${Date.now() - t0}ms)`);
          if (step.print !== false) console.log(JSON.stringify(out.data ?? out.text, null, 2).slice(0, 4000));
        } catch (err) {
          results.push({ tool: step.tool, ok: false, ms: Date.now() - t0, error: String(err.message) });
          console.log(`[FAIL] ${step.tool}: ${err.message}`);
        }
        if (step.continueOnError !== true && results.at(-1).ok === false) break;
      }
      const failed = results.filter((r) => !r.ok).length;
      console.log(`\nRESULT steps=${results.length} failed=${failed}`);
      if (script.stopAtEnd !== false) {
        try {
          await server.callTool("stop_project", { session: script.session ?? "gdx-live" }, 60000);
          console.log("[ok] stop_project");
        } catch (err) {
          console.log(`[warn] stop_project: ${err.message}`);
        }
      }
      process.exitCode = failed === 0 ? 0 : 1;
    } else if (argv.includes("--play")) {
      // One-command playthrough: hold a direction, tap jump on a cadence,
      // screenshot + read errors at intervals.
      const get = (flag, dflt) => {
        const i = argv.indexOf(flag);
        return i >= 0 && argv[i + 1] ? argv[i + 1] : dflt;
      };
      const scene = get("--play", "res://levels/level_01.tscn");
      const frames = Number(get("--frames", "600"));
      const jumpEvery = Number(get("--jump-every", "45"));
      const shotEvery = Number(get("--shot-every", "120"));
      const session = get("--session", "gdx-play");
      const outDir = get("--out", ".tmp/mcp");

      console.log(`[play] scene=${scene} frames=${frames}`);
      const run = await server.callTool(
        "run_project",
        {
          projectPath: REPO,
          scene,
          engineArgs: ["--resolution", "960x540"],
          options: { quiet: true, session },
        },
        180000
      );
      console.log(`[play] launched pid=${run.data?.processId ?? "?"}`);
      await server.callTool("wait_for", { condition: { frames: 40 }, session }, 60000);
      await server.callTool("simulate_action", { action: get("--hold", "p1_right"), options: { mode: "press" }, session }, 60000);

      const shots = [];
      let nextShot = 0;
      for (let f = 0; f < frames; f += jumpEvery) {
        await server.callTool("simulate_action", { action: "p1_jump", options: { mode: "tap" }, session }, 60000);
        if (f >= nextShot) {
          const shot = `${outDir}/play_${String(nextShot).padStart(4, "0")}.png`;
          await server.callTool("take_screenshot", { path: shot, responseMode: "path_only", session }, 60000);
          shots.push(shot);
          nextShot += shotEvery;
          const errs = await server.callTool("get_errors", { session }, 60000);
          if ((errs.data?.errors ?? []).length > 0) console.log(`[play] errors at frame ~${f}: ${JSON.stringify(errs.data.errors)}`);
        }
        await server.callTool("wait_for", { condition: { frames: jumpEvery }, session }, 60000);
      }
      await server.callTool("simulate_action", { action: get("--hold", "p1_right"), options: { mode: "release" }, session }, 60000);
      const state = await server.callTool(
        "inspect_node",
        { node: "/root/LevelRoot/Players/PlayerP1", properties: ["form", "global_position", "gravity_direction", "control_locked"], session },
        60000
      );
      const coord = await server.callTool(
        "inspect_node",
        { node: "/root/LevelRoot/RespawnCoordinator", properties: ["attempt_count"], session },
        60000
      );
      const errors = await server.callTool("get_errors", { session }, 60000);
      const output = await server.callTool("get_debug_output", { limit: 60, session }, 60000);
      console.log("PLAY_RESULT " + JSON.stringify({
        scene,
        frames,
        shots,
        p1: state.data?.properties ?? null,
        attempts: coord.data?.properties?.attempt_count ?? null,
        errors: errors.data?.errors ?? [],
        stderrTail: (output.data?.stderr ?? []).slice(-10),
      }, null, 2));
      await server.callTool("stop_project", { session }, 60000);
    } else {
      console.log("usage: --list | --schema <tool|*> | --script <file.json> | --play <scene> [--frames N]");
    }
  } catch (err) {
    console.error("ERROR:", err.message);
    console.error(server.stderr().slice(-2000));
    process.exitCode = 2;
  } finally {
    server.stop();
    setTimeout(() => process.exit(process.exitCode ?? 0), 800);
  }
}
