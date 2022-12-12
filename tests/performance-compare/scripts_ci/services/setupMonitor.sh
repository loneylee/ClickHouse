#!/bin/bash


if [ $# -ne 6 ];then
        echo "Usage: ./setupMonitor.sh key_file monitor_home private_driver_host private_worker_hosts private_namenode_ip private_datanode_ip"
        exit 1
fi
#./setupMonitor.sh /home/ubuntu/ckops-awscn.pem ~/glutenTest/monitor

key_file=$1
monitor_home=$2
private_driver_host=$3
private_worker_hosts=$4
private_namenode_ip=$5
private_datanode_ip=$6

echo "$(date '+%F %T'): setup monitor,include node exporter,prometheus,grafana"

#prometheus,grafana depend on docker to start,so need to setup docker first,
#todo: setup docker and then pull down images of prometheus and grafana
#todo: download exporter zip package
#todo: upload playbook yml

cd ${monitor_home}
echo "$(date '+%F %T'): config prometheus.yml"
cp prometheus.yml.template prometheus.yml
#replace ip holders in prometheus.yml:
#{driver} -> spark driver private ip,${private_driver_host}
#{emr-master} -> ${private_namenode_ip}
#{spark-worker} -> ${private_worker_hosts}
#{emr-worker} -> ${private_datanode_ip}
sed -i "s#{driver}#${private_driver_host}#g" prometheus.yml
sed -i "s#{emr-master}#${private_namenode_ip}#g" prometheus.yml

OLD_IFS="$IFS"
IFS=","

sparkWorkerArr=(${private_worker_hosts})
spark_worker_list=""
#"172.31.28.130:9100", "172.31.26.22:9100", "172.31.19.40:9100"
for sparkWorker in ${sparkWorkerArr[@]}
do
	spark_worker_list="\"${sparkWorker}:9100\","
done
spark_worker_list=${spark_worker_list%?}

emrWorkerArr=(${private_datanode_ip})
emr_worker_list=""
#"172.31.30.160:9100","172.31.28.24:9100","172.31.19.94:9100"
for emrWorker in ${emrWorkerArr[@]}
do
	emr_worker_list="\"${emrWorker}:9100\","
done
emr_worker_list=${emr_worker_list%?}

IFS="${OLD_IFS}"

#{spark-worker} -> ${private_worker_hosts}
#{emr-worker} -> ${private_datanode_ip}
sed -i "s#{spark-worker}#${spark_worker_list}#g" prometheus.yml
sed -i "s#{emr-worker}#${emr_worker_list}#g" prometheus.yml

echo "$(date '+%F %T'): config prometheus.yml complete, start monitor deployment"
ansible-playbook --key-file ${key_file} export.yml --extra-vars "install_dir=${monitor_home}"
sudo docker restart prometheus
sudo docker restart grafana

echo "$(date '+%F %T'): monitor is up"
