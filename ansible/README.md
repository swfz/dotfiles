# ubuntu(localhost)

```
ansible-playbook -i localhost, -c local ubuntu.yml --extra-vars "user='hoge'" --ask-sudo-pass
```

# centos

```
ansible-playbook -i hosts development.yml
```


