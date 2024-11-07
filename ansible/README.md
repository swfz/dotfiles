# ubuntu(localhost)

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='$(whoami)'" --ask-become-pass
```

# codespace

```
ansible-playbook -i localhost, -c local codespace.yml --extra-vars "user='$(whoami)'" --ask-become-pass
```

# use tag

```
ansible-playbook -i hosts -c local development.yml --list-tags
ansible-playbook -i hosts -c local development.yml --tags "git"
```

## use docker example

```
sudo docker-compose run --rm centos ansible-playbook -i localhost, -c local ubuntu.yml --tags awscli
```

