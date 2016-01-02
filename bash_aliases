#function combines cd with ls, because who ever knows where they're going??
cdd()
{
cd $1 && ls -p
}

#navigation
alias ..="cdd .."
alias ...="cdd ../.."
alias ....="cdd ../../.."
alias .....="cdd ../../../.."

#long list alias
alias ll='ls -pl'

#short list alias with hidden files included
alias la='ls -ap'

#only list directories
alias lsd='ls -l | grep "^d"'

#toggle view hidden files in finder super easily
alias showall='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideall='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

#git aliases for everyday use
alias g='git'
alias s='git status'
alias a='git add'
alias a.='git add .'
alias ap='git add -p'
alias c='git commit -m'
alias cv='git commit -v'
alias ca='git commit --amend'
alias gb='git branch'
alias gcb='git checkout -b'
alias gco='git checkout'
alias gpm='git push origin master'
alias gp='git push -u origin HEAD'
alias gd='git diff'
alias gcl='git clone'
alias gl='git log'

# Undo a `git push`
alias undopush="git push -f origin HEAD^:master"

#rails aliases
alias r='rspec'
alias rk='rake'
alias rka='rake assets:precompile'
alias be='bundle exec'

#even faster sublime opener
alias e='subl'

#rspec with color every time
alias rspec='rspec -c'

#reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"

#heroku debugging
alias h='heroku'
alias hr='heroku restart'
alias gph='git push heroku master'
alias prec="rka && a . && c 'assets precompile' && gph && hr"

#docker
alias d='docker '
alias dm='docker-machine '
alias dinit="eval '$(docker-machine env default)' "
alias dbash='docker run -t -i ubuntu /bin/bash'
alias dcleani='printf "\n>>> Deleting untagged images\n\n" && docker rmi $(docker images -q -f dangling=true)'
