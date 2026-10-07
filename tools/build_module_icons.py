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

The four letterless "Octagon <type> Empty" icons an empty fitting slot
uses are derived from the hand-provided per-type octagons instead:
`python3 tools/build_module_icons.py --empty-icons` (see
build_letterless_empty_icons below).
"""
import math
import os
import random
import sys

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

# ---- Octagon silhouette (the slot markers' own shape, S2.8.1) ----
# The slot markers in main/outpost.gui_script are regular-looking octagons
# (a square with its corners cut at 45 degrees), and every hand-provided
# "Octagon *" icon fills the whole 128px tile with that same silhouette and
# a near-black interior. These vertices match the hand icons exactly
# (measured off Octagon C.png: the top/bottom flat edges span x 29..98, the
# left/right flat edges span y 32..96), so a generated icon given this
# background reads as the same shape as the hand-drawn ones.
OCTAGON_POINTS = [
    (29, 0), (98, 0), (127, 32), (127, 96),
    (98, 127), (29, 127), (0, 96), (0, 32),
]
# Generated icons that should sit on a plain black octagon rather than the
# fully transparent canvas the rest of the set uses - i.e. the ones whose
# module is shown on the octagon slot markers but which (unlike the
# hand-provided "Octagon *" art) had no dark backing of their own, so the
# marker's own colour showed straight through them. Per direct instruction
# the Asteroid Analyser is the one that needed this.
OCTAGON_BACKGROUND_ICONS = {"asteroid_analyser"}
OCTAGON_BACKGROUND_COLOR = (0, 0, 0, 255)


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


# ---- Gopher (Patrol-tier mining cannon, formerly named "Prospector"/"Digger" -
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

# ---- Key modifier icons ----
# Small symbols shown as the modifier prefix on a keyboard hint, e.g. the
# Shift icon in front of a weapon's slot number (main/flight_hud.gui_script's
# per-slot key label and hover tooltip) - per direct instruction: "modify
# keys should be indicated with an icon before the key". Flat and monochrome
# (a light grey, like the module-icon outlines) so it reads on the dark HUD
# panels; drawn with primitives only, same rule as every other icon here.
KEY_ICON_COLOR = (230, 236, 240, 255)


def draw_shift_key():
    """The upward arrow commonly printed on a Shift key."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # Arrow head: a wide upward triangle.
    d.polygon(
        [(CENTER, CENTER - 46), (CENTER - 42, CENTER + 2), (CENTER + 42, CENTER + 2)],
        fill=KEY_ICON_COLOR,
    )
    # Stem, overlapping the head's base so the two pieces read as one glyph.
    d.rectangle([CENTER - 13, CENTER - 2, CENTER + 13, CENTER + 46], fill=KEY_ICON_COLOR)
    return img

# ---- Hand-provided icons (NOT generated by this script) ----
# Per direct instruction: these octagon-shaped icons were supplied directly
# as finished PNGs under main/images/icons/ rather than drawn here, and are
# now what main/outpost.gui_script and main/data/modules/weapons_autocannons.lua
# actually reference (SLOT_EMPTY_ICON / the `icon` fields). Listed here only
# so re-running this script still includes them in the rewritten
# icons.atlas instead of silently dropping them - main() below does NOT
# call save() for these, since there's no pixel data to (re)generate.
MANUAL_ICONS = [
    "Octagon W", "Octagon C", "Octagon E", "Octagon H",
    "Octagon Cannon Asteroid", "Octagon Cannon Spaceship",
    "Octagon Empty", # the neutral, letterless octagon (currently unwired: every empty
                      # slot uses its own type's letterless "Octagon <T> Empty" below)
]

# ---- Derived letterless empty-slot octagons (per direct instruction) ----
# Each hand-provided "Octagon W"/"C"/"E"/"H" icon draws its slot TYPE's own
# letter in the middle of the octagon. Per direct instruction an EMPTY fitting
# slot shows just the octagon - the type's own colours, but no letter - so
# these four are DERIVED from those icons rather than being another batch of
# hand-drawn art: every pixel belonging to the glyph (the bright ones near the
# middle, plus a small margin for the anti-aliased fringe) is repainted with
# its nearest non-glyph neighbour's own colour, leaving the octagon's border,
# fill and gradient completely untouched.
#
# Measured on the four sources: glyph pixels live within 36px of the centre and
# the border ring starts around 56px, so GLYPH_MAX_RADIUS sits safely between
# the two.
#
# Built with: python3 tools/build_module_icons.py --empty-icons
# (main() only LISTS them, so a later rewrite of icons.atlas keeps them.)
LETTERLESS_EMPTY_ICONS = [
    ("Octagon W", "Octagon W Empty"),
    ("Octagon C", "Octagon C Empty"),
    ("Octagon E", "Octagon E Empty"),
    ("Octagon H", "Octagon H Empty"),
]
GLYPH_MAX_RADIUS = 48       # px from the centre: past every glyph pixel, short of the border ring
GLYPH_EDGE_MARGIN = 2       # px of anti-aliased fringe around each glyph pixel, repainted too
GLYPH_MIN_BRIGHTNESS = 110  # r+g+b: the near-black fill sits near 60, the glyph above 330

# ---- Concrete module icons (plan.md S2.8's current catalog) ----
# (module_key, slot_type, draw_fn, fill_color) - mining_cannon_basic is
# handled separately in main() (draw_mining_badge builds a whole Image,
# not a draw-onto-shared-canvas function like the others need).
#
# Hull/Engine entries below (plan.md S2.8.11, per direct instruction:
# "create an icon for all the recently added modules") reuse the same
# per-type silhouette (draw_hull_silhouette's plate, draw_engine_silhouette's
# thruster bell) every module of that type already shares - same "one shape
# family per slot type, distinguished by fill color" convention the two
# existing weapon/computer icons above already establish, not a bespoke
# shape per module. Colors loosely group by what each one actually does
# rather than being arbitrary: Hull's 6 passive plating tiers move through a
# bronze/steel/olive/teal/mauve range roughly tracking which of
# armor/critical_defense/hull_points (main/data/modules/hull_modules.lua's
# own `stats` field) each one boosts, brightening to gold for the one
# tier that boosts all three; the two ACTIVE abilities (Emergency Hull
# Repair, Slide Thrusters) each get a distinctly brighter/more saturated
# color than their type's passive siblings, so they read as "different kind
# of module" at a glance even before checking behavior.
MODULE_ICONS = [
    ("auto_cannon_basic", "weapon", draw_weapon_silhouette, (235, 95, 60, 255)),   # combat orange-red
    ("asteroid_analyser", "computer", draw_computer_silhouette, (150, 110, 235, 255)),  # scanner purple

    # Hull - passive plating (bronze/steel/olive/teal/mauve, brightening to
    # gold for the all-three-stats top tier)
    ("armor_plating_patrol", "hull", draw_hull_silhouette, (210, 150, 70, 255)),            # bronze - armor only
    ("reinforced_plating_patrol", "hull", draw_hull_silhouette, (90, 170, 210, 255)),        # steel blue - critical_defense only
    ("composite_plating_patrol", "hull", draw_hull_silhouette, (150, 180, 90, 255)),         # olive - hull_points + armor
    ("reinforced_hull_plating_patrol", "hull", draw_hull_silhouette, (100, 190, 150, 255)),  # teal - hull_points + critical_defense
    ("reinforced_armor_plating_patrol", "hull", draw_hull_silhouette, (180, 130, 150, 255)), # mauve - armor + critical_defense
    ("reinforced_composite_plating_patrol", "hull", draw_hull_silhouette, (220, 200, 100, 255)), # gold - all three stats
    # Hull - repair pair (per direct instruction: one passive boost to the
    # hull's own repair rate, one active burst of hull points): the passive
    # booster gets a bright repair-green, the active burst the emergency red.
    ("hull_repair_booster_patrol", "hull", draw_hull_silhouette, (120, 235, 150, 255)),     # bright green - repair/regeneration
    # Hull - active ability
    ("emergency_hull_repair_patrol", "hull", draw_hull_silhouette, (230, 80, 80, 255)),      # red - emergency/medical association

    # Engine - passive boosters
    ("engine_gyros_patrol", "engine", draw_engine_silhouette, (120, 170, 230, 255)),   # blue - turning/navigation
    ("thruster_array_patrol", "engine", draw_engine_silhouette, (240, 140, 60, 255)),  # orange - speed/thrust, flame association
    # Engine - active ability
    ("slide_thrusters_patrol", "engine", draw_engine_silhouette, (80, 230, 210, 255)), # bright cyan - distinct energetic color
]


def save(name, img):
    os.makedirs(ICONS_DIR, exist_ok=True)
    path = os.path.join(ICONS_DIR, name + ".png")
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def strip_letter(img):
    """The same octagon icon with its type letter painted out (see
    LETTERLESS_EMPTY_ICONS above). Returns a new image; `img` is not used
    again."""
    px = img.load()
    w, h = img.size
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0

    glyph = set()
    for y in range(h):
        for x in range(w):
            if math.hypot(x - cx, y - cy) > GLYPH_MAX_RADIUS:
                continue
            r, g, b, a = px[x, y]
            if a > 40 and (r + g + b) > GLYPH_MIN_BRIGHTNESS:
                glyph.add((x, y))

    # Grow the mask so the glyph's anti-aliased edge goes with it.
    for _ in range(GLYPH_EDGE_MARGIN):
        edge = set()
        for x, y in glyph:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in glyph:
                    edge.add((nx, ny))
        glyph |= edge

    # Repaint every masked pixel with the nearest unmasked (i.e. body/border)
    # pixel's own colour, so the fill's own gradient is preserved.
    for x, y in glyph:
        for radius in range(1, max(w, h)):
            replacement = None
            for dx in range(-radius, radius + 1):
                for dy in range(-radius, radius + 1):
                    if max(abs(dx), abs(dy)) != radius:
                        continue
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in glyph:
                        replacement = px[nx, ny]
                        break
                if replacement:
                    break
            if replacement:
                px[x, y] = replacement
                break

    print("    painted out %d glyph pixels" % len(glyph))
    return img


def build_letterless_empty_icons():
    """(Re)derives the four letterless empty-slot octagons from the
    hand-provided per-type icons (see LETTERLESS_EMPTY_ICONS above)."""
    for source, name in LETTERLESS_EMPTY_ICONS:
        path = os.path.join(ICONS_DIR, source + ".png")
        print("reading", os.path.relpath(path, ROOT))
        save(name, strip_letter(Image.open(path).convert("RGBA")))


def main():
    written = []

    for key, slot_type, draw_fn, color in MODULE_ICONS:
        img = new_canvas()
        draw = ImageDraw.Draw(img)
        if key in OCTAGON_BACKGROUND_ICONS:
            draw.polygon(OCTAGON_POINTS, fill=OCTAGON_BACKGROUND_COLOR)
        draw_fn(draw, color)
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

    save("key_shift", draw_shift_key())
    written.append("key_shift")

    written.extend(MANUAL_ICONS)
    # Derived, not drawn here - built with --empty-icons (see
    # build_letterless_empty_icons) but listed so rewriting icons.atlas keeps
    # them in it.
    written.extend(name for _, name in LETTERLESS_EMPTY_ICONS)

    with open(ATLAS_PATH, "w") as f:
        for name in written:
            f.write('images {\n  image: "/main/images/icons/%s.png"\n}\n' % name)
    print("wrote", os.path.relpath(ATLAS_PATH, ROOT))


if __name__ == "__main__":
    if "--empty-icons" in sys.argv[1:]:
        build_letterless_empty_icons()
    else:
        main()
