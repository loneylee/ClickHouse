#!/bin/bash

if [ $# -ne 1 ];then
        echo "Usage: ./cleanStarrocks.sh key_file"
        exit 1
fi

key_file=$1

echo "$(date '+%F %T'): Starrocks clean work start!"
ansible --key-file ${key_file} driver -m shell -a "${STARROCKS_INSTALL_HOME}/StarRocks-${STARROCKS_VERSION}/fe/bin/stop_fe.sh --daemon"
ansible --key-file ${key_file} workers -m shell -a "${STARROCKS_INSTALL_HOME}/StarRocks-${STARROCKS_VERSION}/be/bin/stop_be.sh --daemon"
ansible --key-file ${key_file} workers -m shell -a "${STARROCKS_INSTALL_HOME}/StarRocks-${STARROCKS_VERSION}/apache_hdfs_broker/bin/stop_broker.sh --daemon"
echo "$(date '+%F %T'): Starrocks clean work done!"

