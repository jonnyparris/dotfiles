#navigation
alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

#long list alias
alias ll='ls -pl'

#short list alias with hidden files included
alias la='ls -ap'

#only list directories
alias lsd='ls -l | grep "^d"'

#function combines cd with ls, because who ever knows where they're going??
cdd()
{
cd $1 && ls -p
}

#toggle view hidden files in finder super easily
alias show='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hide='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

#git aliases for everyday use
alias s='git status '
alias a='git add '
alias c='git commit -m '
alias gb='git branch '
alias gcb='git checkout -b '
alias gco='git checkout'
alias gpm='git push origin master'
alias gp='git push origin '
alias gd='git diff'
alias gcl='git clone'
alias gl='git log'

# Undo a `git push`
alias undopush="git push -f origin HEAD^:master"

#rails aliases
alias r='rspec '
alias be='bundle exec '

#even faster sublime opener
alias e='subl '

#rspec with color every time
alias rspec='rspec -c '

#reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"
