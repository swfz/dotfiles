dotfiles

# install

```
ansible-playbook -i hosts development.yml
```

## set color

```
ansible-playbook -i hosts development.yml --extra-vars "zsh_color=allblue" --tags color
```

## by role update

```
ansible-playbook -i hosts development.yml --list-tags
ansible-playbook -i hosts development.yml --tags apex,terraform
```

