"""
Generate pixel-art UI hero logo, 9-slice panel frame, and 9-slice arcade button textures via PixelLab MCP.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import tools.pixellab_client as plc


def run_pixen(description: str, width: int, height: int, output_path: str) -> bool:
    print(f"[*] Calling create_image_pixen ({width}x{height}) -> {output_path}...")
    res = plc.call_mcp("tools/call", {
        "name": "create_image_pixen",
        "arguments": {
            "description": description,
            "width": width,
            "height": height,
            "no_background": True,
            "view": "side",
            "detail": "medium detail",
        },
    })
    text = "".join(c.get("text", "") for c in (res or {}).get("result", {}).get("content", []))
    print(f"[*] Server response: {text}")
    uuids = re.findall(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", text)
    if not uuids:
        print("[!] Failed to parse job UUID")
        return False
    return plc.fetch_job(uuids[0], output_path)


def main() -> None:
    print(plc.get_balance())

    # 1. Stylized Pixel-Art Title Logo: "GDXV2"
    run_pixen(
        "Bold stylized pixel art arcade game title logo spelling 'GDXV2', chunky beveled metallic cyan and glowing electric blue chrome 3D letters with dark outline and orange cyber tech wings on both sides, retro sci-fi game emblem, no subtitle",
        320, 96,
        "assets/sprites/ai_ui_logo_gdxv2.png",
    )

    # 2. 9-Slice Cyber Panel Frame
    run_pixen(
        "2D front-view sci-fi dark steel pixel art game UI panel frame box, chamfered octagonal metallic corners with rivets and glowing neon cyan inner trim line, clean uniform dark navy empty center, symmetrical",
        160, 160,
        "assets/sprites/ai_ui_panel_raw.png",
    )

    # 3. 9-Slice Arcade Cyber Button Texture
    run_pixen(
        "2D front-view wide horizontal sci-fi pixel art game UI button bar, sculpted chamfered octagonal dark titanium metal frame, glowing cyan inner neon bevel edge, corner bolts, clean uniform dark navy empty interior, symmetrical",
        160, 56,
        "assets/sprites/ai_ui_btn_raw.png",
    )


if __name__ == "__main__":
    main()
