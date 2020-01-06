#!/bin/bash

git clone https://github.com/vim/vim.git /tmp/vim

cd /tmp/vim

git checkout $1

./configure \
    --enable-fail-if-missing \
    --with-features=huge \
    --disable-selinux \
    --enable-luainterp \
    --enable-perlinterp \
    --enable-pythoninterp \
    --enable-cscope \
    --enable-fontset \
    --enable-multibyte

make
make install

rm -rf /tmp/vim
