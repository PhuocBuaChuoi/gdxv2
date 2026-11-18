"""
Script generate pixel-art sprites cho cac components con thieu trong gdxv2:
- spike_red.png, spike_cyan.png, spike_orange.png (48x48)
- coop_box.png (40x40)
- breakable_dash_wall.png (48x48)
- pressure_button.png, pressure_button_pressed.png (72x24)
- mechanized_platform.png (96x24)
- laser_emitter.png (32x16)
- restore_point.png, restore_point_active.png (32x48)
"""
from PIL import Image, ImageDraw
import os

OUTPUT_DIR = "assets/sprites"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def color(hex_str: str, alpha: int = 255):
    h = hex_str.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (alpha,)


def create_spike(accent_hex: str, highlight_hex: str, filename: str):
    w, h = 48, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    c_body_dark = color("#0E1320")
    c_body_mid = color("#182236")
    c_body_light = color("#243350")
    c_accent = color(accent_hex)
    c_high = color(highlight_hex)
    c_glow = color(accent_hex, 70)

    # 1. Base socket
    draw.rectangle([4, 38, 43, 44], fill=c_body_dark)
    draw.line([(4, 38), (43, 38)], fill=c_body_light, width=1)
    # Rivets on socket
    for rx in [8, 20, 28, 40]:
        draw.point((rx, 41), fill=c_high)

    # 2. Main Spike Facets (Left = darker, Right = lighter)
    # Left facet polygon: (24, 6), (5, 37), (24, 37)
    draw.polygon([(24, 6), (5, 37), (24, 37)], fill=c_body_dark)
    # Right facet polygon: (24, 6), (24, 37), (42, 37)
    draw.polygon([(24, 6), (24, 37), (42, 37)], fill=c_body_mid)

    # Tech facet insets
    draw.polygon([(23, 16), (11, 35), (23, 35)], fill=c_body_mid)
    draw.polygon([(25, 16), (25, 35), (37, 35)], fill=c_body_light)

    # 3. Outer Neon Glow & Edges
    # Outer glow (1px wider)
    draw.line([(4, 38), (24, 5)], fill=c_glow, width=2)
    draw.line([(24, 5), (43, 38)], fill=c_glow, width=2)

    # Crisp neon border
    draw.line([(5, 37), (24, 6)], fill=c_accent, width=2)
    draw.line([(24, 6), (42, 37)], fill=c_accent, width=2)

    # Sharp tip highlight
    draw.point((24, 6), fill=c_high)
    draw.point((24, 7), fill=c_high)

    # Center spine ridge line
    draw.line([(24, 8), (24, 37)], fill=c_accent, width=1)
    draw.line([(24, 8), (24, 20)], fill=c_high, width=1)

    img.save(os.path.join(OUTPUT_DIR, filename))
    print(f"Generated {filename}")


def create_coop_box():
    w, h = 40, 40
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Cyberpunk heavy crate
    c_border = color("#2FE0FF")
    c_body = color("#0E1422")
    c_panel = color("#162036")
    c_plate = color("#223250")
    c_core = color("#2FE0FF")
    c_core_hi = color("#E0FAFF")
    c_bolt = color("#80C8F0")

    # Outer rounded/beveled body
    draw.rectangle([1, 1, 38, 38], fill=c_body)
    # Beveled corners
    draw.point((1, 1), (0, 0, 0, 0))
    draw.point((38, 1), (0, 0, 0, 0))
    draw.point((1, 38), (0, 0, 0, 0))
    draw.point((38, 38), (0, 0, 0, 0))

    # Neon outline
    draw.polygon([(3, 1), (36, 1), (38, 3), (38, 36), (36, 38), (3, 38), (1, 36), (1, 3)], outline=c_border)

    # Inner plate
    draw.rectangle([5, 5, 34, 34], fill=c_panel)
    draw.rectangle([8, 8, 31, 31], fill=c_plate)

    # Corner tech brackets & bolts
    for bx, by in [(7, 7), (32, 7), (7, 32), (32, 32)]:
        draw.point((bx, by), fill=c_bolt)

    # Center glowing power core (diamond shape)
    # Core outer diamond
    draw.polygon([(20, 12), (27, 20), (20, 27), (12, 20)], fill=c_body, outline=c_core)
    # Core inner glow
    draw.polygon([(20, 15), (24, 20), (20, 24), (15, 20)], fill=c_core)
    draw.rectangle([19, 19, 20, 20], fill=c_core_hi)

    # Power conduits from core to edges
    draw.line([(20, 5), (20, 11)], fill=c_core, width=1)
    draw.line([(20, 28), (20, 34)], fill=c_core, width=1)
    draw.line([(5, 20), (11, 20)], fill=c_core, width=1)
    draw.line([(28, 20), (34, 20)], fill=c_core, width=1)

    img.save(os.path.join(OUTPUT_DIR, "coop_box.png"))
    print("Generated coop_box.png")


def create_breakable_dash_wall():
    w, h = 48, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_border = color("#FF2FE0")
    c_body = color("#120A1C")
    c_panel = color("#1E102E")
    c_crack = color("#FF40E8")
    c_crack_hi = color("#FFE8FC")
    c_glow = color("#FF2FE0", 60)

    # Outer wall block
    draw.rectangle([1, 1, 46, 46], fill=c_body, outline=c_border)
    draw.rectangle([4, 4, 43, 43], fill=c_panel)

    # Inset frame
    draw.rectangle([7, 7, 40, 40], outline=color("#301A48"))

    # Fissure / energy fracture lines
    crack_pts = [(24, 4), (20, 14), (28, 22), (18, 32), (24, 44)]
    # Glow under crack
    for pt1, pt2 in zip(crack_pts[:-1], crack_pts[1:]):
        draw.line([pt1, pt2], fill=c_glow, width=4)
    # Bright crack
    for pt1, pt2 in zip(crack_pts[:-1], crack_pts[1:]):
        draw.line([pt1, pt2], fill=c_crack, width=2)
    # Core hot line
    for pt1, pt2 in zip(crack_pts[:-1], crack_pts[1:]):
        draw.line([pt1, pt2], fill=c_crack_hi, width=1)

    # Branch cracks
    draw.line([(20, 14), (10, 18)], fill=c_crack, width=1)
    draw.line([(28, 22), (38, 26)], fill=c_crack, width=1)
    draw.line([(18, 32), (10, 36)], fill=c_crack, width=1)

    # Corner warning markings
    for cx in [2, 45]:
        draw.line([(cx, 3), (cx, 8)], fill=c_border, width=1)
        draw.line([(cx, 39), (cx, 44)], fill=c_border, width=1)

    img.save(os.path.join(OUTPUT_DIR, "breakable_dash_wall.png"))
    print("Generated breakable_dash_wall.png")


def create_pressure_buttons():
    w, h = 72, 24

    # 1. Normal Unpressed
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_base = color("#0E121E")
    c_base_edge = color("#202C42")
    c_plate = color("#182236")
    c_neon = color("#39FF14")
    c_neon_hi = color("#C4FFB0")

    # Base housing (y=12 to 22, x=2 to 69)
    draw.rectangle([2, 13, 69, 21], fill=c_base)
    draw.line([(2, 13), (69, 13)], fill=c_base_edge, width=1)
    draw.line([(2, 21), (69, 21)], fill=c_base_edge, width=1)
    for bx in [8, 24, 48, 63]:
        draw.point((bx, 17), fill=color("#445A80"))

    # Elevated plate (y=5 to 13, x=6 to 65)
    draw.rectangle([6, 5, 65, 12], fill=c_plate)
    # Top neon strip
    draw.line([(6, 5), (65, 5)], fill=c_neon, width=2)
    draw.line([(10, 5), (61, 5)], fill=c_neon_hi, width=1)
    # Side edges
    draw.line([(6, 6), (6, 12)], fill=c_neon, width=1)
    draw.line([(65, 6), (65, 12)], fill=c_neon, width=1)
    # Indicator bars
    for ix in [18, 28, 36, 44, 54]:
        draw.line([(ix, 8), (ix + 4, 8)], fill=c_neon, width=1)

    img.save(os.path.join(OUTPUT_DIR, "pressure_button.png"))
    print("Generated pressure_button.png")

    # 2. Pressed
    img_p = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_p = ImageDraw.Draw(img_p)

    c_neon_p = color("#FFD700")
    c_neon_p_hi = color("#FFFFE0")

    # Base housing
    draw_p.rectangle([2, 13, 69, 21], fill=c_base)
    draw_p.line([(2, 13), (69, 13)], fill=c_base_edge, width=1)
    draw_p.line([(2, 21), (69, 21)], fill=c_base_edge, width=1)
    for bx in [8, 24, 48, 63]:
        draw_p.point((bx, 17), fill=color("#445A80"))

    # Depressed plate (y=10 to 14, flush)
    draw_p.rectangle([6, 10, 65, 14], fill=c_plate)
    draw_p.line([(6, 10), (65, 10)], fill=c_neon_p, width=2)
    draw_p.line([(10, 10), (61, 10)], fill=c_neon_p_hi, width=1)
    # Intense energy indicator
    for ix in range(12, 60, 4):
        draw_p.point((ix, 12), fill=c_neon_p_hi)

    img_p.save(os.path.join(OUTPUT_DIR, "pressure_button_pressed.png"))
    print("Generated pressure_button_pressed.png")


def create_mechanized_platform():
    w, h = 96, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_deck = color("#0E1422")
    c_panel = color("#182236")
    c_cyan = color("#2FE0FF")
    c_cyan_hi = color("#E0FAFF")
    c_sub = color("#126488")
    c_vent = color("#0A0E18")

    # Platform chassis (y=5 to 21, x=2 to 93)
    draw.polygon([(4, 5), (91, 5), (93, 7), (93, 19), (90, 21), (5, 21), (2, 19), (2, 7)], fill=c_deck)
    draw.rectangle([6, 7, 89, 18], fill=c_panel)

    # Top maglev guide rail (glowing cyan line)
    draw.line([(4, 5), (91, 5)], fill=c_cyan, width=2)
    draw.line([(8, 5), (87, 5)], fill=c_cyan_hi, width=1)

    # Bottom trim line
    draw.line([(6, 20), (89, 20)], fill=c_sub, width=1)

    # 3 tech thruster vents
    for vx in [16, 44, 72]:
        draw.rectangle([vx, 9, vx + 12, 16], fill=c_vent, outline=color("#223350"))
        draw.line([(vx + 3, 11), (vx + 9, 11)], fill=c_sub, width=1)
        draw.line([(vx + 3, 14), (vx + 9, 14)], fill=c_sub, width=1)

    # Side warning notches
    draw.line([(4, 9), (4, 16)], fill=c_cyan, width=1)
    draw.line([(91, 9), (91, 16)], fill=c_cyan, width=1)

    img.save(os.path.join(OUTPUT_DIR, "mechanized_platform.png"))
    print("Generated mechanized_platform.png")


def create_laser_emitter():
    w, h = 32, 16
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_body = color("#121624")
    c_frame = color("#26344E")
    c_laser = color("#FF2A55")
    c_laser_hi = color("#FFA8BC")

    # Emitter casing
    draw.polygon([(4, 2), (27, 2), (29, 4), (29, 11), (27, 13), (4, 13), (2, 11), (2, 4)], fill=c_body, outline=c_frame)
    # Energy focus lens in center
    draw.rectangle([10, 4, 21, 11], fill=color("#080A12"), outline=c_laser)
    draw.rectangle([13, 6, 18, 9], fill=c_laser)
    draw.point((15, 7), fill=c_laser_hi)
    draw.point((16, 7), fill=c_laser_hi)

    img.save(os.path.join(OUTPUT_DIR, "laser_emitter.png"))
    print("Generated laser_emitter.png")


def create_restore_point_sprites():
    w, h = 32, 48

    # 1. Inactive checkpoint crystal
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_border = color("#2FE0FF")
    c_body = color("#0A1622", 220)
    c_inner = color("#142E44", 230)
    c_core = color("#2FE0FF")
    c_glow = color("#2FE0FF", 50)

    # Outer diamond: top (16, 6), right (28, 24), bottom (16, 42), left (4, 24)
    diamond = [(16, 6), (28, 24), (16, 42), (4, 24)]
    draw.polygon(diamond, fill=c_body)

    # Glow ring
    draw.polygon([(16, 4), (30, 24), (16, 44), (2, 24)], outline=c_glow)
    draw.polygon(diamond, outline=c_border)

    # Inner facet
    draw.polygon([(16, 12), (24, 24), (16, 36), (8, 24)], fill=c_inner)

    # Center rune pulse
    draw.polygon([(16, 17), (21, 24), (16, 31), (11, 24)], fill=c_core)
    draw.point((16, 24), fill=color("#E0FAFF"))

    img.save(os.path.join(OUTPUT_DIR, "restore_point.png"))
    print("Generated restore_point.png")

    # 2. Active checkpoint crystal
    img_a = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_a = ImageDraw.Draw(img_a)

    c_border_a = color("#39FF14")
    c_body_a = color("#0A2612", 240)
    c_inner_a = color("#144A22", 240)
    c_core_a = color("#39FF14")
    c_core_hi = color("#FFFFFF")
    c_glow_a = color("#39FF14", 90)

    # Outer aura
    draw_a.polygon([(16, 3), (31, 24), (16, 45), (1, 24)], outline=c_glow_a)
    draw_a.polygon([(16, 5), (29, 24), (16, 43), (3, 24)], outline=c_glow_a)
    draw_a.polygon(diamond, fill=c_body_a, outline=c_border_a)

    # Inner active facet
    draw_a.polygon([(16, 11), (25, 24), (16, 37), (7, 24)], fill=c_inner_a)

    # Radiant core
    draw_a.polygon([(16, 16), (22, 24), (16, 32), (10, 24)], fill=c_core_a)
    draw_a.polygon([(16, 20), (19, 24), (16, 28), (13, 24)], fill=c_core_hi)

    img_a.save(os.path.join(OUTPUT_DIR, "restore_point_active.png"))
    print("Generated restore_point_active.png")


def main():
    # Spikes
    create_spike("#FF2A55", "#FFA8BC", "spike_red.png")
    create_spike("#2FE0FF", "#A8F6FF", "spike_cyan.png")
    create_spike("#FF8A00", "#FFD699", "spike_orange.png")

    # Placed Blocks & Objects
    create_coop_box()
    create_breakable_dash_wall()
    create_pressure_buttons()
    create_mechanized_platform()
    create_laser_emitter()
    create_restore_point_sprites()
    print("All pixel assets generated successfully!")


if __name__ == "__main__":
    main()
