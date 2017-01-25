#alias
alias ll="ls -l"
alias lls="ll --sort=size"
alias lle="ll --sort=extension"
alias llt="ll -t"
alias grep="grep --color=always"

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
alias gbd="git branch --merged | grep -v '*' | xargs -i git branch -d {}"

#vim
alias vi="vim"
alias view='vim -R -'
alias mysqlu="mysql --default-character-set=utf8"
alias psgrep="ps aux | grep "

alias V='vim -R -'
alias Gc='grep -c'
alias G='grep'
alias ZG='zgrep'
alias cs='cheat'

#env
alias ne="ndenv exec"
alias pe="plenv exec "
alias ce="carton exec"
alias re="rbenv exec "
alias be="bundle exec"

alias L="less"
alias G="grep"
alias GC="grep --color=always"

# log file utility
# ltsv to json from fluentd
alias ltoj="awk -F\"\\t\" '{print \$3}'"
alias jqless="jq '.' -C | less -R"
# for twitter
alias twjq="jq --unbuffered -C '{start: .started, end: .finished, req_method: .payload.request.method, req_path: .payload.request.path, req_body: .payload.request.body, res_code: .payload.response.code, res_body: .payload.response.body|fromjson }'"
alias twjqless="jq --unbuffered -C '{start: .started, end: .finished, req_method: .payload.request.method, req_path: .payload.request.path, req_body: .payload.request.body, res_code: .payload.response.code, res_body: .payload.response.body|fromjson }' | less -R "
# url decode
alias ud="perl -Xnpe '$|=1; s/\\?/\\n/g; s/&/\\n/g; s/=/:\\t/g' | nkf -u --url-input"

# docker-compose
alias dkc="sudo docker-compose"
alias dkce="sudo docker-compose exec"
alias dkcps="sudo docker-compose ps"
alias dkclogs="sudo docker-compose logs"
alias dkctop="sudo docker-compose top"

# docker
alias dk="sudo docker"
alias dke="sudo docker exec"
alias dkps="sudo docker ps"
alias dklogs="sudo docker logs"
alias dktop="sudo docker top"


