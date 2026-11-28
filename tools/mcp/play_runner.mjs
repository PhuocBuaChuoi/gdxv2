// Live playthrough driver: REAL injected input via leftos/godot-mcp.
// No teleports, no set_property on players: only simulate_action (keyboard),
// inspect_node (read state) and wait_for (frame clock).
//
// Usage:
//   node tools/mcp/play_runner.mjs --level 1
//   node tools/mcp/play_runner.mjs --all
//
// Evidence: tools/mcp/runs/level_0N.json (positions over time, attempts,
// exit-gate is_done, runtime errors, screenshots).

import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { startServer, REPO } from "./godot_mcp_client.mjs";

const RUNS_DIR = join(REPO, "tools", "mcp", "runs");
const SHOTS_DIR = join(REPO, ".tmp", "mcp", "runs");

function arg(flag, dflt) {
  const i = process.argv.indexOf(flag);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : dflt;
}

const LEVELS = {
  1: { scene: "res://levels/level_01.tscn", play: playLevel1 },
  2: { scene: "res://levels/level_02.tscn", play: playLevel2 },
  3: { scene: "res://levels/level_03.tscn", play: playLevel3 },
  4: { scene: "res://levels/level_04.tscn", play: playLevel4 },
  5: { scene: "res://levels/level_05.tscn", play: playLevel5 },
  6: { scene: "res://levels/level_06.tscn", play: playLevel6 },
};

class Run {
  constructor(server, level, session) {
    this.server = server;
    this.level = level;
    this.session = session;
    this.steps = [];
    this.marks = [];
  }

  async call(name, args = {}, timeoutMs = 25000) {
    const out = await this.server.callTool(name, { ...args, session: this.session }, timeoutMs);
    return out.data;
  }

  async callRaw(name, args = {}, timeoutMs = 60000) {
    const out = await this.server.callTool(name, args, timeoutMs);
    return out.data;
  }

  note(kind, data = {}) {
    this.steps.push({ t: new Date().toISOString(), kind, ...data });
    console.log(`[L${this.level}] ${kind} ${data.id ? "p" + data.id + " " : ""}${data.targetX ?? ""} ${data.reached ? data.reached.x.toFixed(0) + "," + data.reached.y.toFixed(0) : ""} ${data.reached ? "" : JSON.stringify(data).slice(0, 160)}`);
  }

  async frames(n) {
    await this.call("wait_for", { condition: { frames: n } });
  }

  async press(action) {
    await this.call("simulate_action", { action, options: { mode: "press" } });
  }

  async release(action) {
    await this.call("simulate_action", { action, options: { mode: "release" } });
  }

  // A "tap" must last at least one physics tick, otherwise Input polling can
  // miss it entirely (Cube jump reads is_jump_pressed in _physics_process).
  // Drop every movement key; a stale held key makes axis=0 (vx=0) and silently
  // breaks pushing/walking later in the run.
  async clearInputs() {
    for (const action of ["p1_left", "p1_right", "p1_jump", "p1_action", "p2_left", "p2_right", "p2_jump", "p2_action"]) {
      try {
        await this.release(action);
      } catch {
        // action may not exist in a stripped build; ignore
      }
    }
    await this.frames(6);
  }

  // UFO only hops on a fresh press: repeated presses make it descend steadily
  // (used to duck under ceiling spikes without touching them).
  async hopBurst(id, count = 3) {
    for (let i = 0; i < count; i += 1) {
      await this.tap(`p${id}_jump`);
      await this.frames(2);
    }
    this.note("hop_burst", { id, count, at: await this.player(id) });
  }

  async tap(action) {
    await this.press(action);
    await this.frames(3);
    await this.release(action);
  }

  // The engine returns an empty property map when the game is not running;
  // walking a phantom player for minutes hides the real failure.
  async waitReady(id = 1, tries = 24) {
    for (let i = 0; i < tries; i += 1) {
      const p = await this.player(id);
      if (p.x !== 0 || p.y !== 0) return p;
      await this.frames(10);
    }
    return null;
  }

  // UFO + inverted gravity: each tap sets vy = +HOP (away from the ceiling) and
  // gravity pulls it back up, so altitude is held Flappy-Bird style by tapping
  // only when the body drifts too close to the ceiling. Used to duck the 30px
  // ceiling spike that hangs into the 144px top corridor.
  async hopHold(id, targetX, { yNear = 172, yFar = 214, timeoutFrames = 900, sampleEvery = 2 } = {}) {
    const p0 = await this.player(id);
    const dirRight = targetX >= p0.x;
    const dir = dirRight ? `p${id}_right` : `p${id}_left`;
    const jump = `p${id}_jump`;
    await this.press(dir);
    let p = p0;
    let used = 0;
    let taps = 0;
    const trail = [];
    const attempts0 = await this.attempts();
    while (used < timeoutFrames) {
      p = await this.player(id);
      if (dirRight ? p.x >= targetX : p.x <= targetX) break;
      if (p.locked) {
        this.note("death_at", { id, x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form });
        break;
      }
      if (trail.length < 40) trail.push([+p.x.toFixed(0), +p.y.toFixed(0)]);
      if (p.y < yNear) {
        await this.tap(jump);
        taps += 1;
      }
      await this.frames(sampleEvery);
      used += sampleEvery;
    }
    await this.release(dir);
    this.note("hop_hold", {
      id,
      targetX,
      from: { x: +p0.x.toFixed(1), y: +p0.y.toFixed(1) },
      reached: { x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form },
      frames: used,
      taps,
      dead: (await this.attempts()) > attempts0,
      trail,
    });
    return p;
  }

  async player(id) {
    const out = await this.call("inspect_node", {
      node: `/root/LevelRoot/Players/PlayerP${id}`,
      properties: ["global_position", "form", "gravity_direction", "control_locked", "velocity"],
    });
    const p = out?.properties ?? {};
    return {
      x: p.global_position?.x ?? 0,
      y: p.global_position?.y ?? 0,
      vx: p.velocity?.x ?? 0,
      vy: p.velocity?.y ?? 0,
      form: String(p.form ?? ""),
      gravity: p.gravity_direction ?? 1,
      locked: !!p.control_locked,
    };
  }

  async inspect(path, properties) {
    const out = await this.call("inspect_node", { node: path, properties });
    return out?.properties ?? {};
  }

  async attempts() {
    const out = await this.call("inspect_node", {
      node: "/root/LevelRoot/RespawnCoordinator",
      properties: ["attempt_count"],
    });
    return out?.properties?.attempt_count ?? 0;
  }

  async gateDone() {
    const out = await this.call("inspect_node", {
      node: "/root/LevelRoot/Mechanisms/DualExitGate",
      properties: ["_done"],
    });
    return !!out?.properties?._done;
  }

  async errors() {
    const out = await this.call("get_errors", {});
    return out?.errors ?? [];
  }

  async shot(name) {
    try {
      await this.call("take_screenshot", {
        path: `.tmp/mcp/runs/${name}.png`,
        responseMode: "path_only",
        options: { overwrite: true },
      });
      this.note("screenshot", { file: `.tmp/mcp/runs/${name}.png` });
    } catch (err) {
      this.note("screenshot_failed", { name, error: String(err.message) });
    }
  }

  // Walk toward targetX using only held direction keys. Jumps are tapped at
  // explicit world-x triggers (`jumpAt`) or when the player stalls against a
  // step (stallJump). Never sets position.
  async walk(id, targetX, opts = {}) {
    const {
      tol = 12,
      timeoutFrames = 700,
      sampleEvery = 4,
      jumpAt = [],
      stallJump = true,
      jumpHoldFrames = 2,
    } = opts;
    const p0 = await this.player(id);
    const dirRight = targetX >= p0.x;
    const dir = dirRight ? `p${id}_right` : `p${id}_left`;
    const jump = `p${id}_jump`;
    const pending = [...jumpAt];
    await this.press(dir);
    let p = p0;
    let used = 0;
    let lastX = p0.x;
    let stallMs = 0;
    let jumps = 0;
    let maxStep = 0;
    const jumpXs = [];
    const trail = [];
    const attempts0 = await this.attempts();
    while (used < timeoutFrames) {
      await this.frames(sampleEvery);
      used += sampleEvery;
      p = await this.player(id);
      if (trail.length < 60) trail.push([+p.x.toFixed(0), +p.y.toFixed(0), p.form[0]]);
      // Stop on crossing (not on a window): polling steps can be wider than tol.
      const crossed = dirRight ? p.x >= targetX - tol : p.x <= targetX + tol;
      if (crossed) break;
      if (p.locked) {
        this.note("death_at", { id, x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form });
        break;
      }
      // Explicit jump triggers: fire when we cross them in the travel direction.
      while (pending.length) {
        const trigger = pending[0];
        const crossed = dirRight ? p.x >= trigger : p.x <= trigger;
        if (!crossed) break;
        pending.shift();
        jumpXs.push({ trigger, at: +p.x.toFixed(1) });
        await this.tap(jump);
        jumps += 1;
        await this.frames(jumpHoldFrames);
      }
      const moved = Math.abs(p.x - lastX);
      maxStep = Math.max(maxStep, moved);
      lastX = p.x;
      stallMs = moved < 1.5 ? stallMs + sampleEvery * (1000 / 120) : 0;
      if (stallJump && stallMs > 260) {
        await this.tap(jump);
        jumps += 1;
        stallMs = 0;
        await this.frames(8);
      }
    }
    await this.release(dir);
    await this.frames(4);
    p = await this.player(id);
    // Brake correction: kill leftover overshoot with short counter-taps.
    for (let i = 0; i < 4 && Math.abs(p.x - targetX) > tol * 2; i += 1) {
      const back = p.x > targetX ? `p${id}_left` : `p${id}_right`;
      await this.press(back);
      await this.frames(2);
      await this.release(back);
      await this.frames(4);
      p = await this.player(id);
    }
    const att = await this.attempts();
    this.note("walk", {
      id,
      targetX,
      from: { x: +p0.x.toFixed(1), y: +p0.y.toFixed(1) },
      reached: { x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form, gravity: p.gravity },
      frames: used,
      jumps,
      jumpXs,
      maxStep: +maxStep.toFixed(1),
      attempts: att,
      died: att > attempts0,
      trail,
    });
    return p;
  }

  // Ship/ufo altitude-hold flight: held jump = thrust up, released = gentle fall.
  // Bang-bang on y keeps the body inside [yMin, yMax] so it clears pits AND the
  // static pillars above the gates. Never writes position.
  async fly(id, targetX, { yTarget = 385, yMin = 352, yMax = 418, timeoutFrames = 900, sampleEvery = 3, holdJump = true } = {}) {
    const p0 = await this.player(id);
    const dirRight = targetX >= p0.x;
    const dir = dirRight ? `p${id}_right` : `p${id}_left`;
    const jump = `p${id}_jump`;
    await this.press(dir);
    let p = p0;
    let used = 0;
    let jumping = false;
    const trail = [];
    while (used < timeoutFrames) {
      p = await this.player(id);
      const crossed = dirRight ? p.x >= targetX : p.x <= targetX;
      if (crossed) break;
      if (p.locked) {
        this.note("death_at", { id, x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form });
        break;
      }
      if (trail.length < 60) trail.push([+p.x.toFixed(0), +p.y.toFixed(0)]);
      // Hover controller: thrust only while below the band and not already
      // rising fast; release while above it. vy feedback avoids the ~60px
      // momentum overshoot a pure y thermostat causes.
      const wantThrust = holdJump && (
        p.y > yTarget + 6 && p.vy > -110
        || p.y >= yMin && p.y <= yTarget + 6 && p.vy > 60
      );
      if (wantThrust && !jumping) {
        await this.press(jump);
        jumping = true;
      } else if ((!wantThrust || p.y < yMin) && jumping) {
        await this.release(jump);
        jumping = false;
      }
      await this.frames(sampleEvery);
      used += sampleEvery;
    }
    if (jumping) await this.release(jump);
    await this.release(dir);
    this.note("fly", {
      id,
      targetX,
      from: { x: +p0.x.toFixed(1), y: +p0.y.toFixed(1) },
      reached: { x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form },
      frames: used,
      trail,
      attempts: await this.attempts(),
    });
    return p;
  }

  // Push a rigid body left by walking into it, stopping when `done()` is true.
  async pushLeft(id, done, { timeoutFrames = 700, sampleEvery = 3, boxPath = null } = {}) {
    const left = `p${id}_left`;
    await this.clearInputs();
    const boxNow = async () => (boxPath ? await this.inspect(boxPath, ["global_position", "constant_force"]) : null);
    await this.press(left);
    let used = 0;
    let state = null;
    const trail = [];
    while (used < timeoutFrames) {
      await this.frames(sampleEvery);
      used += sampleEvery;
      state = await done();
      const pp = await this.player(id);
      if (trail.length < 40) trail.push({ x: +pp.x.toFixed(1), y: +pp.y.toFixed(1), vx: +pp.vx.toFixed(0), box: (await boxNow())?.global_position?.x, force: (await boxNow())?.constant_force?.x });
      if (state) break;
    }
    await this.release(left);
    await this.frames(10);
    this.note("push_left", { id, frames: used, done: !!state, attempts: await this.attempts(), trail, boxEnd: await boxNow() });
    return state;
  }

  // Normal-gravity UFO climb: tap only while below the target height.
  async hopClimb(id, yTarget, { timeoutFrames = 500 } = {}) {
    let p = await this.player(id);
    let used = 0;
    let taps = 0;
    while (used < timeoutFrames && p.y > yTarget) {
      if (p.locked) break;
      await this.tap(`p${id}_jump`);
      taps += 1;
      used += 3;
      p = await this.player(id);
    }
    this.note("hop_climb", { id, yTarget, reached: { x: +p.x.toFixed(1), y: +p.y.toFixed(1) }, taps });
    return p;
  }

  // Normal-gravity UFO hover while travelling: tap whenever the body sinks.
  async hopAlt(id, targetX, { yMax = 165, timeoutFrames = 500, sampleEvery = 2 } = {}) {
    const p0 = await this.player(id);
    const dirRight = targetX >= p0.x;
    const dir = dirRight ? `p${id}_right` : `p${id}_left`;
    await this.press(dir);
    let p = p0;
    let used = 0;
    let taps = 0;
    while (used < timeoutFrames) {
      p = await this.player(id);
      if (dirRight ? p.x >= targetX : p.x <= targetX) break;
      if (p.locked) {
        this.note("death_at", { id, x: +p.x.toFixed(1), y: +p.y.toFixed(1), form: p.form });
        break;
      }
      if (p.y > yMax) {
        await this.tap(`p${id}_jump`);
        taps += 1;
      }
      await this.frames(sampleEvery);
      used += sampleEvery;
    }
    await this.release(dir);
    this.note("hop_alt", { id, targetX, reached: { x: +p.x.toFixed(1), y: +p.y.toFixed(1) }, taps });
    return p;
  }

  // Poll a blinking hazard until it is dark; walking into an `is_on` beam is a kill.
  async waitOff(nodePath, { timeoutFrames = 600, property = "is_on" } = {}) {
    let used = 0;
    while (used < timeoutFrames) {
      const props = await this.inspect(nodePath, [property]);
      if (!props[property]) return true;
      await this.frames(6);
      used += 6;
    }
    return false;
  }

  // Wait until the player's y stops changing (landed / standing on a platform).
  async waitGrounded(id, { timeoutFrames = 240, sampleEvery = 4 } = {}) {
    let prev = await this.player(id);
    let stable = 0;
    let used = 0;
    while (used < timeoutFrames) {
      await this.frames(sampleEvery);
      used += sampleEvery;
      const p = await this.player(id);
      if (Math.abs(p.y - prev.y) < 0.6) stable += sampleEvery;
      else stable = 0;
      prev = p;
      if (stable >= 12) return p;
    }
    return prev;
  }

  // Retry a walk until it lands near the target (deaths respawn at checkpoints,
  // so one leg may need to be replayed from further back).
  async walkRetry(id, targetX, opts = {}) {
    let p = null;
    for (let attempt = 0; attempt < 3; attempt += 1) {
      p = await this.walk(id, targetX, opts);
      if (Math.abs(p.x - targetX) <= 40) return p;
      await this.frames(60);
      p = await this.player(id);
      if (Math.abs(p.x - targetX) <= 40) return p;
    }
    return p;
  }

  async waitForX(id, targetX, { tol = 12, timeoutFrames = 400, sampleEvery = 5 } = {}) {
    let p = await this.player(id);
    let used = 0;
    while (used < timeoutFrames && Math.abs(p.x - targetX) > tol) {
      await this.frames(sampleEvery);
      used += sampleEvery;
      p = await this.player(id);
    }
    return p;
  }

  async stand(id, ms) {
    await this.frames(Math.round(ms / 8.33));
  }

  async jumpHeld(id, frames) {
    await this.press(`p${id}_jump`);
    await this.frames(frames);
    await this.release(`p${id}_jump`);
  }
}

// ---------------------------------------------------------------------------
// Routes. Each one only uses keyboard input; all positioning is done by walking.
// ---------------------------------------------------------------------------

async function playLevel1(r) {
  // P1 crosses by walking through the cyan trench (spikes safe for P1).
  const p1To = (x, extra = {}) => r.walkRetry(1, x, { jumpAt: [1075], timeoutFrames: 900, ...extra });
  // P2 only crosses the cyan trench over the lowered walkway (jump at x=400).
  const p2To = (x, extra = {}) => r.walkRetry(2, x, { jumpAt: [400], timeoutFrames: 900, ...extra });

  // 1) P1 latches ButtonA (TOGGLE) -> cyan walkway lowers for P2.
  await p1To(1012);
  await r.frames(140); // let the walkway finish its 120px travel
  r.note("button_a", await r.player(1));
  // 2) P2 jumps onto the lowered cyan walkway and walks across to the island.
  await p2To(1012);
  // 3) P2 walks through the orange trench (safe for P2) to ButtonB.
  await p2To(1588);
  await r.frames(140);
  r.note("button_b", await r.player(2));
  // 4) P1 jumps onto the lowered orange walkway and crosses.
  await p1To(1588);
  await r.shot("level_01_mid");
  // 5) Both reach the lift deck at the plateau wall (x=1920).
  await p1To(1886);
  await p2To(1886);
  await r.frames(30);
  r.note("pre_stack", { p1: await r.player(1), p2: await r.player(2) });
  // 6) P2 hops onto P1's head, waits to land, then jumps right onto the plateau.
  await r.tap("p2_jump");
  const onHead = await r.waitGrounded(2);
  r.note("on_head", onHead);
  if (onHead.y < 395) {
    await r.press("p2_right");
    await r.tap("p2_jump");
    await r.frames(90);
    await r.release("p2_right");
    await r.frames(20);
    r.note("after_stack", { p1: await r.player(1), p2: await r.player(2) });
  }
  // 7) P2 stands on ButtonC (HOLD) -> the lift carries P1 up to the plateau.
  await r.walkRetry(2, 2016, { tol: 10, timeoutFrames: 400 });
  await r.frames(170);
  r.note("p1_after_lift", await r.player(1));
  await r.walkRetry(1, 2060, { timeoutFrames: 400 });
  // 8) Both enter the dual exit gate.
  await r.walkRetry(2, 2218, { timeoutFrames: 400 });
  await r.walkRetry(1, 2218, { timeoutFrames: 400 });
  await r.frames(120);
}

async function playLevel2(r) {
  const BUTTON = "/root/LevelRoot/Mechanisms/PressureButton";
  const BOX = "/root/LevelRoot/Mechanisms/CoopBox";
  const buttonOn = async () => !!(await r.inspect(BUTTON, ["is_on"])).is_on;
  const boxX = async () => (await r.inspect(BOX, ["global_position"])).global_position.x;

  // 1) P1 takes the SHIP portal; P2 climbs on the ship's back platform.
  await r.walkRetry(1, 340, { timeoutFrames: 400 });
  await r.walkRetry(2, 340, { timeoutFrames: 400 });
  await r.tap("p2_jump");
  r.note("p2_on_ship", await r.waitGrounded(2));
  // 2) Ship carries P2 over the 7-tile pit, under the ceiling spike.
  await r.fly(1, 900, { yTarget: 385, yMin: 356, yMax: 420, timeoutFrames: 500 });
  await r.frames(60);
  r.note("after_flight", { p1: await r.player(1), p2: await r.player(2) });
  // 3) Ship hops OVER the box (bottom 372 clears box top 392) and lands to its right.
  await r.fly(1, 1180, { yTarget: 348, yMin: 330, yMax: 386, timeoutFrames: 600 });
  await r.frames(70);
  r.note("after_hop", { p1: await r.player(1), p2: await r.player(2), box_x: await boxX() });
  // 4) P2 steps off to the right of the box, then pushes it LEFT onto the HOLD button.
  await r.walkRetry(2, 1215, { timeoutFrames: 300 });
  const pushed = await r.pushLeft(2, async () => (await boxX()) <= 1020, {
    timeoutFrames: 500,
    boxPath: BOX,
  });
  await r.frames(40);
  r.note("button_state", { is_on: await buttonOn(), box_x: await boxX() });
  await r.shot("level_02_box");
  if (!(await buttonOn())) throw new Error(`box never rested on the pressure button (box x=${(await boxX()).toFixed(1)})`);
  // 5) Ship flies through the open gate lane (y band 336..432) over the orange pit.
  await r.fly(1, 1800, { yTarget: 392, yMin: 372, yMax: 420, timeoutFrames: 900 });
  await r.frames(60);
  r.note("p1_past_orange", await r.player(1));
  // 6) P2 follows on foot through the gate and the orange pit (safe for P2).
  await r.walkRetry(2, 1760, { timeoutFrames: 900 });
  r.note("p2_past_orange", await r.player(2));
  r.note("button_after_p2", { is_on: await buttonOn(), box_x: await boxX() });
  // 7) CUBE portal at 1840 turns the ship back into a cube; then both enter the exit gate.
  await r.walkRetry(1, 1860, { timeoutFrames: 500 });
  r.note("p1_after_cube_portal", await r.player(1));
  await r.walkRetry(2, 2170, { timeoutFrames: 700 });
  await r.walkRetry(1, 2170, { timeoutFrames: 700 });
  await r.frames(120);
}

async function playLevel3(r) {
  const gateOpen = async (name) => !!(await r.inspect(`/root/LevelRoot/Mechanisms/${name}`, ["is_open"])).is_open;
  const buttonOn = async (name) => !!(await r.inspect(`/root/LevelRoot/Mechanisms/${name}`, ["is_on"])).is_on;

  // 1) P2 walks the floor lane first (a death here respawns P1 too), clearing the
  //    neutral floor spike at x=632..728. Sample every 2 frames (~7px) so the jump
  //    trigger fires well before the hitbox instead of 40px past it.
  await r.walkRetry(2, 1000, { jumpAt: [500], sampleEvery: 2, timeoutFrames: 1200 });
  r.note("p2_at_button", await r.player(2));
  // 2) P1 steps into the gravity portal (280) -> rises under the mid platform.
  await r.walkRetry(1, 288, { timeoutFrames: 400 });
  await r.frames(90);
  r.note("p1_inverted", await r.player(1));
  // 3) Drift right past the platform edge (336) -> rises to the ceiling lane.
  await r.walkRetry(1, 380, { timeoutFrames: 300 });
  await r.frames(120);
  r.note("p1_ceiling", await r.player(1));
  // 4) UFO portal at 440 on the ceiling lane.
  await r.walkRetry(1, 450, { timeoutFrames: 300 });
  await r.frames(40);
  r.note("p1_ufo", await r.player(1));
  // 5) Duck the 30px ceiling spike at 680..? by flying mid-corridor with UFO
  //    taps, then let inverted gravity re-attach to the ceiling past it.
  await r.walkRetry(1, 470, { timeoutFrames: 300 });
  // Tap threshold 196 keeps the hull ~70px below the 102..126 spike hitbox even
  // with one ~25px rise between MCP reads; 780 is still inside the jump shaft, so
  // inverted gravity then carries the UFO back up to the ceiling.
  await r.hopHold(1, 780, { yNear: 196, yFar: 232, timeoutFrames: 700 });
  await r.frames(90);
  await r.walkRetry(1, 1000, { timeoutFrames: 500 });
  r.note("p1_at_button", await r.player(1));
  // 6) SIMULTANEOUS pair (<0.5s window). A plate only fires body_entered on
  //    ENTRY, so both players must stand clear of their plates first: P2 had
  //    parked on the lower plate and P1 was already touching the upper one.
  await r.walkRetry(2, 960, { timeoutFrames: 400 });
  await r.walkRetry(1, 950, { timeoutFrames: 400 });
  await r.press("p1_right");
  await r.press("p2_right");
  await r.frames(26);
  await r.release("p1_right");
  await r.release("p2_right");
  await r.frames(40);
  r.note("buttons_raw", { top: await buttonOn("ButtonTop"), bottom: await buttonOn("ButtonBottom") });
  const latched = { top: await gateOpen("MiddleWall"), bottom: await gateOpen("LowerWall") };
  r.note("buttons_latched", latched);
  await r.shot("level_03_gate");
  if (!latched.top || !latched.bottom) {
    throw new Error(`simultaneous buttons did not open both gates: ${JSON.stringify(latched)}`);
  }
  // 7) P1 crosses to the exit gravity portal on the ceiling and drops to the floor.
  await r.walkRetry(1, 1690, { timeoutFrames: 900 });
  await r.frames(160);
  r.note("p1_back_normal", await r.player(1));
  // 8) P2 follows through the opened gates; both take the CUBE portal then exit.
  await r.walkRetry(2, 1900, { timeoutFrames: 1200 });
  await r.walkRetry(1, 1910, { timeoutFrames: 600 });
  r.note("p1_after_cube_portal", await r.player(1));
  await r.walkRetry(2, 2170, { timeoutFrames: 500 });
  await r.walkRetry(1, 2170, { timeoutFrames: 500 });
  await r.frames(120);
}

async function playLevel4(r) {
  const LASER = "/root/LevelRoot/Hazards/LaserGate";
  const doorOpen = async () => !!(await r.inspect("/root/LevelRoot/Mechanisms/ExitPlatformDoor", ["is_open"])).is_open;

  // 1) Both take the DASH portal. The portal used to be P1_ONLY, which left P2
  //    (cube) with no way across the 192px spiked pit at 432..624 at all.
  await r.walkRetry(1, 336, { timeoutFrames: 400 });
  await r.walkRetry(2, 336, { timeoutFrames: 500 });
  await r.frames(25);
  r.note("dash_forms", { p1: await r.player(1), p2: await r.player(2) });
  if ((await r.player(2)).form !== "DASH") throw new Error("P2 did not become DASH");

  // 2) Dash from the pit lip through the breakable wall and land past 624.
  for (const id of [1, 2]) {
    await r.walk(id, 424, { tol: 6, timeoutFrames: 300 });
    await r.press(`p${id}_action`);
    await r.frames(4);
    await r.release(`p${id}_action`);
    await r.frames(45);
    const p = await r.player(id);
    r.note("after_dash", { id, p });
    if (p.x < 630) throw new Error(`P${id} dash did not clear the pit (x=${p.x.toFixed(1)})`);
  }

  // 3) P2 hops the 1-tile hole at 720..768 and takes the SHIP portal at 920.
  await r.walk(2, 700, { tol: 10, timeoutFrames: 300 });
  await r.tap("p2_jump");
  await r.frames(70);
  await r.walkRetry(2, 920, { timeoutFrames: 400 });
  await r.frames(20);
  r.note("p2_ship", await r.player(2));

  // 4) P1 hops the hole and stops before the blinking laser (1138..1162).
  await r.walk(1, 700, { tol: 10, timeoutFrames: 300 });
  await r.tap("p1_jump");
  await r.frames(70);
  await r.walkRetry(1, 1100, { timeoutFrames: 400 });
  r.note("p1_before_laser", await r.player(1));

  // 5) P2 flies the corridor: laser dark, over the floor spike (top 402) at y=350,
  //    then down to y=390 to slip under the ceiling pillar into the door lane.
  await r.fly(2, 1100, { yTarget: 352, yMin: 334, yMax: 378, timeoutFrames: 500 });
  if (!(await r.waitOff(LASER))) throw new Error("laser never switched off");
  r.note("laser_off_p2");
  await r.fly(2, 1330, { yTarget: 350, yMin: 334, yMax: 376, timeoutFrames: 600 });
  await r.fly(2, 1650, { yTarget: 380, yMin: 366, yMax: 392, timeoutFrames: 600 });

  // 6) P1 waits for the dark phase and jumps the spike, landing on the UFO portal.
  if (!(await r.waitOff(LASER))) throw new Error("laser never switched off");
  r.note("laser_off_p1");
  await r.walk(1, 1480, { jumpAt: [1170], sampleEvery: 2, timeoutFrames: 400 });
  r.note("p1_dash_clear", await r.player(1));
  // 7) UFO up to the ceiling button at (1600,106), then down through the door.
  await r.hopClimb(1, 150, { timeoutFrames: 600 });
  await r.hopAlt(1, 1600, { yMax: 165, timeoutFrames: 400 });
  await r.frames(30);
  r.note("ceiling_button", { p1: await r.player(1), door: await doorOpen() });
  await r.frames(70);
  for (let i = 0; i < 20 && !(await doorOpen()); i += 1) await r.frames(10);
  if (!(await doorOpen())) throw new Error("ExitPlatformDoor never opened");

  // 8) Both pass the 96px door lane (336..432) and finish on the exit gate.
  await r.fly(2, 1860, { yTarget: 390, yMin: 372, yMax: 400, timeoutFrames: 700 });
  await r.walkRetry(1, 1860, { timeoutFrames: 600 });
  await r.walkRetry(2, 2000, { timeoutFrames: 600 });
  await r.walkRetry(1, 2000, { timeoutFrames: 600 });
  await r.walkRetry(2, 2150, { timeoutFrames: 400 });
  await r.walkRetry(1, 2150, { timeoutFrames: 400 });
  await r.frames(120);
}

async function playLevel5(r) {
  // P1 stands on box A -> box B rises; P2 rides B across the first trench.
  await r.walk(1, 530, { jump: true, timeoutFrames: 400 });
  await r.walk(2, 700, { jump: true, timeoutFrames: 500 });
  await r.frames(60);
  r.note("float_pair", { p1: await r.player(1), p2: await r.player(2) });
  await r.walk(2, 850, { jump: true, timeoutFrames: 400 });
  await r.frames(40);
  // P2 latches ButtonA -> BridgeA lowers for P1.
  await r.walk(1, 850, { jump: true, timeoutFrames: 500 });
  // Both press the polarised buttons -> MidGate opens.
  await r.walk(1, 1140, { jump: true, timeoutFrames: 400 });
  await r.walk(2, 1265, { jump: true, timeoutFrames: 400 });
  await r.frames(60);
  r.note("mid_gate_buttons", { p1: await r.player(1), p2: await r.player(2) });
  // One player climbs the one-way steps to the high block and toggles ButtonHigh.
  await r.walk(1, 900, { jump: true, timeoutFrames: 400 });
  await r.press("p1_jump");
  await r.press("p1_left");
  await r.frames(70);
  await r.release("p1_left");
  await r.press("p1_jump");
  await r.press("p1_right");
  await r.frames(60);
  await r.press("p1_left");
  await r.frames(50);
  await r.release("p1_left");
  await r.release("p1_jump");
  r.note("high_block", await r.player(1));
  // Cross the second trench over the raised lift.
  await r.walk(1, 1560, { jump: true, timeoutFrames: 500 });
  await r.walk(2, 1560, { jump: true, timeoutFrames: 500 });
  await r.walk(1, 2200, { jump: true, timeoutFrames: 500 });
  await r.walk(2, 2200, { jump: true, timeoutFrames: 500 });
  await r.frames(120);
}

async function playLevel6(r) {
  // P1 gravity portal -> ceiling, UFO portal, ceiling laser timing.
  await r.walk(1, 300, { timeoutFrames: 300 });
  await r.frames(120);
  await r.walk(1, 420, { jump: true, timeoutFrames: 300 });
  await r.frames(20);
  r.note("p1_ufo", await r.player(1));
  // P2 pushes the box onto the floor button, then both reach the sync buttons.
  await r.walk(2, 780, { jump: true, timeoutFrames: 600 });
  await r.walk(2, 900, { timeoutFrames: 400 });
  await r.walk(1, 1240, { jump: true, timeoutFrames: 900 });
  await r.walk(2, 1240, { jump: true, timeoutFrames: 600 });
  await r.frames(90);
  r.note("sync_buttons", { p1: await r.player(1), p2: await r.player(2) });
  // P1 to the exit gravity portal, then the cube portal.
  await r.walk(1, 1500, { jump: true, timeoutFrames: 500 });
  await r.frames(120);
  await r.walk(1, 1620, { jump: true, timeoutFrames: 300 });
  // P2 -> DASH and dash through the breakable wall.
  await r.walk(2, 1700, { jump: true, timeoutFrames: 400 });
  await r.frames(20);
  await r.tap("p2_action");
  await r.frames(50);
  r.note("after_dash", await r.player(2));
  await r.walk(2, 2000, { jump: true, timeoutFrames: 400 });
  await r.walk(1, 2000, { jump: true, timeoutFrames: 400 });
  await r.walk(1, 2180, { jump: true, timeoutFrames: 400 });
  await r.walk(2, 2180, { jump: true, timeoutFrames: 400 });
  await r.frames(120);
}

// ---------------------------------------------------------------------------

async function runLevel(server, num) {
  const spec = LEVELS[num];
  const session = `gdx-play-${num}`;
  const r = new Run(server, num, session);
  const watchdog = setTimeout(() => {
    console.error(`WATCHDOG level ${num} stuck after 300s`);
    process.exit(4);
  }, 300000);
  mkdirSync(RUNS_DIR, { recursive: true });
  mkdirSync(SHOTS_DIR, { recursive: true });
  const started = Date.now();
  let error = null;
  try {
    // run_project takes the session inside `options` (no top-level session arg).
    await r.callRaw("run_project", {
      projectPath: REPO,
      scene: spec.scene,
      engineArgs: ["--resolution", "960x540"],
      options: { quiet: true, session },
    }, 180000);
    const ready = await r.waitReady(1);
    if (ready == null) {
      const dbg = await r.call("inspect_node", { node: "/root/LevelRoot", properties: ["name"] });
      throw new Error(`game state unreadable after run_project (properties=${JSON.stringify(dbg?.properties ?? null)})`);
    }
    r.note("spawn", { p1: ready, p2: await r.player(2) });
    await spec.play(r);
    await r.frames(90);
    const done = await r.gateDone();
    const p1 = await r.player(1);
    const p2 = await r.player(2);
    const attempts = await r.attempts();
    const errs = await r.errors();
    await r.shot(`level_0${num}_end`);
    const passed = done;
    const report = {
      level: num,
      scene: spec.scene,
      passed,
      gateDone: done,
      p1,
      p2,
      attempts,
      errors: errs,
      seconds: +((Date.now() - started) / 1000).toFixed(1),
      steps: r.steps,
    };
    writeFileSync(join(RUNS_DIR, `level_0${num}.json`), JSON.stringify(report, null, 2));
    console.log(`LEVEL ${num}: ${passed ? "PASSED" : "NOT COMPLETED"} gateDone=${done} attempts=${attempts} p1=${p1.x.toFixed(0)},${p1.y.toFixed(0)}(${p1.form}) p2=${p2.x.toFixed(0)},${p2.y.toFixed(0)}(${p2.form}) errors=${errs.length}`);
    return passed;
  } catch (e) {
    error = String(e.message);
    console.log(`LEVEL ${num}: ERROR ${error}`);
    try {
      const p1 = await r.player(1);
      const p2 = await r.player(2);
      writeFileSync(
        join(RUNS_DIR, `level_0${num}.json`),
        JSON.stringify({ level: num, scene: spec.scene, passed: false, error, p1, p2, steps: r.steps }, null, 2)
      );
    } catch {}
    return false;
  } finally {
    clearTimeout(watchdog);
    try {
      await r.call("stop_project", {}, 60000);
    } catch {}
  }
}

const server = startServer({ quietStderr: true });
let ok = true;
try {
  await server.initialize();
  const which = arg("--level", null);
  const nums = which ? [Number(which)] : [1, 2, 3, 4, 5, 6];
  for (const n of nums) {
    const passed = await runLevel(server, n);
    ok = ok && passed;
  }
} catch (err) {
  console.error("RUNNER ERROR:", err.message);
  console.error(server.stderr().slice(-3000));
  ok = false;
} finally {
  server.stop();
  setTimeout(() => process.exit(ok ? 0 : 1), 1000);
}
