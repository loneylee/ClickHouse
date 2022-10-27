#!/bin/bash
#this script contains main process,running on ci vm
#basic environment/services preparation and locust perf test scripts are all called on cloud vms,not on local ci vm for permission casue(need run sudo to config ansible and run apt-get install)
echo "$(date '+%F %T'): begin perf test!"

#start remote cloud vms using ansible plugin,suppose CI VM has secret key to access cloud vms ,tbd
echo "$(date '+%F %T'): start cloud vms!"

#get driver and workers host IP via cloud api,tbd,write constances temporally for test convenience
echo "$(date '+%F %T'): driver and workers host IP via cloud api!"
driver_host='10.198.57.212'
worker_hosts='10.198.55.236'

#on driver, open port 10000 for spark thrift server, 12222 for spark history server,via cloud api or manually,tbd
echo "$(date '+%F %T'): on driver, open port 10000 for spark thrift server, 12222 for spark history server,via cloud api or manually"

#get config from conf file
echo "$(date '+%F %T'): source common variable, file mainProcessOnCI.conf"
main_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${main_script_dir}/mainProcessOnCI.conf 


#put secret pem(key file) to driver host.First remove then upload,or there will be a "Permission denied" error
echo "$(date '+%F %T'): put secret pem(key file) to driver host.First remove then upload"
ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host} "rm ${key_file}"
scp -i ${local_key_file} ${local_key_file} ${cloud_vm_user}@${driver_host}:${key_file}



#get all newly updated scripts into script_home
echo "$(date '+%F %T'): get all newly updated scripts into script_home"
ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host} "rm -rf ${script_home};mkdir -p ${script_home}"
#copy scripts from ci local to remote driver vm
scp -i ${local_key_file} -R ${local_script_home}/* ${cloud_vm_user}@${driver_host}:${script_home}/
if [ $? -ne 0 ];then
	echo "$(date '+%F %T'): shell script upload to driver failed!"
	exit 1
fi
ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host} "chmod u+x ${script_home}/*.sh"

echo "$(date '+%F %T'): get all newly updated locust scripts into locust_home"
ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host} "rm -rf ${locust_home};mkdir -p ${locust_home}"
scp -i ${local_key_file} -r ${local_locust_home}/* ${cloud_vm_user}@${driver_host}:${locust_home}/
if [ $? -ne 0 ];then
        echo "$(date '+%F %T'): locust script upload to driver failed!"
        exit 1
fi

#copy sqls to driver
echo "$(date '+%F %T'): copy sqls to driver"
ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host} "rm -rf ${sqls_home};mkdir -p ${sqls_home}"
scp -i ${local_key_file} -r ${local_sqls_home}/* ${cloud_vm_user}@${driver_host}:${sqls_home}/

#get test data set from s3 bucket on driver and dispatch to all workers,tbd
#no need to download data if exists
echo "$(date '+%F %T'): get test data set from s3 bucket on driver and dispatch to all workers"

#do setup basic env,all ops are on driver host
echo "$(date '+%F %T'): do setup basic env,all ops are on driver host"

#need loop
loop=0
while true
do 
	let loop++

	ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host}  << EOF
	cd ${script_home}

	#check if need to setup ansible and make a config
	bash ./setupAnsible.sh ${key_file} ${driver_host} ${worker_hosts}
	if [ $? -ne 0 ];then
		exit 1
	fi

	#check if need to setup java env
	bash ./setupJava.sh ${key_file}
	if [ $? -ne 0 ];then
        	exit 1
	fi

	#check if need to setup s3client env,tbd

	#check if need to setup locust env
	sudo apt install -y python3-pip
	sudo apt-get install libsasl2-dev
	pip install -r ${locust_home}/requirements.txt

	#pull up conbench service 
EOF


	if [ $? -eq 0 ];then
		echo "$(date '+%F %T'): basic env setup done"
		break
	elif [ $? -ne 0 ] && [ ${loop} -ge 5 ];then
		echo "$(date '+%F %T'): basic env setup wrong"
		exit 1
	fi
done



#service test loop start
echo "$(date '+%F %T'): service test loop start"
for sv in ${service[@]}
do
	echo "$(date '+%F %T'): service to test is ${sv}"
	source ${main_script_dir}/services/var${sv}.conf

	#copy gluten jar and libch.so to driver
	bash ${main_script_dir}/services/uploadPackageFromCI${sv}.sh ${local_key_file} ${cloud_vm_user} ${driver_host}


	ssh -i ${local_key_file} ${cloud_vm_user}@${driver_host}  << EOF
	cd ${script_home}
	source var${sv}.conf
	#check if need to setup spark and start service
	bash ./setup${sv}.sh ${key_file} ${driver_host}
	if [ $? -ne 0 ];then
        	exit 1
	fi


	#call locust script,tbd
	echo "$(date '+%F %T'): call call locust script"
	cd ${locust_home}
	mkdir -p result
	python3 ./test.py --iterations 10 --dialect-path ${sqls_home} --output-file ./result/${sv}_$(date '+%Y-%m-%d-%H-%M-%S').csv -p 10000 --engine hive --host ${driver_host} --user root --password root
	if [ $? -ne 0 ];then
        	exit 1
	fi


	#clean work
	cd ${script_home}
	bash ./clean${sv}.sh ${key_file} 
	if [ $? -ne 0 ];then
        	exit 1
	fi

	#service test loop end
EOF
	echo "$(date '+%F %T'): service ${sv} test is done"
	echo ""
	echo ""

done #service test loop done

#upload all results to conbench,tbd
echo "$(date '+%F %T'): upload result to conbench"

#shutdown cloud vms using ansible plugin,suppose CI VM has secret key to access cloud vms ,tbd
echo "$(date '+%F %T'): shutdown cloud vms!"

echo "$(date '+%F %T'): end perf test!"
