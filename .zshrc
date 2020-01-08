umask 002

### Added by Zplugin's installer
if [[ ! -d $HOME/.zplugin/bin ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing Zplugin…%f"
    command mkdir -p $HOME/.zplugin
    command git clone https://github.com/zdharma/zplugin $HOME/.zplugin/bin && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%F" || \
        print -P "%F{160}▓▒░ The clone has failed.%F"
fi
source "$HOME/.zplugin/bin/zplugin.zsh"
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin installer's chunk

zplugin ice wait'!0'; zplugin load zsh-users/zsh-syntax-highlighting
zplugin ice wait'!0'; zplugin load zsh-users/zsh-completions
zplugin ice wait'!0'; zplugin load sindresorhus/pure

# set environment
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  export IS_WSL=1
fi

export EDITOR=vim
export SVN_EDITOR=vim
export LC_CTYPE=ja_JP.utf8
export LC_ALL=en_US.UTF-8
export LESS="-R -W -i -M"
export LESSCHARSET=utf-8

# complete
autoload -Uz compinit
compinit
zplugin cdreplay - q

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

# powerline
if type powerline > /dev/null 2>&1; then
  python_full_ver=$(pyenv global)
  python_minor_ver=$(pyenv global|grep -oP '\d+\.\d+')
  source $HOME/.anyenv/envs/pyenv/versions/${python_full_ver}/lib/python${python_minor_ver}/site-packages/powerline/bindings/zsh/powerline.zsh
fi

if [ -f $HOME/.zshrc.color ]; then
  source $HOME/.zshrc.color
fi
source $HOME/dotfiles/envs_version

# zshディレクトリ以下の設定ファイルを読み込み
for file in $HOME/dotfiles/zsh/*
do
  source $file
done

# macの場合は追加で設定ファイルを読み込み
case ${OSTYPE} in
  darwin*)
    source $HOME/dotfiles/.darwin.rc
    ;;
esac

# localrc
if [ -f $HOME/.localrc ]; then
  source $HOME/.localrc
fi

# enhancd
export ENHANCD_FILTER="peco"
if [ -f "/home/${USER}/.enhancd/zsh/enhancd.zsh" ]; then
    source "/home/${USER}/.enhancd/zsh/enhancd.zsh"
fi

# cheatsheet
export DEFAULT_CHEAT_DIR=~/dotfiles/cheatsheets
export CHEATCOLORS=true

# GOPATH
export GOPATH=~/go

# export KB_TYPE="US"
