#!/usr/bin/sh

SHELLFILE="~/.bashrc"
DIRECTORY="~/.vim/bundle ~/bin ~/.tmux"

for dir in $DIRECTORY
do
  if [ ! -e $dir ]; then
    mkdir -p $dir
  fi
done

if [ ! -e ~/.vim/bundle/neobundle.vim ]; then
  git clone git://github.com/Shougo/neobundle.vim.git ~/.vim/bundle/neobundle.vim
fi

DOTFILES=".tmux.conf .vimrc"
VIMDIRS="snippets dict"

for file in $DOTFILES
do
  if [ ! -L ~/$file ]; then
    ln -s ~/dotfiles/$file ~/$file
  fi
done

for dir in $VIMDIRS
do
  if [ ! -L ~/.vim/$dir ]; then
    ln -s ~/dotfiles/.vim/$dir ~/.vim/$dir
  fi
done

#tmux powerline

if [ ! -e ~/.tmux/tmux-powerline ]; then
  git clone https://github.com/erikw/tmux-powerline.git ~/.tmux/tmux-powerline
  ln -s ~/dotfiles/tmux/lucius.sh ~/.tmux/tmux-powerline/themes/lucius.sh
  ln -s ~/dotfiles/tmux/.tmux-powerlinerc ~/.tmux-powerlinerc

cat << EOT >> $SHELLFILE
PS1="\$PS1"'\$([ -n "\$TMUX" ] && tmux setenv TMUXPWD_\$(tmux display -p "#D" | tr -d %) "\$PWD")'
export TERM=xterm-256color
EOT
source $SHELLFILE
fi

if [ ! -e ~/bin/used-mem ]; then
  git clone https://github.com/yonchu/used-mem.git ~/bin/used-mem
  ln -s ~/bin/used-mem/used-mem ~/.tmux/tmux-powerline/segments/used-mem.sh
  sed -i -e "s/.*main.*exit_usage.*//g" ~/bin/used-mem/used-mem
  sed -i -e "s/main/run_segment/g" ~/bin/used-mem/used-mem
fi

