#!/usr/bin/env python3
"""Check that the website's version matches the game's own.

The game and the website (the galaxy-site repo, checked out next to this one)
are released together: main/version.lua says which Galaxy this is, and the
website's own VERSION file says which Galaxy it was built against. Bumping one
and forgetting the other is the easy mistake, and it is invisible until someone
notices the number on the dashboard disagreeing with the login screen, so this
compares the two and fails while they differ.

The website repo is not always checked out beside this one, so a missing file is
reported and skipped rather than treated as an error. Run it as part of the
release steps in README.md.

    python tools/check_site_version.py
    python tools/check_site_version.py --site ../galaxy-site
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME_VERSION_FILE = ROOT / 'main/version.lua'
# Where the website repo usually sits. Its folder name depends on which of its
# names was used to clone it: the GitHub repo is TheShakyCoder/galaxy-laravel,
# the deployment docs call it galaxy-site.
SITE_CANDIDATES = ['../laravel', '../galaxy-site']


def game_version():
    """The version main/version.lua declares, e.g. '0.4.0-alpha.1'."""
    text = GAME_VERSION_FILE.read_text(encoding='utf-8')
    match = re.search(r'^M\.VERSION\s*=\s*"([^"]+)"', text, re.MULTILINE)
    if match is None:
        sys.exit(f'{GAME_VERSION_FILE.relative_to(ROOT)} has no M.VERSION line to read.')
    return match.group(1)


def site_version_file(explicit):
    """The website's VERSION file, or None when no website checkout is present."""
    if explicit:
        return Path(explicit).expanduser().resolve() / 'VERSION'

    for candidate in SITE_CANDIDATES:
        path = (ROOT / candidate / 'VERSION').resolve()
        if path.is_file():
            return path

    return None


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--site', help='path to the website repo (default: whichever of '
                       f'{", ".join(SITE_CANDIDATES)} is checked out)'
    )
    args = parser.parse_args()

    game = game_version()
    site = site_version_file(args.site)

    if site is None:
        print(f'No website VERSION file found in {", ".join(SITE_CANDIDATES)}; skipping.')
        return
    if not site.is_file():
        sys.exit(f'No VERSION file in {site.parent}.')

    published = site.read_text(encoding='utf-8').strip()
    if published != game:
        sys.exit(
            f'The website is on {published or "(empty)"}, the game on {game}:\n'
            f'  set {site} to {game}, then commit and push both repos.'
        )

    print(f'Website version matches the game ({game}).')


if __name__ == '__main__':
    main()
