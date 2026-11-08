#!/usr/bin/env bash
# Set up pi (coding agent) + cmux from this repo. Idempotent: re-run after editing anything under pi/, cmux/ or ghostty/.
#
#   - installs pi (npm) if missing; cmux comes from the Brewfile (`brew bundle --file ~/dotfiles/Brewfile`)
#   - symlinks pi extensions + themes, the cmux sidebar and the Ghostty config cmux embeds
#   - writes ~/.pi/agent/settings.json: pi/settings.json gives defaults, the existing file (what pi or you set,
#     lastChangelogVersion, theme…) overrides them, ~/.pi/agent/settings.local.json (optional, machine-local, never
#     committed) overrides both. `packages` and `extensions` are concatenated (existing, base, local; duplicates
#     dropped), so entries added with `pi install` survive; removing one means editing ~/.pi/agent/settings.json too
#   - creates ~/.config/cmux/cmux.json with a fresh random socket password if it doesn't exist
#   - applies cmux/prefs.plist (cmux app preferences) on a Mac where cmux has none yet
#
# Secrets never live in this repo: pi auth is in ~/.pi/agent/auth.json / mcp-auth.json, cmux's socket password in
# ~/.config/cmux/cmux.json — all created on the machine.
set -euo pipefail
DOT=$(cd "$(dirname "$0")" && pwd)
PI=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
CMUX=$HOME/.config/cmux

command -v jq >/dev/null || { echo "install-pi-cmux: needs jq (brew bundle --file $DOT/Brewfile)" >&2; exit 1; }
# A cmux shim (…/cmux-cli-shims/…/pi) doesn't count as installed; any other pi on PATH does.
# Installs into ~/.local (user-writable), not npm's global prefix, which may be root-owned. ~/.local/bin goes on this
# script's PATH so an existing install is found from bash too; zshenv/zprofile put it on the shell's PATH.
export PATH="$HOME/.local/bin:$PATH"
if ! type -ap pi | grep -qv '/cmux-cli-shims/'; then
  echo "installing pi into ~/.local…"
  npm install -g --prefix "$HOME/.local" @earendil-works/pi-coding-agent
fi

BACKUP=$HOME/dotfiles_backup
link() {
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && [ ! -L "$2" ]; then mkdir -p "$BACKUP"; mv "$2" "$BACKUP/$(basename "$2").$(date +%Y%m%d%H%M%S)"; echo "  backed up $2 to $BACKUP"; fi
  ln -sfn "$1" "$2"; echo "  $2 -> $1"
}
mkdir -p "$PI/extensions" "$PI/themes" "$CMUX/sidebars" "$HOME/.config/ghostty"
for f in "$DOT"/pi/extensions/*; do link "$f" "$PI/extensions/$(basename "$f")"; done
for f in "$DOT"/pi/themes/*; do link "$f" "$PI/themes/$(basename "$f")"; done
for f in "$DOT"/cmux/sidebars/*; do link "$f" "$CMUX/sidebars/$(basename "$f")"; done
link "$DOT/ghostty/config" "$HOME/.config/ghostty/config"

# settings.json: merge, don't symlink (pi writes to it)
existing=$PI/settings.json local=$PI/settings.local.json
[ -f "$existing" ] || echo '{}' > "$existing"
[ -f "$local" ] && overlay=$local || overlay=/dev/null
tmp=$(mktemp)
jq -s '
  def uniq: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
  (.[0] // {}) as $e | (.[1] // {}) as $b | (.[2] // {}) as $o
  | ($b * $e * $o)
  | .packages = ((($e.packages // []) + ($b.packages // []) + ($o.packages // [])) | uniq)
  | .extensions = ((($e.extensions // []) + ($b.extensions // []) + ($o.extensions // [])) | uniq)
' "$existing" "$DOT/pi/settings.json" <(cat "$overlay") > "$tmp"
mv "$tmp" "$PI/settings.json"
[ "$overlay" = /dev/null ] && echo "  $PI/settings.json (base)" || echo "  $PI/settings.json (base + settings.local.json)"

if [ ! -f "$CMUX/cmux.json" ]; then
  umask 077
  pw=$(openssl rand -hex 16)
  jq -n --arg pw "$pw" '{schemaVersion: 1, "$schema": "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json",
    automation: {socketControlMode: "password", socketPassword: $pw}}' > "$CMUX/cmux.json"
  echo "  $CMUX/cmux.json (new socket password)"
fi

# cmux app preferences (sidebar look, blur/tint, pi-board sidebar): apply automatically only on a Mac where cmux has no
# preferences yet, so re-runs never undo changes made in cmux's UI. Otherwise: cmux/prefs.sh diff / apply.
if [ "$(uname)" = Darwin ] && [ -f "$DOT/cmux/prefs.plist" ]; then
  if ! defaults read com.cmuxterm.app >/dev/null 2>&1; then
    "$DOT/cmux/prefs.sh" apply || echo "  cmux prefs not applied; quit cmux and run $DOT/cmux/prefs.sh apply" >&2
  else
    echo "  cmux prefs: existing preferences kept; '$DOT/cmux/prefs.sh diff' shows what apply would change"
  fi
fi

echo "done. Restart pi (or /reload) and cmux to pick changes up."
