dotfiles

![](https://github.com/swfz/dotfiles/actions/workflows/ci-ansible.yml/badge.svg)


## install

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='$(whoami)'" --ask-become-pass
```

see [ansible](/ansible/README.md) for more information.

## local customization

use custom configuration to `~/.localrc`

## environment

| env | available values | description |
|:-|:-|:-|
| KB_TYPE | US | vimキーバインドに影響 |

