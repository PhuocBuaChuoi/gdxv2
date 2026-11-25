"""
Generate improved mechanical sprites & animated sprite sheets via PixelLab MCP.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import tools.pixellab_client as plc


def get_reusable_upload_url() -> str:
    res = plc.call_mcp("tools/call", {"name": "get_upload_url", "arguments": {}})
    text = "".join(c.get("text", "") for c in res.get("result", {}).get("content", []))
    urls = re.findall(r"https://api\.pixellab\.ai/v2/uploads/[^\s]+", text)
    if not urls:
        raise RuntimeError(f"Failed to parse upload URL from: {text}")
    return urls[0]


def upload_file(upload_url: str, file_path: str) -> str:
    proc = subprocess.run(
        ["curl", "-sS", "-F", f"file=@{file_path}", upload_url],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(proc.stdout)
    ref = data.get("ref", "")
    if not ref:
        raise RuntimeError(f"Upload failed: {proc.stdout}")
    print(f"[+] Uploaded {file_path} -> {ref}")
    return ref


def fetch_animation_frames(job_id: str, frame_count: int, out_strip_path: str) -> bool:
    print(f"[*] Polling animation job {job_id} ({frame_count} frames)...")
    for attempt in range(40):
        poll_res = plc.call_mcp("tools/call", {"name": "get_image", "arguments": {"job_id": job_id}})
        poll_text = "".join(c.get("text", "") for c in poll_res.get("result", {}).get("content", []))
        if "error" in poll_text.lower() or "failed" in poll_text.lower():
            print("[!] Animation job failed:", poll_text)
            return False

        urls = re.findall(r"https?://[^\s)\]\"'<>]+", poll_text)
        if urls:
            # Check if response already lists individual frame URLs or sheet URL
            print(f"[*] Found {len(urls)} URL(s) on completion")
            os.makedirs("scratch/anim_frames", exist_ok=True)
            frames = []
            if len(urls) >= frame_count:
                for i in range(frame_count):
                    tmp = f"scratch/anim_frames/f_{i}.png"
                    urllib.request.urlretrieve(urls[i], tmp)
                    frames.append(Image.open(tmp).convert("RGBA"))
            else:
                # Query each frame index explicitly if needed, or inspect downloaded image
                tmp0 = "scratch/anim_frames/f_main.png"
                urllib.request.urlretrieve(urls[0], tmp0)
                img0 = Image.open(tmp0).convert("RGBA")
                # Also try fetching explicit indices 0..frame_count-1
                fetched_by_idx = []
                for idx in range(frame_count):
                    r_idx = plc.call_mcp("tools/call", {"name": "get_image", "arguments": {"job_id": job_id, "index": idx}})
                    t_idx = "".join(c.get("text", "") for c in r_idx.get("result", {}).get("content", []))
                    u_idx = re.findall(r"https?://[^\s)\]\"'<>]+", t_idx)
                    if u_idx:
                        tmp_i = f"scratch/anim_frames/f_idx_{idx}.png"
                        urllib.request.urlretrieve(u_idx[0], tmp_i)
                        fetched_by_idx.append(Image.open(tmp_i).convert("RGBA"))
                if len(fetched_by_idx) == frame_count:
                    frames = fetched_by_idx
                elif img0.width >= img0.height * frame_count:
                    fw = img0.width // frame_count
                    for i in range(frame_count):
                        frames.append(img0.crop((i * fw, 0, (i + 1) * fw, img0.height)))
                else:
                    frames = [img0]

            w, h = frames[0].size
            strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
            for i, fr in enumerate(frames):
                if fr.size != (w, h):
                    fr = fr.resize((w, h), Image.Resampling.NEAREST)
                strip.paste(fr, (i * w, 0), fr)
            os.makedirs(os.path.dirname(out_strip_path), exist_ok=True)
            strip.save(out_strip_path)
            print(f"[+] Saved {len(frames)}-frame sheet ({strip.width}x{strip.height}) -> {out_strip_path}")
            print(plc.get_balance())
            return True

        print(f"    ... waiting ({attempt + 1}/40): {poll_text[:80]}...")
        time.sleep(3)
    print("[!] Timeout waiting for animation")
    return False


def animate_sprite(upload_url: str, src_path: str, action: str, out_strip_path: str, frame_count: int = 4, loop: bool = True) -> bool:
    ref = upload_file(upload_url, src_path)
    args = {
        "action": action,
        "frame_count": frame_count,
        "first_frame_url": ref,
        "no_background": True,
    }
    if loop:
        args["last_frame_url"] = ref
    print(f"[*] Calling animate_image: '{action}' on {src_path} ({frame_count} frames)...")
    res = plc.call_mcp("tools/call", {"name": "animate_image", "arguments": args})
    text = "".join(c.get("text", "") for c in (res or {}).get("result", {}).get("content", []))
    print(f"[*] Server response: {text}")
    uuids = re.findall(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", text)
    if not uuids:
        print("[!] Could not parse job_id UUID")
        return False
    return fetch_animation_frames(uuids[0], frame_count, out_strip_path)


def generate_mech() -> None:
    plc.generate_sprite(
        "2D side-view flat horizontal sci-fi industrial steel bridge girder block, flush vertical flat square left and right ends so blocks tile seamlessly side by side, dark gunmetal metal chassis with recessed rivets and glowing cyan energy strip along the top edge, pixel art, crisp Geometry Dash neon cyber style, rectangular beam, no wings, no saucer shape",
        width=96,
        height=32,
        output_path="assets/sprites/ai_mech_platform_v2.png",
        detail="medium detail",
        view="side",
    )
    plc.generate_sprite(
        "2D side-view mechanical floor pressure switch button, dark heavy steel flat rectangular base bolted on the floor with a raised glowing emerald green metal pedal plate on top, crisp pixel art, flat bottom, Geometry Dash sci-fi industrial style",
        width=64,
        height=32,
        output_path="assets/sprites/ai_pressure_button_v2.png",
        detail="medium detail",
        view="side",
    )


def generate_animations(only_key: str = "") -> None:
    upload_url = get_reusable_upload_url()
    jobs = [
        (
            "portal",
            "assets/sprites/ai_portal_tall.png",
            "energy vortex swirling smoothly inside the archway portal, glowing runes shimmering gently",
            "assets/sprites/ai_portal_tall_anim.png",
            4,
        ),
        (
            "restore",
            "assets/sprites/restore_point.png",
            "glowing energy crystal floating gently up and down while shimmering inside pedestal ring",
            "assets/sprites/ai_restore_point_anim.png",
            4,
        ),
        (
            "gravity",
            "assets/sprites/gravity_portal.png",
            "purple energy ring swirling and pulsing smoothly in place",
            "assets/sprites/ai_gravity_portal_anim.png",
            4,
        ),
        (
            "crystals",
            "assets/sprites/deco_crystals.png",
            "glowing cyan and purple crystals sparkling and pulsing gently in place",
            "assets/sprites/ai_deco_crystals_anim.png",
            4,
        ),
        (
            "terminal",
            "assets/sprites/deco_terminal.png",
            "sci-fi terminal monitor waveform flickering and status indicator light blinking",
            "assets/sprites/ai_deco_terminal_anim.png",
            4,
        ),
        (
            "vines",
            "assets/sprites/deco_hanging_vines.png",
            "hanging cyber vines and energy cables swaying gently with tiny electrical sparks",
            "assets/sprites/ai_deco_hanging_vines_anim.png",
            4,
        ),
        (
            "pylon",
            "assets/sprites/deco_pylon.png",
            "sci-fi lamp post cyan beacon light glowing and flickering gently",
            "assets/sprites/ai_deco_pylon_anim.png",
            4,
        ),
        (
            "dash_orb",
            "assets/sprites/dash_orb.png",
            "pink neon energy orb pulsing brightly with tiny swirling plasma sparks",
            "assets/sprites/ai_dash_orb_anim.png",
            4,
        ),
        (
            "mech_plat",
            "assets/sprites/ai_mech_platform_v2.png",
            "glowing cyan energy strip flowing horizontally along the steel girder top rail",
            "assets/sprites/ai_mech_platform_v2_anim.png",
            4,
        ),
    ]
    for key, src, action, out, count in jobs:
        if only_key and key != only_key:
            continue
        if os.path.exists(out):
            print(f"[*] Skipping existing {out}")
            continue
        ok = animate_sprite(upload_url, src, action, out, frame_count=count, loop=True)
        if not ok:
            print(f"[!] Stopping on failed animation for {src}")
            break


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--step", choices=["mech", "anim", "all"], default="mech")
    parser.add_argument("--only", default="")
    args = parser.parse_args()
    if args.step in ("mech", "all"):
        generate_mech()
    if args.step in ("anim", "all"):
        generate_animations(args.only)
