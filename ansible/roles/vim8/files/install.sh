#!/bin/bash -e

$(command -v git) clone https://github.com/vim/vim.git /tmp/vim

cd /tmp/vim

$(command -v git) checkout $1

./configure \
  --enable-fail-if-missing \
  --with-features=huge \
  --enable-gpm \
  --disable-selinux \
  --enable-perlinterp \
  --enable-python3interp \
  --enable-cscope \
  --enable-fontset \
  --enable-multibyte

make
make install

rm -rf /tmp/vim
