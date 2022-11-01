#!/bin/bash


ROOT_PATH=$(cd `dirname -- $0` && pwd -P)


#STARROCKS_INSTALL_HOME=/home/admin123/lishuai/starrocks

DRIVER_HOST=$1
WORKER_HOSTS=$2
echo $WORKER_HOSTS
WORKER_HOSTS_ARR=(${WORKER_HOSTS//,/})

STARROCKS_VERSION=2.3.3

# install fe
ansible-playbook fe-playbook.yml --extra-vars "install_dir=${STARROCKS_INSTALL_HOME} starrock_version=${STARROCKS_VERSION} JAVA_HOME=${JAVA_HOME}"

if [ $? -ne 0 ];then
	echo "$(date '+%F %T'): Starrocks fe install failed! Have a check!"
	exit 120
fi


ansible-playbook be-playbook.yml --skip-tags clean --extra-vars "install_dir=${STARROCKS_INSTALL_HOME} starrock_version=${STARROCKS_VERSION}"

if [ $? -ne 0 ];then
        echo "$(date '+%F %T'): Starrocks be install failed! Have a check!"
        exit 121
fi


for worker in ${WORKER_HOSTS_ARR[@]}
do
	echo "Add starrocks be ${worker}"
	mysql -h ${DRIVER_HOST} -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND \"${worker}:9050\";"
	if [ $? -ne 0 ];then
		echo "$(date '+%F %T'): Starrocks add be ${worker} failed! Have a check!"
		exit 122
	fi
done

sleep 10

alive_cnt=`mysql -h 127.0.0.1 -P9030 -uroot -e "SHOW PROC '/backends'\G"|grep "Alive: true"|wc -l`

if [ ${#WORKER_HOSTS_ARR[*]} -ne $alive_cnt ];then
	echo "$(date '+%F %T'): Starrocks not alive all! Have a check!"
	exit 123
fi

echo "$(date '+%F %T'): Starrocks is installed."

# todo: add create table and load data

