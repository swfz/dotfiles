#!/bin/bash
# for codecpaces

sudo apt -y update
sudo apt install -y python-pip python-setuptools
sudo apt install -y ansible
# TODO codespace用のインスタンスにansibleのロール(by_pip)を適用させたかったがcryptography内部で使っているようでrust compilierが必要らしい
# そこまでしなくて良いという判断で、一旦cheatだけインストールする処理を入れる
pytnon3 -m pip install cheat

# codespace .zshrc is exist(oh-my-zsh).
# I want to use my own file. saving existing .zshrc
mv ~/.zshrc ~/.zshrc.bak

cd ansible
ansible-playbook -i localhost, -c local codespace.yml --extra-vars="user=$(whoami)"
