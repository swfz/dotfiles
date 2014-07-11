#!/usr/bin/sh

PROFILE=".zprofile"
function exist_command() {
  if which "$1" > /dev/null 2>&1 ; then
    echo 1
  else
    echo 2
  fi
}

#anyenv
function install_anyenv() {
  if [ ! -e $HOME/.anyenv ]; then
    echo -e "\e[32m anyenv install..........\e[m"
    git clone https://github.com/riywo/anyenv ~/.anyenv
    echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> $HOME/$PROFILE
    echo 'eval "$(anyenv init -)"' >> $HOME/$PROFILE
  fi
  source $HOME/$PROFILE
}

function install_env() {
  if [ ! -e $HOME/.anyenv/envs/$1 ]; then
    anyenv install $1
    echo 'export PATH="$HOME/.anyenv/envs/$1/shims:$PATH"' >> $HOME/$PROFILE
    source $HOME/$PROFILE
  fi
}

#git config
git config --global user.name swfz
git config --global user.email sawafuji.09@gmail.com
git config --global url."https://".insteadOf git://
git config --global http.sslVerify false
git config --global color.ui true
git config --global core.editor vim

install_anyenv
install_env plenv
install_env rbenv
install_env ndenv
install_env pyenv

pyenv install 3.4.0
pyenv global 3.4.0

SHELLFILE=".zshrc"
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

DOTFILES=".tmux.conf .vimrc .zshrc"
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
  echo -e "\e[32m tmux powerline install..........\e[m"
  git clone https://github.com/erikw/tmux-powerline.git $HOME/.tmux/tmux-powerline
  ln -s $HOME/dotfiles/tmux/lucius.sh $HOME/.tmux/tmux-powerline/themes/lucius.sh
  ln -s $HOME/dotfiles/tmux/.tmux-powerlinerc $HOME/.tmux-powerlinerc
cat << EOT >> $HOME/$PROFILE
export TERM=xterm-256color
EOT
shell=`echo $SHELL`

  case $shell in
    *bash)
cat << EOT >> $HOME/$PROFILE
PS1="\$PS1"'\$([ -n "\$TMUX" ] && tmux setenv TMUXPWD_\$(tmux display -p "#D" | tr -d %) "\$PWD")'
EOT
    ;;
  esac

  source $HOME/$PROFILE
fi

if [ ! -e $HOME/bin/used-mem ]; then
  git clone https://github.com/yonchu/used-mem.git $HOME/bin/used-mem
  ln -s $HOME/bin/used-mem/used-mem $HOME/.tmux/tmux-powerline/segments/used-mem.sh
  sed -i -e "s/.*main.*exit_usage.*//g" $HOME/bin/used-mem/used-mem
  sed -i -e "s/main/run_segment/g" $HOME/bin/used-mem/used-mem
fi

if [[ "$1" =~ "scheme" ]]; then
  mv $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/shell/default.json $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/shell/default_back.json
  ln -s $HOME/dotfiles/powerline_theme/shell_colorscheme_allblue.json $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/shell/default.json
  mv $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/vim/default.json $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/vim/default_back.json
  ln -s $HOME/dotfiles/powerline_theme/vim_colorscheme_allblue.json $HOME/.vim/bundle/powerline/powerline/config_files/colorschemes/vim/default.json
fi

exec $SHELL -l

