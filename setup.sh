#!/usr/bin/sh

#git config
git config --global url."https://".insteadOf git://
git config --global http.sslVerify false
git config --global color.ui true
git config --global core.editor vim

#plenv
if [ ! -e $HOME/.plenv ]; then
  git clone git://github.com/tokuhirom/plenv.git ~/.plenv
  echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(plenv init -)"' >> ~/.bash_profile
  exec $SHELL -l
  git clone git://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
fi

SHELLFILE=".bashrc"
DIRECTORY=".vim/bundle bin .tmux"

for dir in $DIRECTORY
do
  if [ ! -e $HOME/$dir ]; then
    mkdir -p $HOME/$dir
  fi
done

if [ ! -e $HOME/.vim/bundle/neobundle.vim ]; then
  git clone git://github.com/Shougo/neobundle.vim.git $HOME/.vim/bundle/neobundle.vim
fi

DOTFILES=".tmux.conf .vimrc"
VIMDIRS="snippets dict"

for file in $DOTFILES
do
  if [ ! -L $HOME/$file ]; then
    ln -s $HOME/dotfiles/$file $HOME/$file
  fi
done

for dir in $VIMDIRS
do
  if [ ! -L $HOME/.vim/$dir ]; then
    ln -s $HOME/dotfiles/.vim/$dir $HOME/.vim/$dir
  fi
done

#tmux powerline

if [ ! -e $HOME/.tmux/tmux-powerline ]; then
  git clone https://github.com/erikw/tmux-powerline.git $HOME/.tmux/tmux-powerline
  ln -s $HOME/dotfiles/tmux/lucius.sh $HOME/.tmux/tmux-powerline/themes/lucius.sh
  ln -s $HOME/dotfiles/tmux/.tmux-powerlinerc $HOME/.tmux-powerlinerc
cat << EOT >> $HOME/$SHELLFILE
PS1="\$PS1"'\$([ -n "\$TMUX" ] && tmux setenv TMUXPWD_\$(tmux display -p "#D" | tr -d %) "\$PWD")'
export TERM=xterm-256color
EOT
source $HOME/$SHELLFILE
fi

if [ ! -e $HOME/bin/used-mem ]; then
  git clone https://github.com/yonchu/used-mem.git $HOME/bin/used-mem
  ln -s $HOME/bin/used-mem/used-mem $HOME/.tmux/tmux-powerline/segments/used-mem.sh
  sed -i -e "s/.*main.*exit_usage.*//g" $HOME/bin/used-mem/used-mem
  sed -i -e "s/main/run_segment/g" $HOME/bin/used-mem/used-mem
fi

