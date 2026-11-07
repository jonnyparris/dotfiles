# Start configuration added by Zim install {{{
#
# User configuration sourced by all invocations of the shell
#

# Define Zim location
: ${ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim}
# }}} End configuration added by Zim install

# better put some respect on yo name
# echo "BEHOLD! $USER has logged in at $(hostname)"

# Not 100% sure what this achieves but I think it was here by default so I'm not messing with it.
export PATH=/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH
export PATH=/usr/local/bin:$PATH

# Path for flutter
test -d /usr/local/bin && export PATH="$PATH:~/dev/flutter/bin"

# Path for Heroku
test -d /usr/local/heroku/ && export PATH="/usr/local/heroku/bin:$PATH"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# set default text editor
export EDITOR='zed --wait'
export VISUAL="$EDITOR"

# Rbenv autocomplete and shims
if which rbenv >/dev/null; then eval "$(rbenv init -)"; fi
# Path for RBENV
test -d $HOME/.rbenv/ && PATH="$HOME/.rbenv/bin:$PATH"

export PATH="/usr/local/opt/ruby/bin:$PATH"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# pi: cmux-activity.ts owns the cmux progress channel; disable pi-cmux sidebar writer
export PI_CMUX_SIDEBAR=0

# Machine-local env (secrets, work certs). Never committed.
if [ -f "$HOME/.zshenv.local" ]; then . "$HOME/.zshenv.local"; fi
