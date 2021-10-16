#!/bin/bash


# ubuntu for codecpaces
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python get-pip.py
pip install pexpect --user

# codespace .zshrc is exist(oh-my-zsh).
# I want to use my own file. saving existing .zshrc
mv ~/.zshrc ~/.zshrc.bak

cd ansible
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars="user=$(whoami)"
