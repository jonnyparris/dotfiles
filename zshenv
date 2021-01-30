# better put some respect on yo name
echo "BEHOLD! $USER has logged in at $(hostname)"

# Not 100% sure what this achieves but I think it was here by default so I'm not messing with it.
export PATH=/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH
export PATH=/usr/local/bin:$PATH

# Path for flutter
test -d /usr/local/bin && export PATH="$PATH:~/dev/flutter/bin"

# Path for Heroku
test -d /usr/local/heroku/ && export PATH="/usr/local/heroku/bin:$PATH"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Force grep to always use the color option
export GREP_OPTIONS='--color=auto'

# set default text editor
export EDITOR='code -w'

# Rbenv autocomplete and shims
if which rbenv >/dev/null; then eval "$(rbenv init -)"; fi
# Path for RBENV
test -d $HOME/.rbenv/ && PATH="$HOME/.rbenv/bin:$PATH"

export PATH="/usr/local/opt/ruby/bin:$PATH"
