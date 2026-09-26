#!/usr/bin/env python3
"""Compatibility entry point for the detailed lionfish model.

Uses the current original fleet generator; requires Python and Pillow.
Additional arguments (for example --output-root) are forwarded unchanged.
Run the full fleet build and integration commands when updating game cameras.
"""
from pathlib import Path
import subprocess
import sys

if __name__ == '__main__':
    raise SystemExit(subprocess.call([sys.executable, str(Path(__file__).with_name('build_fleet_models.py')), '--ship', 'lionfish', *sys.argv[1:]]))
