#!/bin/bash
# Launches the macOS build (build/arm64-osx/dmengine) and resizes its window
# to 2/3 of the actual screen's width AND height, centered - per direct
# instruction ("make the final output screen 2/3 size of the actual visible
# screen on every build").
#
# Why a wrapper script instead of a game.project/engine setting: Defold's
# dmengine only exposes ONE width/height pair (game.project's [display]
# section, confirmed by inspecting the engine binary's own --config= keys -
# no separate "window size" key exists, just display.width/display.height).
# That pair drives BOTH the fixed 1920x1080 GUI design resolution every
# outpost.gui node position is hand-placed against AND the window's initial
# OS size - so lowering it to get a smaller window would also rescale/break
# every absolute-pixel GUI layout in the project. Resizing the OS window
# AFTER Defold creates it, the same way this session already verified live
# (System Events `set size of window`), leaves the design resolution alone -
# the render script's own fit/letterbox scaling (already relied on by that
# manual testing) handles the mismatch cleanly, same as an end user manually
# dragging the window's corner.
#
# Limitation: this only covers launches THROUGH THIS SCRIPT. Defold's own
# editor "Run" (the Play button / Cmd+B+R) launches dmengine directly and
# has no hook this script can attach to - a build launched that way still
# opens at the full design-resolution window size unless resized by hand
# afterward.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$REPO_DIR/build/arm64-osx/dmengine"

if [ ! -x "$ENGINE" ]; then
	echo "error: $ENGINE not found or not executable - build the project first (bob.jar build, or the Defold editor's Build command)" >&2
	exit 1
fi

# Screen size queried live (NSScreen.main), not hardcoded - this machine has
# more than one 1920x1080 display (a streaming-software display was
# mistaken for the game window earlier this session), and NSScreen.main is
# the one actually holding the frontmost/active window, so this stays
# correct regardless of which physical monitor ends up hosting the game.
read -r SCREEN_W SCREEN_H <<EOF
$(cat <<'SWIFT' | swift -
import Cocoa
guard let screen = NSScreen.main else { print("1920 1080"); exit(0) }
let f = screen.frame
print("\(Int(f.width)) \(Int(f.height))")
SWIFT
)
EOF

WIN_W=$(( SCREEN_W * 2 / 3 ))
WIN_H=$(( SCREEN_H * 2 / 3 ))
WIN_X=$(( (SCREEN_W - WIN_W) / 2 ))
WIN_Y=$(( (SCREEN_H - WIN_H) / 2 ))

echo "Launching dmengine, then resizing its window to ${WIN_W}x${WIN_H} (2/3 of ${SCREEN_W}x${SCREEN_H}), centered..."

nohup "$ENGINE" > /tmp/dmengine_run_windowed.log 2>&1 &
ENGINE_PID=$!
disown

# Poll for the window to actually exist (it takes a moment after the process
# starts) rather than a blind fixed sleep - up to 10s, matching this
# session's own established "poll, don't guess a sleep" habit.
for _ in $(seq 1 50); do
	if osascript -e "tell application \"System Events\" to tell (first process whose unix id is $ENGINE_PID) to get windows" >/dev/null 2>&1; then
		break
	fi
	sleep 0.2
done

osascript -e "tell application \"System Events\" to tell (first process whose unix id is $ENGINE_PID) to set size of window \"Galaxy\" to {$WIN_W, $WIN_H}"
osascript -e "tell application \"System Events\" to tell (first process whose unix id is $ENGINE_PID) to set position of window \"Galaxy\" to {$WIN_X, $WIN_Y}"

echo "dmengine running (pid $ENGINE_PID), window at ${WIN_X},${WIN_Y} size ${WIN_W}x${WIN_H}."
