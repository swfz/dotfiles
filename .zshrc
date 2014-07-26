# servers
if [ -f $HOME/practice/.alias.server ]; then
  source $HOME/practice/.alias.server
fi
umask 002

#env
export EDITOR=vim
export SVN_EDITOR=vim
export LC_CTYPE=ja_JP.utf8

# complete
autoload -U compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

setopt ZLE
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -Uz is-at-least

#color settings
autoload -Uz colors
colors

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

#powerline
source $HOME/.vim/bundle/powerline/powerline/bindings/zsh/powerline.zsh

source $HOME/.zshrc.color
source $HOME/dotfiles/envs_version

for file in $HOME/dotfiles/zsh/*
do
  source $file
done

