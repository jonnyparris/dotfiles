#!/usr/bin/env bash
# Carry cmux app preferences (sidebar look, blur/tint, custom sidebar choice, browser + quit behaviour) between Macs.
#
#   cmux/prefs.sh capture   # this Mac's cmux preferences -> cmux/prefs.plist (commit it)
#   cmux/prefs.sh apply     # cmux/prefs.plist -> this Mac's cmux preferences (quit cmux first; exit 4 if it's open)
#   cmux/prefs.sh diff      # what apply would change
#   cmux/prefs.sh fresh     # exit 0: none of the carried keys set yet; 3: cmux has its own; other: error (install-pi-cmux.sh)
#
# Only the keys in KEYS below travel (plain values only). Window geometry, workspace layouts, browser profiles, telemetry
# and device IDs, server feature flags and the socket password stay on the machine. `capture` lists keys that look like
# settings but aren't in KEYS, so you can decide to add them; it never adds them by itself. The terminal's own translucency and blur
# (background-opacity / background-blur) live in ghostty/config, which cmux reads.
set -euo pipefail
DOMAIN=${CMUX_PREFS_DOMAIN:-com.cmuxterm.app}  # override for testing
FILE="$(cd "$(dirname "$0")" && pwd)/prefs.plist"
cmd=${1:-}

[ "$(uname)" = Darwin ] || { echo "cmux prefs: macOS only" >&2; exit 0; }
case "$cmd" in capture|apply|diff|fresh) ;; *) sed -n '2,8p' "$0" >&2; exit 2 ;; esac
if [ "$cmd" = apply ] && [ "$(osascript -e "application id \"$DOMAIN\" is running" 2>/dev/null)" = true ]; then
  echo "cmux prefs: cmux is running; quit it first or it may write its in-memory values back on quit" >&2
  exit 4  # install-pi-cmux.sh keys its "pending" retry on this code
fi
if [ "$cmd" = capture ] && [ "$(osascript -e "application id \"$DOMAIN\" is running" 2>/dev/null)" = true ]; then
  echo "cmux prefs: cmux is running; capturing what it has saved so far (change a setting, then capture, is fine)" >&2
fi
EXPORT=$(mktemp)
trap 'rm -f "$EXPORT"' EXIT
# A domain cmux never wrote exports fine (empty dict); any failure here is real, so stop rather than treat it as empty.
defaults export "$DOMAIN" "$EXPORT" || { echo "cmux prefs: can't read $DOMAIN preferences" >&2; exit 1; }

python3 - "$cmd" "$DOMAIN" "$FILE" "$EXPORT" <<'PY'
import plistlib, subprocess, sys
cmd, domain, file, live = sys.argv[1:]

KEYS = {
    # look: sidebar material, blur, tint; terminal translucency itself is ghostty/config
    "appearanceMode", "sidebarAppearanceDefaultsVersion", "sidebarBlendMode", "sidebarBlurOpacity",
    "sidebarCornerRadius", "sidebarMatchTerminalBackground", "sidebarMaterial", "sidebarPreset", "sidebarState",
    "sidebarTintHex", "sidebarTintOpacity", "workspacePresentationMode", "sleepyMode.glow", "markdown.fontFamily",
    # sidebar content and layout; pi-board as the sidebar needs custom sidebars switched on
    "cmuxExtensionSidebarProviderId", "customSidebars.beta.enabled", "sidebarBranchDirectoryStacked",
    "sidebarHideAllDetails", "sidebarWrapWorkspaceTitles", "rightSidebar.mode", "fileExplorer.width",
    # behaviour
    "confirmQuit", "terminal.copyOnSelect", "browserSearchEngine",
    "browserInterceptTerminalOpenCommandInCmuxBrowser", "browserOpenTerminalLinksInCmuxBrowser",
}
# Keys that look like settings, for capture's "not carried" hint
HINT = ("sidebar", "terminal.", "sleepyMode.", "customSidebars.", "rightSidebar.", "fileExplorer.", "markdown.", "browser")
SCALARS = (bool, int, float, str)

def wanted(d):
    return {k: v for k, v in sorted(d.items()) if k in KEYS and isinstance(v, SCALARS)}

def load(path):
    try:
        with open(path, "rb") as f:
            d = plistlib.load(f)
    except FileNotFoundError:
        return {}
    except OSError as e:
        sys.exit(f"cmux prefs: can't read {path} ({e.strerror})")
    except Exception as e:  # truncated XML, garbage, binary errors…
        sys.exit(f"cmux prefs: {path} is not a valid plist ({type(e).__name__})")
    if not isinstance(d, dict):
        sys.exit(f"cmux prefs: {path} is not a dictionary plist")
    return d

if cmd == "fresh":
    sys.exit(3 if any(k in KEYS for k in load(live)) else 0)

if cmd == "capture":
    allp = load(live)
    cur = wanted(allp)
    extra = [k for k, v in sorted(allp.items()) if k not in KEYS and k.startswith(HINT) and isinstance(v, SCALARS)]
    if extra:
        print("not carried (add to KEYS in prefs.sh if wanted): " + ", ".join(extra))
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
def num(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool)

def same(a, b):
    if num(a) and num(b):
        return abs(a - b) < 1e-6  # `defaults write -float` stores 32-bit; cmux may store 295 as int or real
    return type(a) is type(b) and a == b

changes = {k: v for k, v in want.items() if not same(have.get(k), v)}
for k, v in changes.items():
    print(f"  {k}: {have.get(k)!r} -> {v!r}")
if cmd == "diff" or not changes:
    print("no changes" if not changes else f"{len(changes)} change(s)")
    sys.exit(0)
failed = []
for k, v in changes.items():
    t = "-bool" if isinstance(v, bool) else "-int" if isinstance(v, int) else "-float" if isinstance(v, float) else "-string"
    val = ("true" if v else "false") if isinstance(v, bool) else str(v)
    if subprocess.run(["defaults", "write", domain, k, t, val]).returncode != 0:
        failed.append(k)
print(f"applied {len(changes) - len(failed)} key(s); start cmux")
if failed:
    sys.exit("cmux prefs: failed to write " + ", ".join(failed))
PY
