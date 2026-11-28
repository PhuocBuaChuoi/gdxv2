// Temporary live probe (level 3): what kills P1 right after the UFO portal?
import { startServer, REPO } from "./godot_mcp_client.mjs";

const session = "gdx-probe3";
const server = await startServer();
const call = async (name, args, t = 25000) => (await server.callTool(name, { ...args, session }, t)).data;
const frames = (n) => call("wait_for", { condition: { frames: n } });
const press = (a) => call("simulate_action", { action: a, options: { mode: "press" } });
const release = (a) => call("simulate_action", { action: a, options: { mode: "release" } });
const p = async (id) => {
  const o = await call("inspect_node", {
    node: `/root/LevelRoot/Players/PlayerP${id}`,
    properties: ["global_position", "velocity", "form", "gravity_direction", "control_locked"],
  });
  return o.properties;
};
const attempts = async () => (await call("inspect_node", { node: "/root/LevelRoot/RespawnCoordinator", properties: ["attempt_count"] })).properties.attempt_count;

try {
  await server.callTool("run_project", {
    projectPath: REPO,
    scene: "res://levels/level_03.tscn",
    engineArgs: ["--resolution", "960x540"],
    options: { quiet: true, session },
  }, 180000);
  await frames(30);
  // P1 to the gravity portal
  await press("p1_right");
  for (let i = 0; i < 60; i += 1) {
    await frames(4);
    const pp = await p(1);
    if (pp.global_position.x >= 285) break;
  }
  await release("p1_right");
  await frames(60);
  console.log("after portal", JSON.stringify(await p(1)), "att", await attempts());
  // right into the one-way gap
  await press("p1_right");
  for (let i = 0; i < 60; i += 1) {
    await frames(4);
    const pp = await p(1);
    if (pp.global_position.x >= 395) break;
  }
  await release("p1_right");
  for (let i = 0; i < 10; i += 1) {
    await frames(30);
    console.log(i, JSON.stringify(await p(1)), "att", await attempts());
  }
  // to the UFO portal
  await press("p1_right");
  for (let i = 0; i < 60; i += 1) {
    await frames(4);
    const pp = await p(1);
    if (pp.global_position.x >= 440) break;
  }
  await release("p1_right");
  for (let i = 0; i < 12; i += 1) {
    await frames(30);
    console.log("UFO", i, JSON.stringify(await p(1)), "att", await attempts());
  }
} catch (err) {
  console.error("PROBE ERROR", err?.message ?? err);
} finally {
  try { await call("stop_project", {}, 60000); } catch {}
  server.stop();
  setTimeout(() => process.exit(0), 800);
}
