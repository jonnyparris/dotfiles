#long list alias
alias ll='ls -pl'

#short list alias with hidden files included
alias la='ls -ap'

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

#rails aliases
alias r='rspec '

#even faster sublime opener
alias e='subl '

#even faster sublime opener
alias be='bundle exec '

#rspec with color every time
alias rspec='rspec -c '