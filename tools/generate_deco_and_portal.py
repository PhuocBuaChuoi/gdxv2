"""
Generate tall unclipped FormPortal sprite + 6 dedicated decoration assets via PixelLab.
"""
from tools.generate_ai_batch import run_one
from tools.pixellab_client import get_balance

JOBS = [
    {
        "path": "assets/sprites/ai_portal_tall.png",
        "description": "tall vertical elliptical neon portal gate, Geometry Dash style glowing cyan ring gateway arch with swirling bright cosmic energy inside, full oval silhouette completely visible inside canvas with margin, 2d side-view pixel art game sprite",
        "width": 64,
        "height": 96,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_pylon.png",
        "description": "sci-fi glowing neon cyan street lamp pylon post with small holographic lantern head on top, standing upright, 2d side-view pixel art platformer decoration prop",
        "width": 48,
        "height": 96,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_crystals.png",
        "description": "glowing bioluminescent cyan and teal crystal cluster growing from dark rock base, 2d side-view pixel art platformer environment decoration prop",
        "width": 48,
        "height": 48,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_foliage.png",
        "description": "lush pixel art glowing emerald moss grass tuft and small teal cyber fern leaves growing flat along ground line, 2d side-view platformer floor decoration",
        "width": 48,
        "height": 32,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_hanging_vines.png",
        "description": "hanging pixel art neon tech cables and glowing teal moss vines dangling down from ceiling edge, 2d side-view platformer ceiling decoration",
        "width": 48,
        "height": 64,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_terminal.png",
        "description": "futuristic small pixel art sci-fi control terminal pillar with glowing cyan holographic screen, 2d side-view platformer background prop",
        "width": 48,
        "height": 64,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
    {
        "path": "assets/sprites/deco_arrow_sign.png",
        "description": "glowing neon cyan holographic right-pointing arrow sign mounted on slim metal post, 2d side-view pixel art platformer guide prop",
        "width": 48,
        "height": 48,
        "no_background": True,
        "detail": "medium detail",
        "outline": "single color black outline",
        "view": "side",
    },
]


def main():
    print("[*] Balance before deco batch:")
    print(get_balance())
    for idx, job in enumerate(JOBS):
        run_one(job, idx + 800)
    print("[*] Balance after deco batch:")
    print(get_balance())


if __name__ == "__main__":
    main()
