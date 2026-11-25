"""
Batch PixelLab generator for remaining gdxv2 assets (backgrounds, tiles, traps, mechanisms).
Submits create_image_pixen jobs and polls concurrently until all finish.
"""
import os
import re
import time
import urllib.request
from tools.pixellab_client import call_mcp, get_balance

JOBS = [
    {
        "path": "assets/sprites/ai_bg_cyber_city.png",
        "description": "cyberpunk neon metropolis night skyline, dark deep navy indigo sky, futuristic skyscrapers with glowing cyan and magenta neon windows, distant grid horizon, 16-bit side-view platformer parallax background, no characters",
        "width": 640,
        "height": 360,
        "no_background": False,
        "detail": "highly detailed",
        "outline": "lineless",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_bg_cyber_reactor.png",
        "description": "futuristic sci-fi underground cyber reactor facility interior, dark steel support pillars, glowing cyan energy conduits and holographic laboratory panels, deep navy atmosphere, 2d side-view platformer background, no characters",
        "width": 640,
        "height": 360,
        "no_background": False,
        "detail": "highly detailed",
        "outline": "lineless",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_bg_neon_synth.png",
        "description": "synthwave cyberpunk twilight digital horizon, dark starry sky, glowing neon purple and cyan wireframe mountain silhouettes, retro futuristic grid, 2d side-view platformer background, no characters",
        "width": 640,
        "height": 360,
        "no_background": False,
        "detail": "highly detailed",
        "outline": "lineless",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_tile_cyber_block.png",
        "description": "seamless dark cyberpunk sci-fi metal block tile texture, deep navy steel armor plating with subtle glowing cyan circuit lines and corner rivets, 2d platformer tileset block",
        "width": 48,
        "height": 48,
        "no_background": False,
        "detail": "medium detail",
        "outline": "lineless",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_breakable_wall.png",
        "description": "cracked glowing neon magenta and purple crystal energy barrier block, sci-fi destructible wall tile with bright glowing cracks inside dark armored frame, 2d pixel art game tile",
        "width": 48,
        "height": 48,
        "no_background": False,
        "detail": "medium detail",
        "outline": "lineless",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_mech_platform.png",
        "description": "futuristic sci-fi floating metallic hover platform bridge, sleek dark slate deck with bright glowing cyan neon top trim and energy vents underneath, 2d side-view platformer asset",
        "width": 96,
        "height": 32,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_pressure_button.png",
        "description": "sci-fi floor pressure plate switch pad, dark gunmetal mechanical base with bright glowing neon green energy strip on top, 2d side-view platformer game prop",
        "width": 64,
        "height": 32,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_laser_emitter.png",
        "description": "high-tech sci-fi laser emitter nozzle device mounted facing down, dark gunmetal casing with glowing neon crimson crystal core lens, 2d side-view platformer trap",
        "width": 48,
        "height": 32,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_checkpoint_crystal.png",
        "description": "floating sci-fi holographic diamond checkpoint crystal beacon, glowing bright cyan energy crystal core inside sleek metallic halo, 2d pixel art platformer pickup",
        "width": 48,
        "height": 48,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/ai_cyber_arrow.png",
        "description": "glowing neon cyan holographic cyber directional arrow beacon sign, futuristic sci-fi HUD chevron marker, 2d pixel art game prop",
        "width": 48,
        "height": 48,
        "no_background": True,
        "detail": "low detail",
        "outline": "single color black outline",
        "view": "side",
    },
]


def run_one(job, idx):
    if os.path.exists(job["path"]) and os.path.getsize(job["path"]) > 500:
        print(f"[=] Skipping existing {job['path']}")
        return True
    args = {
        "description": job["description"],
        "width": job["width"],
        "height": job["height"],
        "no_background": job["no_background"],
        "view": job["view"],
        "detail": job["detail"],
        "outline": job["outline"],
    }
    print(f"[*] Submitting {job['path']} ({job['width']}x{job['height']})...")
    job_id = None
    for retry in range(5):
        res = call_mcp("tools/call", {"name": "create_image_pixen", "arguments": args}, req_id=idx + 10 + retry * 100)
        text = "".join(c.get("text", "") for c in (res or {}).get("result", {}).get("content", []))
        uuids = re.findall(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", text)
        if uuids:
            job_id = uuids[0]
            break
        print(f"    ... submit retry ({retry + 1}/5): {text[:120]}")
        time.sleep(5)
    if not job_id:
        print(f"[!] Failed to submit {job['path']}")
        return False

    for attempt in range(45):
        poll_res = call_mcp("tools/call", {"name": "get_image", "arguments": {"job_id": job_id}})
        poll_text = "".join(c.get("text", "") for c in (poll_res or {}).get("result", {}).get("content", []))
        urls = re.findall(r"https?://[^\s)\]\"\'<>]+", poll_text)
        if urls:
            os.makedirs(os.path.dirname(job["path"]), exist_ok=True)
            urllib.request.urlretrieve(urls[0], job["path"])
            print(f"[+] Downloaded {job['path']}")
            return True
        if "error" in poll_text.lower() or "failed" in poll_text.lower():
            print(f"[!] Job failed for {job['path']}: {poll_text}")
            return False
        time.sleep(3)
    print(f"[!] Timed out waiting for {job['path']}")
    return False


def main():
    print("[*] Balance before batch:")
    print(get_balance())

    for idx, job in enumerate(JOBS):
        run_one(job, idx)

    print("[*] Balance after batch:")
    print(get_balance())


if __name__ == "__main__":
    main()
