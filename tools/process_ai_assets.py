"""
Process AI-generated sprites from PixelLab into game-ready textures with proper dimensions and color variants.
"""
from PIL import Image, ImageEnhance, ImageOps
import os

SPRITES_DIR = "assets/sprites"


def tint_image(img: Image.Image, target_rgb: tuple) -> Image.Image:
    """Tint the vibrant/glowing pixels of an image toward target_rgb while preserving dark metal shading."""
    rgba = img.convert("RGBA")
    r, g, b, a = rgba.split()
    pixels = list(rgba.getdata())
    new_pixels = []
    
    tr, tg, tb = target_rgb
    for pr, pg, pb, pa in pixels:
        if pa < 10:
            new_pixels.append((0, 0, 0, 0))
            continue
        
        # Calculate saturation / brightness
        brightness = (pr + pg + pb) / 3.0
        max_c = max(pr, pg, pb)
        min_c = min(pr, pg, pb)
        diff = max_c - min_c
        
        # If it's a dark metallic pixel (low saturation or dark), keep metallic
        if brightness < 60 and diff < 30:
            new_pixels.append((pr, pg, pb, pa))
        elif diff > 25 or brightness > 140:
            # It's an accent / glow / highlight pixel! Tint it to target color
            factor = brightness / 255.0
            nr = int(tr * factor * 0.85 + pr * 0.15)
            ng = int(tg * factor * 0.85 + pg * 0.15)
            nb = int(tb * factor * 0.85 + pb * 0.15)
            new_pixels.append((min(255, nr), min(255, ng), min(255, nb), pa))
        else:
            new_pixels.append((pr, pg, pb, pa))
            
    out = Image.new("RGBA", rgba.size)
    out.putdata(new_pixels)
    return out


def process_spikes():
    raw_path = os.path.join(SPRITES_DIR, "ai_spike_raw.png")
    if not os.path.exists(raw_path):
        print("[!] ai_spike_raw.png not found")
        return
        
    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox) # 44x48 approx
    
    # Place onto a 48x48 canvas centered horizontally, resting on base
    canvas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    # Scale slightly if needed to fit 46x44
    target_h = 44
    aspect = cropped.width / cropped.height
    target_w = int(target_h * aspect)
    scaled = cropped.resize((target_w, target_h), Image.Resampling.NEAREST)
    
    paste_x = (48 - target_w) // 2
    paste_y = 48 - target_h # bottom-aligned
    canvas.paste(scaled, (paste_x, paste_y), scaled)
    
    # 1. Red (Neutral)
    red_spike = tint_image(canvas, (255, 42, 85))
    red_spike.save(os.path.join(SPRITES_DIR, "spike_red.png"))
    print("[+] Created AI spike_red.png (48x48)")
    
    # 2. Cyan (Safe P1)
    cyan_spike = tint_image(canvas, (47, 224, 255))
    cyan_spike.save(os.path.join(SPRITES_DIR, "spike_cyan.png"))
    print("[+] Created AI spike_cyan.png (48x48)")
    
    # 3. Orange (Safe P2)
    orange_spike = tint_image(canvas, (255, 138, 0))
    orange_spike.save(os.path.join(SPRITES_DIR, "spike_orange.png"))
    print("[+] Created AI spike_orange.png (48x48)")


def process_portals():
    raw_path = os.path.join(SPRITES_DIR, "ai_portal_tall.png")
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SPRITES_DIR, "ai_portal.png")
    if not os.path.exists(raw_path):
        print("[!] ai_portal_tall.png not found")
        return

    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox) if bbox else img

    # Fit completely inside (60, 96) WITHOUT clipping left/right arches!
    scale = min(60.0 / cropped.width, 94.0 / cropped.height)
    target_w = max(1, int(round(cropped.width * scale)))
    target_h = max(1, int(round(cropped.height * scale)))
    scaled = cropped.resize((target_w, target_h), Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    paste_x = (64 - target_w) // 2
    paste_y = (96 - target_h) // 2
    canvas.paste(scaled, (paste_x, paste_y), scaled)

    # Variants for FormPortal
    variants = {
        "portal_cube.png": (47, 224, 255),    # Cyan
        "portal_ship.png": (70, 150, 255),    # Blue
        "portal_ufo.png": (220, 60, 255),     # Magenta / Purple
        "portal_dash.png": (255, 90, 40),     # Orange / Red
    }

    for filename, rgb in variants.items():
        p_img = tint_image(canvas, rgb)
        p_img.save(os.path.join(SPRITES_DIR, filename))
        print(f"[+] Created AI {filename} ({target_w}x{target_h} inside 64x96)")


def process_box():
    raw_path = os.path.join(SPRITES_DIR, "ai_box.png")
    if not os.path.exists(raw_path):
        print("[*] ai_box.png not ready yet")
        return
        
    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    scaled = cropped.resize((40, 40), Image.Resampling.NEAREST)
    scaled.save(os.path.join(SPRITES_DIR, "coop_box.png"))
    print("[+] Created AI coop_box.png (40x40)")


def process_breakable_wall():
    raw_path = os.path.join(SPRITES_DIR, "ai_breakable_wall.png")
    if not os.path.exists(raw_path):
        print("[!] ai_breakable_wall.png not found")
        return
    img = Image.open(raw_path).convert("RGBA").resize((48, 48), Image.Resampling.NEAREST)
    img.save(os.path.join(SPRITES_DIR, "breakable_dash_wall.png"))
    print("[+] Created AI breakable_dash_wall.png (48x48)")


def process_mech_platform():
    raw_path = os.path.join(SPRITES_DIR, "ai_mech_platform_v2.png")
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SPRITES_DIR, "ai_mech_platform.png")
    if not os.path.exists(raw_path):
        print("[!] ai_mech_platform_v2.png not found")
        return
    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox) if bbox else img
    # Trim 1px outer black outline on left/right so side-by-side 96px segments connect cleanly as a continuous bridge
    if cropped.width > 8:
        cropped = cropped.crop((1, 0, cropped.width - 1, cropped.height))
    scaled = cropped.resize((96, 24), Image.Resampling.NEAREST)
    scaled.save(os.path.join(SPRITES_DIR, "mechanized_platform.png"))
    print("[+] Created AI mechanized_platform.png (96x24 seamless girder)")


def process_checkpoints():
    raw_path = os.path.join(SPRITES_DIR, "ai_checkpoint_crystal.png")
    if not os.path.exists(raw_path):
        print("[!] ai_checkpoint_crystal.png not found")
        return
    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox) if bbox else img
    # Fit inside 44x44 centered on 48x48 canvas
    scaled = cropped.resize((42, 42), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    canvas.paste(scaled, (3, 3), scaled)
    canvas.save(os.path.join(SPRITES_DIR, "restore_point.png"))
    active = tint_image(canvas, (55, 255, 110))
    active.save(os.path.join(SPRITES_DIR, "restore_point_active.png"))
    print("[+] Created AI restore_point.png + restore_point_active.png (48x48)")


def process_button_and_emitter():
    # Build strictly horizontal 2D side-view pressure switch from AI steel girder deck (tinted emerald neon)
    btn_src = os.path.join(SPRITES_DIR, "ai_mech_platform_v2.png")
    if not os.path.exists(btn_src):
        btn_src = os.path.join(SPRITES_DIR, "ai_mech_platform.png")
    if os.path.exists(btn_src):
        img = Image.open(btn_src).convert("RGBA")
        bbox = img.getbbox()
        cropped = img.crop(bbox) if bbox else img
        base_pad = cropped.resize((72, 18), Image.Resampling.NEAREST)
        normal = tint_image(base_pad, (55, 235, 130))
        normal_canvas = Image.new("RGBA", (72, 20), (0, 0, 0, 0))
        normal_canvas.paste(normal, (0, 1), normal)
        normal_canvas.save(os.path.join(SPRITES_DIR, "pressure_button.png"))

        pressed_pad = tint_image(cropped.resize((72, 13), Image.Resampling.NEAREST), (140, 255, 110))
        pressed_canvas = Image.new("RGBA", (72, 20), (0, 0, 0, 0))
        pressed_canvas.paste(pressed_pad, (0, 7), pressed_pad)
        pressed_canvas.save(os.path.join(SPRITES_DIR, "pressure_button_pressed.png"))
        print("[+] Created AI horizontal pressure_button.png + pressure_button_pressed.png (72x20)")

    em_path = os.path.join(SPRITES_DIR, "ai_laser_emitter_flat.png")
    if not os.path.exists(em_path):
        em_path = os.path.join(SPRITES_DIR, "ai_laser_emitter.png")
    if os.path.exists(em_path):
        img = Image.open(em_path).convert("RGBA")
        bbox = img.getbbox()
        cropped = img.crop(bbox) if bbox else img
        emitter = cropped.resize((32, 20), Image.Resampling.NEAREST)
        emitter.save(os.path.join(SPRITES_DIR, "laser_emitter.png"))
        print("[+] Created AI laser_emitter.png (32x20)")


def process_tileset_atlas():
    """Composite AI cyberpunk block texture into neon_tiles_atlas.png preserving exact autotile borders & physics."""
    tile_src_path = os.path.join(SPRITES_DIR, "ai_tile_cyber_block.png")
    atlas_path = "resources/neon_tiles_atlas.png"
    if not os.path.exists(tile_src_path) or not os.path.exists(atlas_path):
        print("[!] Missing tile or atlas source for tileset upgrade")
        return

    base_tile = Image.open(tile_src_path).convert("RGBA").resize((48, 48), Image.Resampling.NEAREST)
    # Darken interior tile (~58%) so gameplay foreground objects pop cleanly!
    dark_tile = ImageEnhance.Brightness(base_tile).enhance(0.58)
    atlas = Image.open(atlas_path).convert("RGBA")
    TILE = 48
    COLS = 4

    NEON_HOT = (232, 252, 255, 255)
    NEON = (47, 224, 255, 255)
    NEON_SOFT = (27, 174, 204, 255)
    NEON_DIM = (14, 95, 115, 255)

    def paint_cell(tx, ty, mask):
        ox, oy = tx * TILE, ty * TILE
        atlas.paste(dark_tile, (ox, oy))
        px = atlas.load()
        # Redraw seamless neon border edges according to autotile mask (N=1, E=2, S=4, W=8)
        if mask & 8:  # W
            for y in range(oy, oy + TILE):
                px[ox, y] = NEON_SOFT
                px[ox + 1, y] = NEON_SOFT
                px[ox + 2, y] = NEON
                px[ox + 3, y] = NEON_DIM
        if mask & 2:  # E
            for y in range(oy, oy + TILE):
                px[ox + TILE - 1, y] = NEON_SOFT
                px[ox + TILE - 2, y] = NEON_SOFT
                px[ox + TILE - 3, y] = NEON
                px[ox + TILE - 4, y] = NEON_DIM
        if mask & 1:  # N (runway top)
            for x in range(ox, ox + TILE):
                px[x, oy] = NEON_HOT
                px[x, oy + 1] = NEON
                px[x, oy + 2] = NEON
                px[x, oy + 3] = NEON_SOFT
                px[x, oy + 4] = NEON_DIM
        if mask & 4:  # S (ceiling bottom)
            for x in range(ox, ox + TILE):
                px[x, oy + TILE - 1] = NEON_SOFT
                px[x, oy + TILE - 2] = NEON_SOFT
                px[x, oy + TILE - 3] = NEON_DIM

    paint_cell(0, 0, 0)
    paint_cell(1, 0, 0xF)
    for mask in range(1, 16):
        paint_cell(mask % COLS, 1 + (mask >> 2), mask)

    # Upgrade (3, 0) deco cell using AI cyber arrow at subtle opacity
    arrow_path = os.path.join(SPRITES_DIR, "ai_cyber_arrow.png")
    if os.path.exists(arrow_path):
        arrow = Image.open(arrow_path).convert("RGBA").resize((36, 36), Image.Resampling.NEAREST)
        r, g, b, a = arrow.split()
        a = a.point(lambda v: int(v * 0.45))
        arrow = Image.merge("RGBA", (r, g, b, a))
        # Clear (3, 0)
        for y in range(TILE):
            for x in range(3 * TILE, 4 * TILE):
                atlas.putpixel((x, y), (0, 0, 0, 0))
        atlas.paste(arrow, (3 * TILE + 6, 6), arrow)

    atlas.save(atlas_path)
    print("[+] Upgraded resources/neon_tiles_atlas.png with AI cyberpunk tiles")


def _process_sheet_frames(src_path: str, out_path: str, frame_count: int, transform_fn) -> bool:
    if not os.path.exists(src_path):
        print(f"[!] {src_path} not found")
        return False
    sheet = Image.open(src_path).convert("RGBA")
    fw = sheet.width // frame_count
    fh = sheet.height
    processed = []
    for i in range(frame_count):
        frame = sheet.crop((i * fw, 0, (i + 1) * fw, fh))
        processed.append(transform_fn(frame, i))
    tw, th = processed[0].size
    out = Image.new("RGBA", (tw * frame_count, th), (0, 0, 0, 0))
    for i, fr in enumerate(processed):
        out.paste(fr, (i * tw, 0), fr)
    out.save(out_path)
    print(f"[+] Created animated sheet {out_path} ({out.width}x{out.height}, {frame_count} frames)")
    return True


def process_animations():
    # 1. Animated FormPortals (4 variants from ai_portal_tall_anim.png)
    tall_anim = os.path.join(SPRITES_DIR, "ai_portal_tall_anim.png")
    if os.path.exists(tall_anim):
        variants = {
            "portal_cube_anim.png": (47, 224, 255),
            "portal_ship_anim.png": (70, 150, 255),
            "portal_ufo_anim.png": (220, 60, 255),
            "portal_dash_anim.png": (255, 90, 40),
        }
        for filename, rgb in variants.items():
            def _fit_portal(fr: Image.Image, _idx: int, col=rgb) -> Image.Image:
                bbox = fr.getbbox()
                cropped = fr.crop(bbox) if bbox else fr
                scale = min(60.0 / cropped.width, 94.0 / cropped.height)
                tw = max(1, int(round(cropped.width * scale)))
                th = max(1, int(round(cropped.height * scale)))
                scaled = cropped.resize((tw, th), Image.Resampling.NEAREST)
                canvas = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
                canvas.paste(scaled, ((64 - tw) // 2, (96 - th) // 2), scaled)
                return tint_image(canvas, col)
            _process_sheet_frames(tall_anim, os.path.join(SPRITES_DIR, filename), 4, _fit_portal)

    # 2. Animated RestorePoint (inactive + active green)
    rp_anim = os.path.join(SPRITES_DIR, "ai_restore_point_anim.png")
    if os.path.exists(rp_anim):
        _process_sheet_frames(rp_anim, os.path.join(SPRITES_DIR, "restore_point_anim.png"), 4, lambda fr, _i: fr)
        _process_sheet_frames(rp_anim, os.path.join(SPRITES_DIR, "restore_point_active_anim.png"), 4, lambda fr, _i: tint_image(fr, (55, 255, 110)))

    # 3. Direct copy animated sheets for GravityPortal, DashOrb, DecoProps
    direct_copies = [
        ("ai_gravity_portal_anim.png", "gravity_portal_anim.png"),
        ("ai_dash_orb_anim.png", "dash_orb_anim.png"),
        ("ai_deco_crystals_anim.png", "deco_crystals_anim.png"),
        ("ai_deco_terminal_anim.png", "deco_terminal_anim.png"),
        ("ai_deco_hanging_vines_anim.png", "deco_hanging_vines_anim.png"),
        ("ai_deco_pylon_anim.png", "deco_pylon_anim.png"),
    ]
    for src_name, dst_name in direct_copies:
        src = os.path.join(SPRITES_DIR, src_name)
        if os.path.exists(src):
            Image.open(src).convert("RGBA").save(os.path.join(SPRITES_DIR, dst_name))
            print(f"[+] Saved animated sheet {dst_name}")

    # 4. Seamless MechanizedPlatform animated girder (384x24, 4 frames of 96x24)
    mech_anim = os.path.join(SPRITES_DIR, "ai_mech_platform_v2_anim.png")
    if os.path.exists(mech_anim):
        def _fit_mech(fr: Image.Image, idx: int) -> Image.Image:
            bbox = fr.getbbox()
            cropped = fr.crop(bbox) if bbox else fr
            if cropped.width > 8:
                cropped = cropped.crop((1, 0, cropped.width - 1, cropped.height))
            scaled = cropped.resize((96, 24), Image.Resampling.NEAREST)
            # Add crisp scrolling cyan pulse along the top energy rail (y=1..2, x=14..82)
            px = scaled.load()
            pulse_center = 16 + idx * 18
            for x in range(14, 82):
                dist = abs(x - pulse_center)
                if dist <= 6:
                    for y in (1, 2, 6):
                        r, g, b, a = px[x, y]
                        if a > 128 and b > 150:
                            boost = int(75 * (1.0 - dist / 7.0))
                            px[x, y] = (min(255, r + boost), min(255, g + boost // 2), 255, a)
            return scaled
        _process_sheet_frames(mech_anim, os.path.join(SPRITES_DIR, "mechanized_platform_anim.png"), 4, _fit_mech)


def process_ui_assets():
    # 1. Stylized winged GDXV2 logo (crop intact right half of ai_ui_logo_gdxv2.png)
    logo_raw = os.path.join(SPRITES_DIR, "ai_ui_logo_gdxv2.png")
    if os.path.exists(logo_raw):
        im = Image.open(logo_raw).convert("RGBA")
        right_half = im.crop((138, 0, im.width, im.height))
        bbox = right_half.getbbox()
        logo = right_half.crop(bbox) if bbox else right_half
        # Slight padding for crisp UI layout
        padded = Image.new("RGBA", (logo.width + 8, logo.height + 8), (0, 0, 0, 0))
        padded.paste(logo, (4, 4), logo)
        padded.save(os.path.join(SPRITES_DIR, "ui_logo_gdxv2.png"))
        print(f"[+] Created ui_logo_gdxv2.png ({padded.width}x{padded.height})")

    # 2. 9-slice Cyber Arcade Buttons (crop crisp octagonal cyan-LED button from right half of ai_ui_btn_raw.png)
    btn_raw = os.path.join(SPRITES_DIR, "ai_ui_btn_raw.png")
    if os.path.exists(btn_raw):
        im = Image.open(btn_raw).convert("RGBA")
        right_half = im.crop((68, 0, im.width, im.height))
        bbox = right_half.getbbox()
        btn = right_half.crop(bbox) if bbox else right_half
        # Upscale 2x nearest-neighbor for crisp hi-res 9-slice margins (margin ~36px horizontal, ~20px vertical)
        btn_2x = btn.resize((btn.width * 2, btn.height * 2), Image.Resampling.NEAREST)
        btn_2x.save(os.path.join(SPRITES_DIR, "ui_btn_normal.png"))

        # Hover: brighter steel + vivid electric cyan glow
        hover = ImageEnhance.Brightness(btn_2x).enhance(1.25)
        hover = ImageEnhance.Color(hover).enhance(1.2)
        hover.save(os.path.join(SPRITES_DIR, "ui_btn_hover.png"))

        # Pressed: warm amber-gold inner neon rim + slight vertical press
        pressed_tint = tint_image(btn_2x, (255, 185, 45))
        pressed_canvas = Image.new("RGBA", pressed_tint.size, (0, 0, 0, 0))
        pressed_canvas.paste(pressed_tint, (0, 2), pressed_tint)
        pressed_canvas.save(os.path.join(SPRITES_DIR, "ui_btn_pressed.png"))

        # Disabled: muted slate monochrome
        gray = ImageEnhance.Color(btn_2x).enhance(0.15)
        disabled = ImageEnhance.Brightness(gray).enhance(0.65)
        disabled.save(os.path.join(SPRITES_DIR, "ui_btn_disabled.png"))

        # Primary CTA (Play / Next): rich emerald-cyan energy rim
        primary = tint_image(btn_2x, (40, 255, 195))
        primary_hover = ImageEnhance.Brightness(primary).enhance(1.24)
        primary.save(os.path.join(SPRITES_DIR, "ui_btn_primary.png"))
        primary_hover.save(os.path.join(SPRITES_DIR, "ui_btn_primary_hover.png"))
        print(f"[+] Created 9-slice UI button variants ({btn_2x.width}x{btn_2x.height})")

    # 3. 9-slice Cyber Steel Panel Frame (smooth seamless tileable edges from ai_ui_panel_raw.png)
    panel_raw = os.path.join(SPRITES_DIR, "ai_ui_panel_raw.png")
    if os.path.exists(panel_raw):
        im = Image.open(panel_raw).convert("RGBA")
        # Copy straight steel+cyan rail strips over the protruding mid-clamps so 9-slice stretches cleanly
        # Straight border strip samples: top/bottom col x=54..61, left/right row y=54..61
        for x in range(58, 102):
            sx = 54 + ((x - 58) % 6)
            for y in range(0, 44):
                im.putpixel((x, y), im.getpixel((sx, y)))
            for y in range(116, 160):
                im.putpixel((x, y), im.getpixel((sx, y)))
        for y in range(58, 102):
            sy = 54 + ((y - 58) % 6)
            for x in range(0, 44):
                im.putpixel((x, y), im.getpixel((x, sy)))
            for x in range(116, 160):
                im.putpixel((x, y), im.getpixel((x, sy)))
        # Uniform deep translucent navy interior so text always pops clearly
        px = im.load()
        for y in range(34, 126):
            for x in range(34, 126):
                r, g, b, a = px[x, y]
                if a > 200 and max(r, g, b) < 70:
                    px[x, y] = (10, 18, 36, 236)
        im.save(os.path.join(SPRITES_DIR, "ui_panel_frame.png"))

        gold_panel = tint_image(im, (255, 195, 55))
        gold_panel.save(os.path.join(SPRITES_DIR, "ui_panel_frame_gold.png"))
        print("[+] Created 9-slice ui_panel_frame.png + ui_panel_frame_gold.png (160x160)")


if __name__ == "__main__":
    process_spikes()
    process_portals()
    process_box()
    process_breakable_wall()
    process_mech_platform()
    process_animations()
    process_ui_assets()
    process_checkpoints()
    process_button_and_emitter()
    process_tileset_atlas()
