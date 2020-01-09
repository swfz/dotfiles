umask 002

# powerline
function load_powerline() {
  if type powerline > /dev/null 2>&1; then
    python_full_ver=$(pyenv global)
    python_minor_ver=$(pyenv global|grep -oP '\d+\.\d+')
    source $HOME/.anyenv/envs/pyenv/versions/${python_full_ver}/lib/python${python_minor_ver}/site-packages/powerline/bindings/zsh/powerline.zsh
  fi
}

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

# Zsh plugin load
zplugin ice wait'!0'; zplugin load zsh-users/zsh-syntax-highlighting
zplugin ice wait'!0'; zplugin load zsh-users/zsh-completions

if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  zplugin ice wait'!0'; zplugin load sindresorhus/pure
else
  load_powerline
fi

# ${fg[color_name]}, ${gb[color_name]}, ${reset_color}を使えるようにする
autoload -Uz colors
colors

# complete
autoload -Uz compinit
compinit
zplugin cdreplay - q

# 補完
## Upper and Lower Case
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## complete option
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:setopt:*' menu true select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Zsh Line Editor
setopt ZLE
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
# version依存な設定を書くための機能
autoload -Uz is-at-least

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# vim-keybind
bindkey -e

# history search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# options
setopt auto_cd # `cd` 不要
setopt auto_pushd # cd の履歴から補完してくれる. list by cd -[tab]
setopt correct # typo時に確認が入る
setopt list_packed # 補完候補を詰めて表示
setopt nobeep # 補完候補がない場合などでビープ音を鳴らさない
setopt magic_equal_subst # コマンドライン引数の--prefix=/usr で =移行でも補完
setopt transient_rprompt # コマンド実行後は右promptを消す
setopt hist_ignore_dups # 直前と同じコマンドラインはhistoryに追加しない
setopt hist_ignore_all_dups # 重複したhistoryは追加しない
setopt share_history # shell process間で履歴を共有
setopt extended_history # 履歴ファイルに時刻を記録
setopt hist_no_store
setopt list_types

# zshディレクトリ以下の設定ファイルを読み込み
for file in $HOME/dotfiles/zsh/*
do
  source $file
done

# カラーテーマ読み込み
if [ -f $HOME/.zshrc.color ]; then
  source $HOME/.zshrc.color
fi

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
