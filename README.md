dotfiles

![](https://github.com/swfz/dotfiles/workflows/ansible/badge.svg)

# install(centos)

```
ansible-playbook -i hosts centos.yml
```

## set color

```
ansible-playbook -i hosts centos.yml --extra-vars "zsh_color=allblue" --tags color
```

## by role update

```
ansible-playbook -i hosts centos.yml --list-tags
ansible-playbook -i hosts centos.yml --tags apex,terraform
```

## ubuntu(wsl)

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars="user=hoge" --extra-vars="execute='/usr/bin/zsh -lc'"
```

`execute` is shell executer


