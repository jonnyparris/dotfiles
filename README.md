dotfiles
========

zsh (zimfw), git, tmux, alacritty, plus pi (coding agent) and cmux.

New machine:

```bash
git clone https://github.com/jonnyparris/dotfiles ~/dotfiles
brew bundle --file ~/dotfiles/Brewfile   # zoxide, fzf, jq, node, gh, cmux…
~/dotfiles/makesymlinks.sh               # ~/.zshrc etc. -> here, then install-pi-cmux.sh
```

| Path | What |
|---|---|
| `zshenv`, `zshrc`, `zprofile`, `zimrc`, `aliases`, `functions` | shell; zimfw self-installs on first start |
| `pi/settings.json` | base pi settings, merged into `~/.pi/agent/settings.json` by `install-pi-cmux.sh` |
| `pi/extensions/cmux-activity.ts` | publishes pi's live activity to the cmux sidebar |
| `pi/themes/matrix.json` | pi theme |
| `cmux/sidebars/pi-board.js` | cmux sidebar that renders it |
| `ghostty/config` | terminal look for cmux (embeds Ghostty) |

Machine-local, never committed (sourced/merged if present):
`~/.zshenv.local`, `~/.zshrc.local`, `~/.gitconfig.local`, `~/.pi/agent/settings.local.json`.
Secrets and work config go there. Auth files (`~/.pi/agent/auth.json`, `mcp-auth.json`, `~/.config/cmux/cmux.json`) are created on the machine.
