# ubuntu(localhost)

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='hoge'" --ask-sudo-pass
```

# centos

```
ansible-playbook -i hosts development.yml
```

# use tag

```
ansible-playbook -i hosts -c local development.yml --tags "git"
```

## use docker example

```
sudo docker-compose run --rm centos ansible-playbook -i localhost, -c local centos.yml --tags awscli
```

