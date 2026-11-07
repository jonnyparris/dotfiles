# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
# Download to a temp file and move it in, so a failed download is retried next start.
if [[ ! -s ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh.tmp.$$ \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh \
      && mv ${ZIM_HOME}/zimfw.zsh.tmp.$$ ${ZIM_HOME}/zimfw.zsh \
      || rm -f ${ZIM_HOME}/zimfw.zsh.tmp.$$
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh.tmp.$$ \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh \
      && mv ${ZIM_HOME}/zimfw.zsh.tmp.$$ ${ZIM_HOME}/zimfw.zsh \
      || rm -f ${ZIM_HOME}/zimfw.zsh.tmp.$$
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ -s ${ZIM_HOME}/zimfw.zsh && ( ! -s ${ZIM_HOME}/init.zsh || ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ) ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
# Initialize modules.
if [[ -s ${ZIM_HOME}/init.zsh ]]; then source ${ZIM_HOME}/init.zsh; else print -u2 "zim: ${ZIM_HOME}/init.zsh missing (zimfw download failed?); open a new shell when online"; fi

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install

# Add aliases.
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Add functions.
if [ -f ~/.functions ]; then
  source ~/.functions
fi

#enables colouring of the terminal
export CLICOLOR=1

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin"

# Add yarn global executables to path as a hotfix until they sort their bugs out
# https://github.com/yarnpkg/yarn/issues/1151
export PATH="$PATH:$HOME/.config/yarn/global/node_modules/.bin"

# Add Flutter
export PATH="$PATH:$HOME/dev/flutter/bin"

# Add Cargo
export PATH="$PATH:$HOME/.cargo/bin"

# Windsurf
[ -d "$HOME/.codeium/windsurf/bin" ] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# zoxide (aliases: cd -> z)
(( ${+commands[zoxide]} )) && eval "$(zoxide init zsh)"

# uv / pipx-style ~/.local/bin
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Machine-local interactive config (work tools, wrappers). Never committed.
if [ -f "$HOME/.zshrc.local" ]; then source "$HOME/.zshrc.local"; fi
