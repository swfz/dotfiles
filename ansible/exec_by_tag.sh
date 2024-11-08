#!/bin/bash

ANSIBLE_CALLBACK_RESULT_FORMAT=yaml CI=true ansible-playbook -i localhost, -c local ubuntu.yml  --tags $1
