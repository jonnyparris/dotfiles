#!/usr/bin/env bash
# Carry cmux app preferences (sidebar look, blur/tint, custom sidebar choice, browser + quit behaviour) between Macs.
#
#   cmux/prefs.sh capture   # this Mac's cmux preferences -> cmux/prefs.plist (commit it)
#   cmux/prefs.sh apply     # cmux/prefs.plist -> this Mac's cmux preferences (quit cmux first)
#   cmux/prefs.sh diff      # what apply would change
#
# Only allowlisted scalar keys travel. Window geometry, workspace layouts, browser profiles, telemetry and device IDs,
# feature flags and the socket password stay on the machine. The terminal's own translucency and blur
# (background-opacity / background-blur) live in ghostty/config, which cmux reads.
set -euo pipefail
DOMAIN=${CMUX_PREFS_DOMAIN:-com.cmuxterm.app}  # override for testing
FILE="$(cd "$(dirname "$0")" && pwd)/prefs.plist"
PLIST="$HOME/Library/Preferences/$DOMAIN.plist"
cmd=${1:-}

[ "$(uname)" = Darwin ] || { echo "cmux prefs: macOS only" >&2; exit 0; }
case "$cmd" in capture|apply|diff) ;; *) sed -n '2,8p' "$0" >&2; exit 2 ;; esac
if [ "$cmd" = apply ] && [ "$(osascript -e "application id \"$DOMAIN\" is running" 2>/dev/null)" = true ]; then
  echo "cmux prefs: cmux is running; quit it first or it may write its in-memory values back on quit" >&2
  exit 1
fi
[ "$cmd" = capture ] && defaults export "$DOMAIN" "$PLIST.export" 2>/dev/null || true

python3 - "$cmd" "$DOMAIN" "$FILE" "$PLIST" <<'PY'
import os, plistlib, subprocess, sys
cmd, domain, file, live = sys.argv[1:]

PREFIXES = ("sidebar", "terminal.", "sleepyMode.", "customSidebars.", "rightSidebar.", "fileExplorer.", "markdown.",
            "browserSearchEngine", "browserIntercept", "browserOpenTerminal")
EXACT = {"appearanceMode", "confirmQuit", "workspacePresentationMode", "cmuxExtensionSidebarProviderId"}
SCALARS = (bool, int, float, str)

def wanted(d):
    return {k: v for k, v in sorted(d.items())
            if (k in EXACT or k.startswith(PREFIXES)) and isinstance(v, SCALARS)}

def load(path):
    try:
        with open(path, "rb") as f:
            return plistlib.load(f)
    except FileNotFoundError:
        return {}

if cmd == "capture":
    exported = live + ".export"
    cur = wanted(load(exported))
    if os.path.exists(exported):
        os.remove(exported)
    if not cur:
        sys.exit("cmux prefs: nothing to capture (has cmux run on this Mac?)")
    with open(file, "wb") as f:
        plistlib.dump(cur, f, sort_keys=True)
    print(f"captured {len(cur)} keys -> {file}")
    sys.exit(0)

want = load(file)
if not want:
    sys.exit(f"cmux prefs: {file} missing or empty; run capture on a Mac that has the look you want")
have = load(live)
def same(a, b):
    if isinstance(a, float) and isinstance(b, float):
        return abs(a - b) < 1e-6  # `defaults write -float` stores 32-bit
    return type(a) is type(b) and a == b

changes = {k: v for k, v in want.items() if not same(have.get(k), v)}
for k, v in changes.items():
    print(f"  {k}: {have.get(k)!r} -> {v!r}")
if cmd == "diff" or not changes:
    print("no changes" if not changes else f"{len(changes)} change(s)")
    sys.exit(0)
for k, v in changes.items():
    t = "-bool" if isinstance(v, bool) else "-int" if isinstance(v, int) else "-float" if isinstance(v, float) else "-string"
    val = ("true" if v else "false") if isinstance(v, bool) else str(v)
    subprocess.run(["defaults", "write", domain, k, t, val], check=True)
print(f"applied {len(changes)} key(s); start cmux")
PY
