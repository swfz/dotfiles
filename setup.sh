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

function set_env(){
  exist_version=`$1 versions | grep $2 | wc -l`
  if [[ "$exist_version" -lt 1 ]]; then
    $1 install $2
    $1 global $2
  fi
}

#git config
function git_config(){
  exist_config=`git config  --get core.editor`
  if [ "$exist_config" != "vim" ]; then
    git config --global user.name swfz
    git config --global user.email sawafuji.09@gmail.com
    git config --global url."https://".insteadOf git://
    git config --global http.sslVerify false
    git config --global color.ui true
    git config --global core.editor vim
  fi
}

function link_dotfiles(){
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

  if [ ! -L $HOME/.config/peco/config.json ]; then
    mkdir -p $HOME/.config/peco
    ln -s $HOME/dotfiles/config/peco/config.json $HOME/.config/peco/config.json
  fi
}

path2dotfiles_bin(){
  echo 'export PATH="$HOME/dotfiles/bin:$PATH"' >> $HOME/$PROFILE
}

#tmux powerline
install_tmux_powerline(){
  if [ ! -e $HOME/.tmux/tmux-powerline ]; then
    echo -e "\e[32m tmux powerline install..........\e[m"
    git clone https://github.com/erikw/tmux-powerline.git $HOME/.tmux/tmux-powerline
    ln -s $HOME/dotfiles/tmux/lucius.sh $HOME/.tmux/tmux-powerline/themes/lucius.sh
    ln -s $HOME/dotfiles/tmux/blue.sh $HOME/.tmux/tmux-powerline/themes/blue.sh
    ln -s $HOME/dotfiles/tmux/green.sh $HOME/.tmux/tmux-powerline/themes/green.sh
    ln -s $HOME/dotfiles/tmux/.tmux-powerlinerc $HOME/.tmux-powerlinerc
cat << EOT >> $HOME/$PROFILE
export TERM=xterm-256color
export POWERLINE_COMMAND=$HOME/.vim/bundle/powerline/scripts/powerline-render
EOT
shell=`echo $SHELL`

#    case $shell in
#      *bash)
#cat << EOT >> $HOME/$PROFILE
#PS1="\$PS1"'\$([ -n "\$TMUX" ] && tmux setenv TMUXPWD_\$(tmux display -p "#D" | tr -d %) "\$PWD")'
#EOT
#      ;;
#    esac

    source $HOME/$PROFILE
  fi

  if [ ! -e $HOME/bin/used-mem ]; then
    git clone https://github.com/yonchu/used-mem.git $HOME/bin/used-mem
    ln -s $HOME/bin/used-mem/used-mem $HOME/.tmux/tmux-powerline/segments/used-mem.sh
    sed -i -e "s/.*main.*exit_usage.*//g" $HOME/bin/used-mem/used-mem
    sed -i -e "s/main/run_segment/g" $HOME/bin/used-mem/used-mem
  fi
}

zsh_command_color(){
  if [ ! -e $HOME/bin/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/bin/zsh-syntax-highlighting
  fi
}

install_enhancd(){
  if [ ! -e $HOME/.enhancd ]; then
    curl -L git.io/enhancd | sh
  fi
}

install_cleaver(){
  exist_cleaver=`exist_command cleaver`
  if [ $exist_cleaver -ne 1 ]; then
    chmod +x $HOME
    ndenv install v5.0.0
    ndenv global v5.0.0
    npm install -g cleaver
  fi
}

# nginx.conf
    # server{
    #     location /cleaver {
    #         root $HOME;
    #     }
    # }

git_config
link_dotfiles
path2dotfiles_bin
zsh_command_color
install_enhancd
install_cleaver

install_anyenv
envs="plenv rbenv ndenv pyenv"
for env in $envs
do
  install_env $env
done
set_env pyenv 3.4.0

install_tmux_powerline

function replace_link(){
  if [ -L $1 ]; then
    rm $1
  else
    if [ -e $1 ]; then
      mv $1 "$1".orig
    fi
  fi
  ln -s $2 $1
}

# set colorscheme
function set_scheme(){
  powerline_config="$HOME/.vim/bundle/powerline/powerline/config_files"
  powerline_colorschemes="$powerline_config/colorschemes"

  replace_link "$powerline_config"/colors.json $HOME/dotfiles/powerline_theme/colors.json

  if [ "$2" = "list" ]; then
    if [ "$1" = "shell" -o "$1" = "vim" ]; then
      ls -l $HOME/dotfiles/powerline_theme/"$1"_colorscheme_*.json | awk -F" " '{print $9}' | awk -F"/" '{print $NF}' | awk -F"[_.]" '{print $(NF - 1)}'
    fi
    if [ "$1" = "tmux" ]; then
      ls -l $HOME/dotfiles/tmux/ | awk -F " " '{print $9}' | awk -F"/" '{print $NF}' | awk -F"." '{print $1}'
    fi
    exit
  fi

  if [ "$1" = "shell" -o "$1" = "vim" ]; then
    replace_link $powerline_colorschemes/$1/default.json $HOME/dotfiles/powerline_theme/"$1"_colorscheme_"$2".json
    replace_link $HOME/.zshrc.color $HOME/dotfiles/zsh/.color."$2"
  fi
  if [ "$1" = "tmux" ]; then
    replace_link $HOME/."$1"/.tmux.color.conf $HOME/dotfiles/tmux/.tmux."$2".conf
    replace_link $HOME/.tmux-powerlinerc $HOME/dotfiles/tmux/.tmux-"$2"-powerlinerc
  fi
}

if [[ "$#" -gt 1 ]]; then
  set_scheme $1 $2
fi


