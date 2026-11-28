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
    raw_path = os.path.join(SPRITES_DIR, "ai_portal.png")
    if not os.path.exists(raw_path):
        print("[!] ai_portal.png not found")
        return
        
    img = Image.open(raw_path).convert("RGBA")
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    
    # FormPortal has collision size (56, 96). Let's fit portal to 56x92 canvas
    target_h = 92
    aspect = cropped.width / cropped.height
    target_w = int(target_h * aspect)
    scaled = cropped.resize((target_w, target_h), Image.Resampling.NEAREST)
    
    canvas = Image.new("RGBA", (56, 96), (0, 0, 0, 0))
    paste_x = (56 - target_w) // 2
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
        print(f"[+] Created AI {filename} (56x96)")


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


if __name__ == "__main__":
    process_spikes()
    process_portals()
    process_box()
