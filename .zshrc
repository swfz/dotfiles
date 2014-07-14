# servers
if [ -f $HOME/practice/.alias.server ]; then
  source $HOME/practice/.alias.server
fi
if [ -f $HOME/dotfiles/.alias.command ]; then
  source $HOME/dotfiles/.alias.command
fi
if [ -f $HOME/dotfiles/.functions ]; then
  source $HOME/dotfiles/.functions
fi
umask 002

#env
export EDITOR=vim
export SVN_EDITOR=vim
export LC_CTYPE=ja_JP.utf8

# complete
autoload -U compinit
compinit

setopt ZLE
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -Uz is-at-least

#color settings
autoload -Uz colors
colors

#powerline
source $HOME/.vim/bundle/powerline/powerline/bindings/zsh/powerline.zsh

# prompt
setopt prompt_subst
#PROMPT="[%F{cyan}%n%f@%F{cyan}%m%f %F{magenta}%c%f ]$"
PROMPT="$PROMPT
%F{074}[%C]$%f "
SPROMPT="%F{red}correct: %R -> %r ? [n,y,a,e] %f"

# ls color
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
alias ls='ls -F --color'

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history

# vim-keybind
bindkey -v

# history search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# options
setopt auto_cd
setopt auto_pushd
setopt correct
setopt list_packed
setopt nolistbeep

function colorlist(){
  for c in {000..255}; do echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;done;echo
}



#VCS status to RPROMPT
zstyle ':vcs_info:*' max-exports 3
zstyle ':vcs_info:*' enable git svn
# misc(%m)
zstyle ':vcs_info:*' formats '(%s)-[%b]'
zstyle ':vcs_info:*' actionformats '(%s)-[%b]' '%m' '<!%a>'
zstyle ':vcs_info:svn:*' formats '%F{075}(%s)%f-%F{208}[%b]%f %F{200}%u%f'
zstyle ':vcs_info:svn+set-message:*' hooks svn-extra-info


if is-at-least 4.3.10; then
    # git
    zstyle ':vcs_info:git:*' formats '(%s)-[%b]' '%c%u %m'
    zstyle ':vcs_info:git:*' actionformats '(%s)-[%b]' '%c%u %m' '<!%a>'
    zstyle ':vcs_info:git:*' check-for-changes true
    zstyle ':vcs_info:git:*' stagedstr "+"    # %c
    zstyle ':vcs_info:git:*' unstagedstr "-"  # %u
fi

# hooks
if is-at-least 4.3.11; then
    # formats '(%s)-[%b]' '%c%u %m' , actionformats '(%s)-[%b]' '%c%u %m' '<!%a>'
    zstyle ':vcs_info:git+set-message:*' hooks \
                                            git-hook-begin \
                                            git-untracked \
                                            git-push-status \
                                            git-nomerge-branch \
                                            git-stash-count
    function +vi-git-hook-begin() {
        if [[ $(command git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
            return 1
        fi
        return 0
    }

    function +vi-git-untracked() {
        if [[ "$1" != "1" ]]; then
            return 0
        fi

        if command git status --porcelain 2> /dev/null \
            | awk '{print $1}' \
            | command grep -F '??' > /dev/null 2>&1 ; then

            # unstaged (%u)
            hook_com[unstaged]+='?'
        fi
    }

    function +vi-git-push-status() {
        if [[ "$1" != "1" ]]; then
            return 0
        fi

        if [[ "${hook_com[branch]}" != "master" ]]; then
            return 0
        fi

        local ahead
        ahead=$(command git rev-list origin/master..master 2>/dev/null \
            | wc -l \
            | tr -d ' ')

        if [[ "$ahead" -gt 0 ]]; then
            # misc (%m)
            hook_com[misc]+="(p${ahead})"
        fi
    }

    # (mN) to misc (%m)
    function +vi-git-nomerge-branch() {
        if [[ "$1" != "1" ]]; then
            return 0
        fi

        if [[ "${hook_com[branch]}" == "master" ]]; then
            return 0
        fi

        local nomerged
        nomerged=$(command git rev-list master..${hook_com[branch]} 2>/dev/null | wc -l | tr -d ' ')

        if [[ "$nomerged" -gt 0 ]] ; then
            # misc (%m)
            hook_com[misc]+="(m${nomerged})"
        fi
    }

    # stash  :SN to misc (%m)
    function +vi-git-stash-count() {
        if [[ "$1" != "1" ]]; then
            return 0
        fi

        local stash
        stash=$(command git stash list 2>/dev/null | wc -l | tr -d ' ')
        if [[ "${stash}" -gt 0 ]]; then
            # misc (%m)
            hook_com[misc]+=":S${stash}"
        fi
    }
fi

function _update_vcs_info_msg() {
    local -a messages
    local prompt

    LANG=en_US.UTF-8 vcs_info

    if [[ -z ${vcs_info_msg_0_} ]]; then
        prompt=""
    else
        # $vcs_info_msg_0_ , $vcs_info_msg_1_ , $vcs_info_msg_2_
        [[ -n "$vcs_info_msg_0_" ]] && messages+=( "%F{075}${vcs_info_msg_0_}%f" )
        [[ -n "$vcs_info_msg_1_" ]] && messages+=( "%F{208}${vcs_info_msg_1_}%f" )
        [[ -n "$vcs_info_msg_2_" ]] && messages+=( "%F{200}${vcs_info_msg_2_}%f" )

        #join separated space
        prompt="${(j: :)messages}"
    fi

    RPROMPT="$prompt"
}

function count_svn_st() {
  svn st | awk '{ c[$1] += 1; } END{for (k in c) {printf "%s:%s ", k, c[k]}}'
}
function +vi-svn-extra-info() {
#  if [[ "$1" != "1" ]]; then
#    return 0
#  fi

  hook_com[unstaged]+=`count_svn_st`
}

add-zsh-hook precmd _update_vcs_info_msg
#====== VCS status to RPROMPT

