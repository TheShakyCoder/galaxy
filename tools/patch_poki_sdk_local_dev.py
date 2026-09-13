#!/usr/bin/env python3
"""
Defensive patch for the extension-poki-sdk dependency's HTML5 engine
template (plan.md §3.4) - NOT a fix for a bug in normal builds. The
game builds and runs fine end-to-end with real internet access; this
only matters when testing somewhere with no network route to
game-cdn.poki.com at all (e.g. a sandboxed tool environment), which
isn't a normal local-dev situation.

THE EDGE CASE
--------------
extension-poki-sdk's own manifests/web/engine_template.html (merged into
the bundled index.html at bob build time) gates Module.runApp("canvas")
behind BOTH the WASM runtime being ready AND the Poki SDK's init()
promise resolving:

    Module['onRuntimeInitialized'] = function() {
        isWasmLoaded = true;
        runFunc();  // only proceeds once isPokiSDKInited is ALSO true
    };

isPokiSDKInited is only ever set inside poki_sdk_loaded(), wired as the
game-cdn.poki.com <script>'s onload handler, with no onerror fallback.
In the one situation where that request can never complete at all (no
network route to the CDN), onload never fires, and the engine sits
fully loaded - archive, WASM, everything - but frozen forever on a
black canvas with no visible error, no console output, nothing to
click. In a normal browser with normal internet access, onload fires
within milliseconds as expected and this never comes up.

THE FIX
-------
Add a matching onerror="poki_sdk_unreachable()" handler to the same
<script> tag, plus the small poki_sdk_unreachable() function, so a
failed/unreachable CDN request unblocks the engine immediately instead
of hanging. In the real Poki-hosted environment (CDN reachable) onload
still wins normally within milliseconds and this fallback never fires -
production behavior is unchanged.

WHY THIS SCRIPT EXISTS
-----------------------
A project-level app-manifest override (an ext.manifest +
manifests/web/engine_template.html living in this repo, the same
mechanism extension-poki-sdk itself uses) would make this a tracked
source file instead of a build-cache edit. That was tried and Bob
didn't pick it up - not chased further, since this isn't a real
day-to-day issue (see plan.md §3.4).

The patch instead lives in the *cached* dependency zip under
.internal/lib/, which is NOT tracked by git and WILL be lost whenever
that cache entry is cleared or the poki-sdk dependency is re-fetched
(e.g. after deleting .internal/, or if extension-poki-sdk's main branch
moves and bob re-downloads it). Re-run this script if that ever matters
again (e.g. building somewhere without internet access) - it's
idempotent, safe to run repeatedly, and will just report "already
patched" if there's nothing to do.

Usage: python3 tools/patch_poki_sdk_local_dev.py
"""

import io
import os
import re
import sys
import zipfile

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_ROOT, ".internal", "lib")
TARGET_ENTRY_SUFFIX = "poki-sdk/manifests/web/engine_template.html"

MARKER = "poki_sdk_unreachable"

OLD_SCRIPT_TAG = (
    '<script defer src="https://game-cdn.poki.com/scripts/v2/poki-sdk.js" '
    'onload="poki_sdk_loaded()"></script>'
)
NEW_SCRIPT_TAG = (
    '<script defer src="https://game-cdn.poki.com/scripts/v2/poki-sdk.js" '
    'onload="poki_sdk_loaded()" onerror="poki_sdk_unreachable()"></script>'
)

FALLBACK_FUNCTION = """\t\t// Local-dev / offline fallback: the game-cdn.poki.com script can't
\t\t// be reached outside a real Poki-hosted iframe (no network, local
\t\t// testing, CDN down, etc.). Without this, onload above never
\t\t// fires, isPokiSDKInited stays false forever, and runFunc() -
\t\t// therefore Module.runApp("canvas") - never runs: the engine loads
\t\t// fully (archive, WASM, everything) but sits frozen on a black
\t\t// canvas with no visible error. onerror fires immediately when the
\t\t// script request fails, so this reacts right away rather than
\t\t// waiting on a blind timeout.
\t\tfunction poki_sdk_unreachable() {
\t\t\tconsole.warn("[poki-sdk] game-cdn.poki.com unreachable (local/offline dev) - starting engine without the Poki SDK.");
\t\t\tisPokiSDKInited = true;
\t\t\trunFunc();
\t\t}
"""


def find_dependency_zip():
    if not os.path.isdir(LIB_DIR):
        sys.exit(f"error: {LIB_DIR} does not exist - run `bob.jar resolve` first")
    for name in os.listdir(LIB_DIR):
        if not name.endswith(".zip"):
            continue
        path = os.path.join(LIB_DIR, name)
        try:
            with zipfile.ZipFile(path) as zf:
                for entry in zf.namelist():
                    if entry.endswith(TARGET_ENTRY_SUFFIX):
                        return path, entry
        except zipfile.BadZipFile:
            continue
    sys.exit(
        "error: no cached dependency zip containing "
        f"'{TARGET_ENTRY_SUFFIX}' was found under {LIB_DIR}\n"
        "Has the extension-poki-sdk dependency been resolved yet? "
        "(`bob.jar resolve`)"
    )


def patch_content(html):
    if MARKER in html:
        return None  # already patched

    if OLD_SCRIPT_TAG not in html:
        sys.exit(
            "error: the expected <script> tag was not found in "
            "engine_template.html - extension-poki-sdk's template has "
            "likely changed upstream. Not patching blindly; update this "
            "script's OLD_SCRIPT_TAG/insertion point by hand instead."
        )

    html = html.replace(OLD_SCRIPT_TAG, NEW_SCRIPT_TAG, 1)

    # Insert the fallback function right before the closing </script> tag
    # that follows poki_sdk_loaded()'s closing brace - i.e. right before
    # the single "\t</script>\n</body>" that ends the poki-sdk-setup
    # script block.
    closing = "\t</script>\n</body>"
    if closing not in html:
        sys.exit(
            "error: could not find the expected closing </script></body> "
            "sequence to insert the fallback function before - aborting "
            "without patching."
        )
    html = html.replace(closing, FALLBACK_FUNCTION + closing, 1)
    return html


def rewrite_zip(zip_path, target_entry, new_content):
    with zipfile.ZipFile(zip_path, "r") as zin:
        items = zin.infolist()
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zout:
            for item in items:
                data = zin.read(item.filename)
                if item.filename == target_entry:
                    data = new_content.encode("utf-8")
                zout.writestr(item, data)
    tmp_path = zip_path + ".tmp"
    with open(tmp_path, "wb") as f:
        f.write(buf.getvalue())
    os.replace(tmp_path, zip_path)


def main():
    zip_path, entry = find_dependency_zip()
    with zipfile.ZipFile(zip_path) as zf:
        original = zf.read(entry).decode("utf-8")

    patched = patch_content(original)
    if patched is None:
        print(f"already patched: {zip_path} ({entry})")
        return

    rewrite_zip(zip_path, entry, patched)
    print(f"patched: {zip_path} ({entry})")
    print("Rebuild the HTML5 bundle for this to take effect.")


if __name__ == "__main__":
    main()
