#!/bin/sh

function exist_command() {
  if which "$1" > /dev/null 2>&1 ; then
    echo 1
  else
    echo 0
  fi
}

#ag(silver searcher)
function install_ag() {
  exist_ag=`exist_command ag`
  if [ $exist_ag -ne 1 ]; then
    echo -e "\e[32m ag install..........\e[m"
    sudo yum -y install pcre-devel xz-devel
    sudo rpm -ivh http://swiftsignal.com/packages/centos/6/x86_64/the-silver-searcher-0.13.1-1.el6.x86_64.rpm
  fi
}

function install_vim74(){
  exist_mercurial=`exist_command hg`
  if [ $exist_mercurial -ne 1 ]; then
    yum install -y mercurial
  fi
  exist_vim=`exist_command vim`
  if [ $exist_vim -ne 1 ]; then
    echo -e "\e[32m vim74 install..........\e[m"
    cd
    hg clone https://vim.googlecode.com/hg/ vim
    cd vim/src
    ./configure \
      --with-python-config-dir=/usr/lib64/python2.6/config/ \
      --enable-pythoninterp \
      --prefix=/usr \
      --enable-multibyte \
      --disable-selinux \
      --with-features=huge \
      --disable-gui \
      --enable-fontset \
      --with-x=no \
      --enable-cscope \
      --enable-fail-if-missing
    make
    make install
    cd
  fi
}

function install_rpmforge(){
  rpmforge=`yum repolist all | grep rpmforge | wc -l`
  if [ $rpmforge -eq 0 ]; then
    echo -e "\e[32m rpmforge install..........\e[m"
    wget http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm --import RPM-GPG-KEY.dag.txt
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-1.el6.rf.x86_64.rpm
    rpm -ivh rpmforge-release-0.5.2-1.el6.rf.x86_64.rpm
  fi
}

function install_tmux(){
  exist_tmux=`exist_command tmux`
  if [ $exist_tmux -ne 1 ]; then
    echo -e "\e[32m tmux install..........\e[m"
    yum install -y tmux --enablerepo=rpmforge
  fi
}

function pkg_install(){
  exist_pkg=`rpm -qa | grep $1 | wc -l`
  if [[ "$exist_pkg" -lt 1 ]]; then
    yum install -y $1
  fi
}

function install_zsh(){
  exist_zsh=`exist_command zsh`
  if [ $exist_zsh -ne 1 ]; then
    wget "http://downloads.sourceforge.net/project/zsh/zsh/5.0.5/zsh-5.0.5.tar.gz"
    tar zxvf zsh-5.0.5.tar.gz
    cd zsh-5.0.5
    ./configure --enable-multibyte --enable-locale
    make install
    zsh_path=`which zsh`
    echo "$zsh_path" >> /etc/shells
  fi
}

pkgs="ncurses-devel fontconfig bzip2-devel python-devel mlocate expect tcpdump telnet wget curl gzip tar unzip"
for pkg in $pkgs
do
  pkg_install $pkg
done

install_rpmforge
install_vim74
install_ag
install_tmux
install_zsh


