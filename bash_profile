# echo is like puts (ruby) for bash
echo "BEHOLD! $USER has logged in at $(hostname)"

# Load the default .profile - the [] brackets are just another way of running the test command (see bash manual)
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"

# .bashrc is what loads for every new bash instance, regardless of profile.
# aliases are loaded from within that file.
source ~/.bashrc

# Not 100% sure what this achieves but I think it was here by default so I'm not messing with it.
export PATH=/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH
export PATH=/usr/local/bin:$PATH

# Path for brew
test -d /usr/local/bin && export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
# Path for Heroku
test -d /usr/local/heroku/ && export PATH="/usr/local/heroku/bin:$PATH"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Force grep to always use the color option
export GREP_OPTIONS='--color=always'

# set sublime as default text editor
export EDITOR='subl -w'

# setup git autocomplete
if [ -f $(brew --prefix)/etc/bash_completion ]; then
	. $(brew --prefix)/etc/bash_completion
fi

# Rbenv autocomplete and shims
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# Path for RBENV
test -d $HOME/.rbenv/ && PATH="$HOME/.rbenv/bin:$PATH"
