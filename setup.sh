#!/usr/bin/sh

mkdir -p ~/.vim/bundle
git clone git://github.com/Shougo/neobundle.vim.git ~/.vim/bundle/neobundle.vim

DOTFILES=".tmux.conf .vimrc"
VIMDIRS="snippets dict"

for file in $DOTFILES
do
  ln -s $HOME/dotfiles/$file $HOME/$file
done

for file in $VIMDIRS
do
  ln -s $HOME/dotfiles/.vim/$file $HOME/.vim/$file
done

