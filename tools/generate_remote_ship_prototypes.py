#!/usr/bin/env python3
"""Regenerates main/remote_ships/<ship_id>_<faction>.go (one tiny .go per
main/data/ships.lua chassis+faction combo, each just a `model` component
pointing at that combo's own .model file) and main/network_hub.go's
embedded_components list of matching factories.

Run this after adding/renaming a ship_id or faction skin in
main/data/ships.lua, then re-open main.collection in the editor so it picks
up main/network_hub.go's new component list. See main/remote_ships.script's
own header comment for why remote players' ships are rendered this way
(one factory per known ship prototype, not a runtime mesh-swap).
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHIPS_LUA = ROOT / "main/data/ships.lua"
REMOTE_SHIPS_DIR = ROOT / "main/remote_ships"
NETWORK_HUB_GO = ROOT / "main/network_hub.go"

KEY_RE = re.compile(r'^\t\["([a-z_]+)"\]\s*=\s*\{')
MODEL_RE = re.compile(r'^\s*(accord|swarm)\s*=\s*\{\s*name\s*=\s*"([^"]+)",\s*model\s*=\s*"([^"]+)"')


def parse_ships():
    ship_id = None
    result = {}
    for line in SHIPS_LUA.read_text().split("\n"):
        m = KEY_RE.match(line)
        if m:
            ship_id = m.group(1)
            continue
        m = MODEL_RE.match(line)
        if m and ship_id:
            faction, _name, model = m.groups()
            result.setdefault(ship_id, {})[faction] = model
    return result


def main():
    ships = parse_ships()
    REMOTE_SHIPS_DIR.mkdir(parents=True, exist_ok=True)

    out = [
        'components {\n  id: "script"\n  component: "/main/remote_ships.script"\n}\n',
        'embedded_components {\n  id: "remote_ship_factory"\n  type: "factory"\n'
        '  data: "prototype: \\"/main/remote_ship.go\\"\\n"\n}\n',
    ]

    for ship_id in sorted(ships.keys()):
        for faction in ("accord", "swarm"):
            model = ships[ship_id][faction]
            go_path = REMOTE_SHIPS_DIR / f"{ship_id}_{faction}.go"
            go_path.write_text(f'components {{\n  id: "model"\n  component: "{model}"\n}}\n')

            factory_id = f"remote_ship_factory_{ship_id}_{faction}"
            proto_path = f"/main/remote_ships/{ship_id}_{faction}.go"
            out.append(
                f'embedded_components {{\n  id: "{factory_id}"\n  type: "factory"\n'
                f'  data: "prototype: \\"{proto_path}\\"\\n"\n}}\n'
            )

    NETWORK_HUB_GO.write_text("".join(out))
    print(f"wrote {len(ships) * 2} remote-ship prototypes + main/network_hub.go")


if __name__ == "__main__":
    main()
