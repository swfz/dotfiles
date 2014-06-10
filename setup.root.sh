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

function install_vim73(){
  exist_vim=`exist_command vim`
  if [ $exist_vim -ne 1 ]; then
    echo -e "\e[32m vim73 install..........\e[m"
    cd
    wget http://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2
    tar jxfv vim-7.3.tar.bz2
    mkdir vim73/patches
    cd vim73/patches/
    seq -f http://ftp.vim.org/pub/vim/patches/7.3/7.3.%03g 3 | xargs wget
    cd ..
    exist_patch=`exist_command patch`
    if [ $exist_patch -ne 1 ]; then
      sudo yum -y install patch
    fi
    cat patches/7.3.* | patch -p0
    ./configure --prefix=/usr --enable-multibyte --with-features=huge --disable-selinux
    make
    make install
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
  if [ $exist_vim -ne 1 ]; then
    echo -e "\e[32m tmux install..........\e[m"
    yum install -y tmux --enablerepo=rpmforge
  fi
}

install_rpmforge
install_vim73
install_ag
install_tmux

