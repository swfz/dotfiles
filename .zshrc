# servers
if [ -f $HOME/practice/.alias.server ]; then
    source $HOME/practice/.alias.server
fi

umask 002

export EDITOR=vim
export SVN_EDITOR=vim

# complete
autoload -U compinit
compinit

setopt ZLE

# prompt
PROMPT="%F{cyan}%n%f@%F{cyan}%m%f "
RPROMPT="[%F{magenta}%d%f]"

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

