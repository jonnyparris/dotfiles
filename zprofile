# Homebrew (Apple Silicon first, then Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# macOS path_helper (/etc/zprofile) moves entries zshenv added behind the system ones; put ~/.local/bin back in front.
# Deliberately ahead of Homebrew: user-level installs (pi, uv tools) win, as uv's own env hook intends.
path=("$HOME/.local/bin" "${(@)path:#$HOME/.local/bin}")
