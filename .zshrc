# servers
if [ -f $HOME/practice/.alias.server ]; then
  source $HOME/practice/.alias.server
fi
if [ -f ~/practice/.functions ]; then
  . ~/practice/.functions
fi
if [ -f ~/practice/.export ]; then
  . ~/practice/.export
fi


umask 002

#env
export EDITOR=vim
export SVN_EDITOR=vim
export LC_CTYPE=ja_JP.utf8

# complete
autoload -U compinit
compinit

# Upper and Lower Case
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# complete option
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:setopt:*' menu true select

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
setopt extended_history
setopt hist_no_store

# vim-keybind
bindkey -e

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
setopt list_types
setopt magic_equal_subst

#command color
source $HOME/bin/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

#powerline
source $HOME/.vim/bundle/powerline/powerline/bindings/zsh/powerline.zsh

source $HOME/.zshrc.color
source $HOME/dotfiles/envs_version

for file in $HOME/dotfiles/zsh/*
do
  source $file
done

# enhancd
export ENHANCD_FILTER="peco"
if [ -f "/home/sawafuji.yuya/.enhancd/zsh/enhancd.zsh" ]; then
    source "/home/sawafuji.yuya/.enhancd/zsh/enhancd.zsh"
fi

# cheatsheet
export DEFAULT_CHEAT_DIR=~/dotfiles/cheatsheets
export CHEATCOLORS=true
