# Add aliases.
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Add functions.
if [ -f ~/.functions ]; then
  source ~/.functions
fi

# A more colorful prompt
# \[\e[0m\] resets the color to default color
c_reset='\[\e[0m\]'
#  \e[0;35m\ sets the color to purple
c_path='\[\e[0;35m\]'
# \e[0;32m\ sets the color to green
c_git_clean='\[\e[0;32m\]'
# \e[0;31m\ sets the color to red
c_git_dirty='\[\e[0;31m\]'

# PS1 is the variable for the prompt you see everytime you hit enter
PROMPT_COMMAND='PS1="${c_path}\W${c_reset}$(git_prompt) :> "'
export PS1='\n\[\033[0;31m\]\W\[\033[0m\]$(git_prompt)\[\033[0m\]:> '

# old PS1 colours from Landey for reverting to later if needed.
# PS1='\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;32m\]\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '

#enables colouring of the terminal
export CLICOLOR=1
# Enables colours of xterm, the standard mac terminal(?)
export TERM="xterm-color"

# Colours that the ls command should use for files, folders, links,  etc. (see man ls and search for LSCOLORS)
export LSCOLORS=GxFxCxDxBxegedabagaced

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin"

# Add yarn global executables to path as a hotfix until they sort their bugs out
# https://github.com/yarnpkg/yarn/issues/1151
export PATH="$PATH:$HOME/.config/yarn/global/node_modules/.bin"

# Add Flutter
export PATH="$PATH:$HOME/dev/flutter/bin"
