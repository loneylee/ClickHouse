#!/bin/bash

if [ $# -ne 3 ];then
        echo "Usage: ./setupAnsible.sh key_file driver_host worker_hosts"
        exit 1
fi

echo "$(date '+%F %T'): ansible setup begin"

sudo apt-get update


#python >= 2.7
which python3
if [ $? -ne 0 ];then
        echo "$(date '+%F %T'): Python3 not found!Have a check!"
        exit 100
fi

sudo apt-get install -y ansible

DRIVER_HOST=$2
WORKER_HOSTS=$3

OLD_IFS="$IFS"
IFS=","
wHostsArr=(${WORKER_HOSTS})


#setup ansible host config
echo "$(date '+%F %T'): setup ansible host config"
sudo chmod a+w /etc/ansible/hosts
echo -e "[tcluster]\n${DRIVER_HOST}" > /etc/ansible/hosts
for worker in ${wHostsArr[@]}
do	
	echo -e "${worker}" >> /etc/ansible/hosts
done

echo -e "\n[driver]\n${DRIVER_HOST}" >> /etc/ansible/hosts

echo -e "\n[workers]" >> /etc/ansible/hosts
for worker in ${wHostsArr[@]}
do
        echo -e "${worker}" >> /etc/ansible/hosts
done


IFS="${OLD_IFS}"

sudo sed -i 's/#host_key_checking = False/host_key_checking = False/' /etc/ansible/ansible.cfg

#check if ansible works well
key_file=$1
echo "$(date '+%F %T'): check if ansible works well"
ansible --key-file ${key_file} tcluster -m shell -a "ls -hl"

if [ $? -ne 0 ];then
	echo "$(date '+%F %T'): Ansible not setup well!Have a check!"
	exit 101
fi

echo "$(date '+%F %T'): ansible setup end"
