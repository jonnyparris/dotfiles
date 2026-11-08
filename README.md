dotfiles
========

zsh (zimfw), git, tmux, alacritty, plus [pi](https://github.com/earendil-works/pi) (coding agent) and
[cmux](https://www.cmux.dev/) (the terminal it runs in), set up so a new Mac looks and behaves like this one.

## New machine

```bash
xcode-select --install                                   # git + python3 (cmux/prefs.sh uses it)
# Homebrew: https://brew.sh
git clone https://github.com/jonnyparris/dotfiles ~/dotfiles
brew bundle --file ~/dotfiles/Brewfile                   # zoxide, fzf, ripgrep, fd, jq, gh, node, cmux, zed
~/dotfiles/makesymlinks.sh                               # links ~/.zshrc etc. here, then runs install-pi-cmux.sh
```

Then open a new terminal (zimfw installs its modules on first start), `gh auth login`, and start cmux.
Any file the scripts replace goes to `~/dotfiles_backup/` first.

Re-run `~/dotfiles/install-pi-cmux.sh` any time after changing `pi/`, `cmux/` or `ghostty/`. It is idempotent.

## What's here

| Path | What | Lands at |
|---|---|---|
| `zshenv`, `zshrc`, `zprofile` | shell: PATH, editor, zimfw bootstrap, zoxide/bun/uv hooks | `~/.zshenv` … (symlink) |
| `zimrc` | zimfw modules (asciiship prompt, completions, syntax highlighting, history search, autosuggestions) | `~/.zimrc` |
| `aliases`, `functions` | aliases and shell functions | `~/.aliases`, `~/.functions` |
| `gitconfig`, `gitignore_global` | git identity (GitHub noreply), `gh:`/`gist:` shortcuts, `gh` credential helper | `~/.gitconfig` … |
| `tmux.conf`, `tmux.conf.local`, `alacritty.yml` | tmux (oh-my-tmux) and alacritty | `~/.tmux.conf` … |
| `Brewfile` | the tools this config expects | `brew bundle` |
| `pi/settings.json` | base pi settings: packages `pi-cmux`, `rpiv-ask-user-question`; theme | merged into `~/.pi/agent/settings.json` |
| `pi/extensions/cmux-activity.ts` | publishes what pi is doing (✨ new, 🙋 waiting, ❌ error, ⚡ tool) to the cmux sidebar | `~/.pi/agent/extensions/` (symlink) |
| `pi/themes/matrix.json` | pi theme (`/settings` → theme) | `~/.pi/agent/themes/` (symlink) |
| `cmux/sidebars/pi-board.js` | cmux custom sidebar that renders pi state per workspace | `~/.config/cmux/sidebars/` (symlink) |
| `cmux/prefs.plist` + `cmux/prefs.sh` | cmux app preferences: sidebar look, blur and tint, pi-board as the sidebar, browser and quit behaviour | macOS preferences (`com.cmuxterm.app`) |
| `ghostty/config` | terminal look inside cmux: 70% opacity, background blur, `cmd+u` toggles opaque | `~/.config/ghostty/config` (symlink) |

### The translucent, blurred look

Two parts, both carried here:

- **Terminal:** `ghostty/config` (`background-opacity = 0.7`, `background-blur = true`). cmux embeds Ghostty and reads this file.
- **Sidebar and chrome:** cmux preferences in `cmux/prefs.plist` (`sidebarMatchTerminalBackground`, `sidebarMaterial`,
  `sidebarBlendMode`, `sidebarTintHex` / `sidebarTintOpacity`, …), plus `cmuxExtensionSidebarProviderId` =
  pi-board and `customSidebars.beta.enabled`.

### cmux preferences

```bash
~/dotfiles/cmux/prefs.sh capture   # after changing cmux settings you want to keep: writes cmux/prefs.plist, then commit
~/dotfiles/cmux/prefs.sh diff      # what apply would change on this Mac
~/dotfiles/cmux/prefs.sh apply     # quit cmux first; writes the keys with `defaults write`
```

`install-pi-cmux.sh` runs `apply` by itself once, and only on a Mac where cmux has none of these keys set yet. A Mac
with its own cmux settings keeps them. After a successful apply, or after keeping existing settings, it writes the
marker `~/.config/cmux/.dotfiles-prefs-applied` and leaves cmux prefs alone on later runs; use `diff` / `apply` by
hand to take the repo's. When it auto-applies, it first writes `~/.config/cmux/.dotfiles-prefs-pending` and
removes it only once apply succeeds. If cmux was open (apply refused) or apply failed, quit cmux and re-run: that run applies the repo's prefs without the "has its
own settings" check, overwriting any of these keys changed in cmux in between. If cmux was opened before the
installer ever ran, it may have saved some of these keys itself, so the Mac counts as having its own settings: run
`cmux/prefs.sh apply` once.
Only the keys listed in `KEYS` in `prefs.sh` travel, including
`customSidebars.beta.enabled`, which pi-board needs. Window positions, workspace layouts, browser profiles,
telemetry/device IDs, server feature flags and the socket password stay on the machine. `capture` lists setting-like
keys it didn't carry, so new cmux settings can be added to `KEYS` on purpose. cmux's own settings file (`~/.config/cmux/cmux.json`) isn't used for these: values set there become
"managed" and can no longer be changed in the UI.

### pi settings

pi writes to `~/.pi/agent/settings.json` itself (last changelog seen, theme…), so it is generated, not symlinked:

1. `pi/settings.json` gives the defaults,
2. the existing `~/.pi/agent/settings.json` overrides them,
3. `~/.pi/agent/settings.local.json` (optional, machine-local) overrides both.

`packages` and `extensions` are combined from all three, duplicates dropped. Packages installed with `pi install`
stay. To remove one, take it out of `~/.pi/agent/settings.json` as well as the file that adds it.

## Machine-local layer (never committed)

Each of these is loaded if it exists. Put secrets, work config and per-machine tweaks here. A private repo can
provide them as symlinks.

| File | Loaded by |
|---|---|
| `~/.zshenv.local` | end of `zshenv` (every zsh, including scripts): env vars, certs, secrets |
| `~/.zshrc.local` | end of `zshrc` (interactive shells): aliases, wrappers, tool setup |
| `~/.gitconfig.local` | end of `gitconfig`: work identity, extra CA certs |
| `~/.pi/agent/settings.local.json` | `install-pi-cmux.sh`: extra pi packages/extensions, default provider/model |

Created on the machine and never in this repo: `~/.pi/agent/auth.json` and `mcp-auth.json` (pi logins),
`~/.config/cmux/cmux.json` (holds cmux's socket password; `install-pi-cmux.sh` generates a random one).
`.gitignore` blocks `*.local`, `*.local.*`, `.secrets*`, `.env`, `auth*.json`, `mcp-auth*.json`, `cmux.json` and
`socket-password` in case one lands in the repo.

## Commits

Commit as `jonnyparris <6400000+jonnyparris@users.noreply.github.com>` (set in this repo's `.git/config`; a work
`~/.gitconfig.local` would otherwise win). This account has GitHub's "block pushes that expose my email" on.
