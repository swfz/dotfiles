dotfiles

![](https://github.com/swfz/dotfiles/workflows/ansible/badge.svg)


## install

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='hoge'" --ask-become-pass
```

see [ansible](/ansible/README.md) for more information.

## local customization

use custom configuration to `~/.localrc`

## environment

| env | available values | description |
|:-|:-|:-|
| KB_TYPE | US | vimキーバインドに影響 |

