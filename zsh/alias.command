#alias
alias ll="ls -l"
alias lls="ll --sort=size"
alias l="eza --icons"
alias la="eza -al --icons"
alias laa="eza -al --icons -h -U -m -u --time-style relative --total-size"

alias lle="ll --sort=extension"
alias llt="ll -t"
alias grep="grep --color=always --line-buffered"

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
alias gc="git commit"
alias gpush="git push"
alias gpull="git pull"
alias gsstash="git stash"
alias gad="git add"
alias gsp="git stash pop"
alias gdic="git diff --cached"
alias gdi="git diff"
alias gbd="git branch --merged | grep -v '*' | xargs -i git branch -d {}"
alias ds="delta -s"

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
# json array to csv [{a:1,...},{....}] to csv
alias jtoc="jq -r '(.[0]|to_entries|map(.key)),(.[]|[.[]])|@csv'"
# for twitter
alias twjq="jq --unbuffered -C '{start: .started, end: .finished, req_method: .payload.request.method, req_path: .payload.request.path, req_body: .payload.request.body, res_code: .payload.response.code, res_body: .payload.response.body|fromjson }'"
alias twjqless="jq --unbuffered -C '{start: .started, end: .finished, req_method: .payload.request.method, req_path: .payload.request.path, req_body: .payload.request.body, res_code: .payload.response.code, res_body: .payload.response.body|fromjson }' | less -R "
# url decode
alias url="perl -Xnpe '$|=1; s/\\?/\\n/g; s/&/\\n/g; s/=/:\\t/g' | nkf -u --url-input"
# unicode decode
alias uni="perl -Xpne 's/\\\u([0-9a-fA-F]{4})/chr(hex($1))/eg'"

# docker-compose
alias dkc="sudo -E $(which docker) compose"
alias dkce="sudo -E $(which docker) comopse exec"
alias dkcps="sudo -E $(which docker) compose ps"
alias dkclogs="sudo -E $(which docker) compose logs"
alias dkctop="sudo -E $(which docker) compose top"

# docker
alias dk="sudo -E docker"
alias dke="sudo -E docker exec"
alias dkps="sudo -E docker ps"
alias dklogs="sudo -E docker logs"
alias dktop="sudo -E docker top"

# tmux
alias tmcp="xargs -0 tmux set-buffer"

# pnpm
alias pn="pnpm"

# xclip Copy without escape sequences
alias xcp="sed 's/\x1b\[[0-9;]*m//g' | xclip -sel c -r"

