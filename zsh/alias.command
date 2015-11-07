#alias
alias ll="ls -l"
alias lls="ll --sort=size"
alias lle="ll --sort=extension"
alias llt="ll -t"

#svn
alias smdrc="svn merge --dry-run -c"
alias smc="svn merge -c"
alias sst="svn st"
alias sstu="svn st -u"
alias sstug="svn st -u | grep '*'"
alias sdi="svn diff"
alias sci="svn ci"
alias srv="svn revert"

#git
alias gst="git status"
alias gba="git branch -a"
alias gci="git commit"
alias gpush="git push"
alias gpull="git pull"
alias gsstash="git stash"
alias gad="git add"
alias gsp="git stash pop"
alias gdic="git diff --cached"
alias gdi="git diff"

#vim
alias vi="vim"
alias view='vim -R -'
alias mysqlu="mysql --default-character-set=utf8"
alias psgrep="ps aux | grep "

#env
alias ne="ndenv exec"
alias pe="plenv exec "
alias ce="carton exec"
alias re="rbenv exec "
alias be="bundle exec"

