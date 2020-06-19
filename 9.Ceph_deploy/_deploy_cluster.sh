#!/bin/sh

export ANSIBLE_LOG_PATH
export STUDENT
export SNET

login=$1

if [ -z "$login" ]; then
  HN=$(hostname)
  if [[ $HN =~ master-1\.s([0-9]{6})\.slurm\.io ]]; then
    STUDENT=${BASH_REMATCH[1]}
    SNET=$(ip -4 -br add show eth0 | awk '{print $3}')
    SNET=${SNET%.*}
    login=s$STUDENT
    envsubst < inventory/hosts.tmpl > inventory/hosts
    envsubst < inventory/group_vars/all.yml.tmpl > inventory/group_vars/all.yml
  else
    echo "Usage: $0 adminname"
    exit 1
  fi
fi

d=$(date '+%Y.%m.%d_%H:%M')
ANSIBLE_LOG_PATH=./deploy-$d.log

ansible-playbook -u $login -i inventory/hosts site.yml -b --diff
