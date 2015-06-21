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

function install_ctags() {
  cd
  wget http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz
  tar zxf ctags-5.8.tar.gz
  cd ctags-5.8
  mkdir -p $HOME/local
  ./configure  --prefix=$HOME/local
  make
  make install
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

function install_epel(){
  rpmforge=`yum repolist all | grep epel | wc -l`
  if [ $rpmforge -eq 0 ]; then
    echo -e "\e[32m epel install..........\e[m"
    wget http://ftp.riken.jp/Linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -Uvh epel-release-6-8.noarch.rpm
    sed -i "s/enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
  fi
}


function install_libevent2(){
  cd
  curl -LO https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz
  tar zxvf libevent-2.0.21-stable.tar.gz
  cd libevent-2.0.21-stable.tar.gz
  ./configure
  make
  make install
}

function install_tmux(){
  exist_tmux=`exist_command tmux`
  if [ $exist_tmux -ne 1 ]; then
    echo -e "\e[32m tmux install..........\e[m"
    # yum install -y tmux --enablerepo=rpmforge
    install_libevent2
    echo /usr/local/lib >> /etc/ld.so.conf.d/libevent.conf
    ldconfig
    ln -s /usr/local/lib/pkgconfig/libevent.pc /usr/lib64/pkgconfig/libevent.pc

    cd
    curl -LO http://downloads.sourceforge.net/tmux/tmux-1.9a.tar.gz
    tar zxvf tmux-1.9a.tar.gz
    cd tmux-1.9a
    ./configure --sysconfdir=/etc --localstatedir=/var
    make
    make install
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

function install_peco(){
  exist_peco=`exist_command peco`
  if [ $exist_peco -ne 1 ]; then
    echo -e "\e[32m peco install..........\e[m"
    cd
    curl -LO https://github.com/peco/peco/releases/download/v0.3.2/peco_linux_amd64.tar.gz
    tar -xzf peco_linux_amd64.tar.gz
    mv peco_linux_amd64/peco /usr/local/bin/
  fi
}

function install_samba(){
  pkg_install samba
  if [ -e /etc/samba/smb.conf ]; then
    done_setting=`grep 'for local settings' /etc/samba/smb.conf | wc -l`
    if [ $done_setting -lt 1 ]; then
      cat << EOF >> /etc/samba/smb.conf
# for local settings
[global]
    security = share
    create mask = 644
    guest account = root
    disable spooless = yes
[public]
    path = /
    public = yes
    writable = yes
    hide dot files = no
    oplocks = no
EOF
      /etc/init.d/smb start
    fi
  fi
}

function install_parallel(){
  cd
  wget ftp://ftp.gnu.org/gnu/parallel/parallel-20110722.tar.bz2
  tar xvjf parallel-20110722.tar.bz2
  cd parallel-20110722
  ./configure
  make
  make install
}

function install_openssh6(){
  pkgs="rpm-build openssl-devel libedit-devel tcp_wrappers-devel tcp_wrappers pam-devel libX11-devel glibc-devel xmkmf libXt libXt-devel gtk2-devel"
  for pkg in $pkgs
  do
    pkg_install $pkg
  done

  wget http://www.ftp.ne.jp/OpenBSD/OpenSSH/portable/openssh-6.6p1.tar.gz
  tar zxvf openssh-6.6p1.tar.gz

  wget wget http://pkgs.fedoraproject.org/repo/pkgs/openssh/x11-ssh-askpass-1.2.4.1.tar.gz/8f2e41f3f7eaa8543a2440454637f3c3/x11-ssh-askpass-1.2.4.1.tar.gz
  tar zxvf x11-ssh-askpass-1.2.4.1.tar.gz
  cp x11-ssh-askpass-1.2.4.1/* openssh-6.6p1/

  rm -rf openssh-6.6p1/aix/
  rm -rf openssh-6.6p1/cygwin/
  rm -rf openssh-6.6p1/caldera/
  rm -rf openssh-6.6p1/hpux/
  rm -rf openssh-6.6p1/solaris/
  rm -rf openssh-6.6p1/suse/

  rm openssh-6.6p1.tar.gz
  tar czvf openssh-6.6p1.tar.gz openssh-6.6p1/
  rpmbuild -tb --clean openssh-6.6p1.tar.gz
}

pkgs="man ncurses-devel fontconfig bzip2-devel python-devel mlocate expect tcpdump telnet wget curl gzip tar unzip compat-glibc-headers bind-utils bc crontabs"
for pkg in $pkgs
do
  pkg_install $pkg
done

#install_rpmforge
install_epel
install_vim74
install_ag
install_tmux
install_zsh
install_peco
install_samba
install_ctags
install_parallel

