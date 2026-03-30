dotfiles

![](https://github.com/swfz/dotfiles/actions/workflows/ci-ansible.yml/badge.svg)


## install

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='$(whoami)'" --ask-become-pass
```

see [ansible](/ansible/README.md) for more information.

## local customization

use custom configuration to `~/.localrc`

## Claude Code skills sync

複数PC間でClaude Codeのskillsをdotfiles経由で共有する仕組み

### setup

```
ln -sf "$(pwd)/hooks/post-merge" .git/hooks/post-merge
```

### usage

```sh
# skillをdotfiles管理に追加（コピー+symlink化）
bin/ccsync.sh add skills/<name>

# dotfiles管理下の全skillsをsymlink作成
bin/ccsync.sh link

# 管理中のskills一覧と状態を表示
bin/ccsync.sh list

# dotfiles管理から外し元の場所に復元
bin/ccsync.sh remove skills/<name>
```

`git pull` 時に `post-merge` hookで `ccsync.sh link` が自動実行される

## environment

| env | available values | description |
|:-|:-|:-|
| KB_TYPE | US | vimキーバインドに影響 |

