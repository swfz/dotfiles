umask 002

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo

# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-bin-gem-node

### End of Zinit's installer chunk

# Zsh plugin load
zinit ice wait'!0'; zplugin load zsh-users/zsh-syntax-highlighting
zinit ice wait'!0'; zplugin load zsh-users/zsh-completions
zinit ice wait'!0'; zplugin load agkozak/zhooks

zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# ${fg[color_name]}, ${gb[color_name]}, ${reset_color}を使えるようにする
autoload -Uz colors
colors

# complete
autoload -Uz compinit && compinit
zinit cdreplay - q

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

eval "$(mise activate zsh)"

