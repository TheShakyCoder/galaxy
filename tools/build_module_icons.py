#!/usr/bin/env python3
"""
Builds small, original flat-icon PNGs for every fittable module
(plan.md S2.8) plus one generic "empty slot" icon per slot TYPE
(weapon/computer/engine/hull), used by the outpost screen's ship visual
(main/outpost.gui_script) to show which component is installed in each
slot by icon instead of by name text.

Deliberately simple/original: flat geometric shapes drawn with basic
primitives (no BSG-style iconography, no text baked into the images -
same "no reference-project art" rule as every other asset in this
project, see plan.md S0). Filled-slot icons are bright/saturated;
empty-slot icons are the same silhouette family rendered as a dim
outline only, so a glance at the ship visual reads "filled vs. empty"
even before reading which specific icon it is.

Run from the project root: `python3 tools/build_module_icons.py`
(needs Pillow - the project's own scratchpad venv has it, or
`pip install Pillow`). Writes directly over the checked-in outputs
under main/images/icons/ and (re)writes main/images/icons.atlas to
match. Re-run this after adding a new module to
main/data/modules/*.lua and giving it an `icon` field, or after
changing a design below, rather than hand-editing the PNGs.
"""
import math
import os
import random

from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS_DIR = os.path.join(ROOT, "main", "images", "icons")
ATLAS_PATH = os.path.join(ROOT, "main", "images", "icons.atlas")

SIZE = 128
CENTER = SIZE / 2

# ---- Per-type outline color for the generic "empty slot" icons ----
TYPE_OUTLINE_COLOR = {
    "weapon": (140, 150, 160, 255),
    "computer": (140, 150, 160, 255),
    "engine": (140, 150, 160, 255),
    "hull": (140, 150, 160, 255),
}
OUTLINE_WIDTH = 5


def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


# ---- Cannon body proportions, shared by both weapon icons. Deliberately
# shorter/lower than a "full height" cannon would be, to leave headroom
# above the muzzle for a firing effect (flash/beam) - only the filled
# module icons draw that effect; the generic empty-slot outline (below)
# draws just the body, so it stays a plain unlit cannon shape. ----
BASE_TOP = CENTER + 14
BASE_BOTTOM = CENTER + 50
BARREL_HALF_W = 12
BARREL_TOP = CENTER - 22
MUZZLE_TIP = CENTER - 38


def polar_point(cx, cy, r, deg):
    rad = math.radians(deg)
    return (cx + r * math.cos(rad), cy - r * math.sin(rad))  # image y is down, so subtract for "up"


def draw_cannon_body(draw, fill, outline_only=False):
    """The turret/cannon shape alone (round base + barrel + muzzle taper),
    with no firing effect - shared by the weapon and mining icons, and by
    the generic empty-weapon-slot outline."""
    kw = {"outline": fill, "width": OUTLINE_WIDTH} if outline_only else {"fill": fill}
    draw.ellipse([CENTER - 34, BASE_TOP, CENTER + 34, BASE_BOTTOM], **kw)
    draw.rectangle([CENTER - BARREL_HALF_W, BARREL_TOP, CENTER + BARREL_HALF_W, BASE_TOP + 4], **kw)
    draw.polygon(
        [(CENTER - BARREL_HALF_W, BARREL_TOP), (CENTER + BARREL_HALF_W, BARREL_TOP), (CENTER, MUZZLE_TIP)],
        **kw,
    )


FLASH_COLOR = (255, 240, 170, 255)      # bright warm spark, same for any cannon body color
FLASH_GLOW_COLOR = (255, 200, 90, 90)   # soft translucent halo behind the spark


def draw_muzzle_flash(draw, tip):
    """A small radial spark-burst (asterisk-style star) right at the
    muzzle, in a bright warm color that contrasts with any cannon body
    color - the "obviously firing" cue for the basic Auto Cannon."""
    cx, cy = tip
    cy -= 4  # sit just off the tip rather than dead-center on it
    # soft glow behind the spark
    glow = [polar_point(cx, cy, r, deg) for deg, r in zip(range(0, 360, 30), [26, 11] * 6)]
    draw.polygon(glow, fill=FLASH_GLOW_COLOR)
    # crisp spark on top
    spikes = 6
    pts = []
    for i in range(spikes * 2):
        r = 20 if i % 2 == 0 else 7
        pts.append(polar_point(cx, cy, r, i * (360 / (spikes * 2))))
    draw.polygon(pts, fill=FLASH_COLOR)
    # a couple of short tracer flecks flying further out, for a bit of motion
    for deg in (35, 145):
        x0, y0 = polar_point(cx, cy, 20, deg)
        x1, y1 = polar_point(cx, cy, 32, deg)
        draw.line([(x0, y0), (x1, y1)], fill=FLASH_COLOR, width=3)


def draw_weapon_silhouette(draw, fill, outline_only=False):
    """The basic Auto Cannon: cannon body + a bright muzzle flash so it
    reads as "firing" at a glance, not just "a cannon shape"."""
    draw_cannon_body(draw, fill, outline_only)
    if not outline_only:
        draw_muzzle_flash(draw, (CENTER, MUZZLE_TIP))


# ---- Digger (Patrol-tier mining cannon, formerly named "Prospector" -
# see weapons_autocannons.lua's mining naming-scale comment) icon: a
# hexagonal badge with a golden sunburst — restyled per direct reference
# (a "Gopher" mining-cannon icon the user liked: hex badge frame, dark
# interior, a fan of golden light rays converging near the bottom,
# scattered sparkle glints).
# Recreated from scratch as flat vector shapes in this project's own
# style/palette, not traced from the reference image (§0's "no copying
# reference art" rule applies to any borrowed art style, not just
# BSG's). This one needs full-image alpha compositing (to clip the
# sunburst rays to the hex silhouette), so it's built as its own
# function returning a whole Image rather than fitting the
# draw-onto-a-shared-canvas convention every other icon uses — see its
# call site in main().
HEX_ANGLES = (0, 60, 120, 180, 240, 300)  # flat-top/bottom, pointed left/right
HEX_R = 54
HEX_RIM_COLOR = (12, 16, 26, 255)
HEX_FILL_COLOR = (23, 32, 52, 255)
HEX_BORDER_COLOR = (230, 236, 240, 255)
SUNBURST_RAY_COLORS = [(255, 200, 88, 235), (255, 236, 175, 245)]


def draw_mining_badge():
    img = new_canvas()

    hex_pts = [polar_point(CENTER, CENTER, HEX_R, a) for a in HEX_ANGLES]
    hex_pts_outer = [polar_point(CENTER, CENTER, HEX_R + 4, a) for a in HEX_ANGLES]

    frame = ImageDraw.Draw(img)
    frame.polygon(hex_pts_outer, fill=HEX_RIM_COLOR)
    frame.polygon(hex_pts, fill=HEX_FILL_COLOR)

    # Sunburst + glints, drawn on their own layer so they can be clipped
    # to the hex silhouette (a plain draw would spill rays past the
    # frame's edges near the left/right points).
    content = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(content)
    source = (CENTER, CENTER + 24)
    ray_offsets = (-46, -32, -18, -6, 6, 18, 32, 46)
    for i, ang_off in enumerate(ray_offsets):
        ang = 90 + ang_off
        color = SUNBURST_RAY_COLORS[i % 2]
        far = polar_point(source[0], source[1], 62, ang)
        far_l = polar_point(source[0], source[1], 62, ang + 4)
        far_r = polar_point(source[0], source[1], 62, ang - 4)
        cdraw.polygon([source, far_l, far, far_r], fill=color)
    # bright core glow where the rays converge
    cdraw.ellipse([source[0] - 18, source[1] - 18, source[0] + 18, source[1] + 18], fill=(255, 224, 140, 110))
    cdraw.ellipse([source[0] - 8, source[1] - 8, source[0] + 8, source[1] + 8], fill=(255, 248, 222, 255))
    # scattered glints, like light catching stray ore/dust
    rnd = random.Random(11)  # fixed seed - reproducible output, not "random" noise on every regen
    for _ in range(6):
        gx = CENTER + rnd.uniform(-36, 36)
        gy = CENTER + rnd.uniform(-32, 30)
        r = rnd.choice((1, 1, 2))
        cdraw.ellipse([gx - r, gy - r, gx + r, gy + r], fill=(255, 255, 255, 210))

    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).polygon(hex_pts, fill=255)
    _, _, _, alpha = content.split()
    content.putalpha(ImageChops.multiply(alpha, mask))
    img.alpha_composite(content)

    # crisp frame border on top, over the glow
    ImageDraw.Draw(img).line(hex_pts + [hex_pts[0]], fill=HEX_BORDER_COLOR, width=4)
    return img


def draw_computer_silhouette(draw, fill, outline_only=False):
    """A scanner dish: concentric arcs over a small base, evoking a
    sensor/analysis sweep rather than a generic "chip" (keeps it
    visually distinct from the hull/engine icons)."""
    kw = {"outline": fill, "width": OUTLINE_WIDTH} if outline_only else {"fill": fill}
    draw.rectangle([CENTER - 10, CENTER + 24, CENTER + 10, CENTER + 44], **kw)
    for r in (14, 28, 42):
        bbox = [CENTER - r, CENTER - r + 6, CENTER + r, CENTER + r + 6]
        if outline_only:
            draw.arc(bbox, start=200, end=340, fill=fill, width=OUTLINE_WIDTH)
        else:
            draw.arc(bbox, start=200, end=340, fill=fill, width=10)
    draw.ellipse([CENTER - 8, CENTER - 8, CENTER + 8, CENTER + 8], **kw)


def draw_engine_silhouette(draw, fill, outline_only=False):
    """A thruster bell: trapezoid nozzle + small flame triangle."""
    kw = {"outline": fill, "width": OUTLINE_WIDTH} if outline_only else {"fill": fill}
    draw.polygon(
        [(CENTER - 22, CENTER - 40), (CENTER + 22, CENTER - 40), (CENTER + 34, CENTER + 30), (CENTER - 34, CENTER + 30)],
        **kw,
    )
    if not outline_only:
        draw.polygon(
            [(CENTER - 16, CENTER + 30), (CENTER + 16, CENTER + 30), (CENTER, CENTER + 58)],
            fill=fill,
        )
    else:
        draw.line(
            [(CENTER - 16, CENTER + 30), (CENTER, CENTER + 58), (CENTER + 16, CENTER + 30)],
            fill=fill, width=OUTLINE_WIDTH,
        )


def draw_hull_silhouette(draw, fill, outline_only=False):
    """A plate/shield: pentagon armor-plate shape."""
    kw = {"outline": fill, "width": OUTLINE_WIDTH} if outline_only else {"fill": fill}
    draw.polygon(
        [
            (CENTER, CENTER - 46),
            (CENTER + 38, CENTER - 18),
            (CENTER + 26, CENTER + 46),
            (CENTER - 26, CENTER + 46),
            (CENTER - 38, CENTER - 18),
        ],
        **kw,
    )


TYPE_DRAW_FN = {
    "weapon": draw_weapon_silhouette,
    "computer": draw_computer_silhouette,
    "engine": draw_engine_silhouette,
    "hull": draw_hull_silhouette,
}

# ---- Concrete module icons (plan.md S2.8's current catalog) ----
# (module_key, slot_type, draw_fn, fill_color) - mining_cannon_basic is
# handled separately in main() (draw_mining_badge builds a whole Image,
# not a draw-onto-shared-canvas function like the others need).
MODULE_ICONS = [
    ("auto_cannon_basic", "weapon", draw_weapon_silhouette, (235, 95, 60, 255)),   # combat orange-red
    ("asteroid_analyser", "computer", draw_computer_silhouette, (150, 110, 235, 255)),  # scanner purple
]


def save(name, img):
    os.makedirs(ICONS_DIR, exist_ok=True)
    path = os.path.join(ICONS_DIR, name + ".png")
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def main():
    written = []

    for key, slot_type, draw_fn, color in MODULE_ICONS:
        img = new_canvas()
        draw_fn(ImageDraw.Draw(img), color)
        save(key, img)
        written.append(key)

    save("mining_cannon_basic", draw_mining_badge())
    written.append("mining_cannon_basic")

    for slot_type, draw_fn in TYPE_DRAW_FN.items():
        img = new_canvas()
        draw_fn(ImageDraw.Draw(img), TYPE_OUTLINE_COLOR[slot_type], outline_only=True)
        name = "slot_%s_empty" % slot_type
        save(name, img)
        written.append(name)

    with open(ATLAS_PATH, "w") as f:
        for name in written:
            f.write('images {\n  image: "/main/images/icons/%s.png"\n}\n' % name)
    print("wrote", os.path.relpath(ATLAS_PATH, ROOT))


if __name__ == "__main__":
    main()
