#!/bin/bash


if [ $# -ne 2 ];then
        echo "Usage: ./setupGlutenWithCHStandard.sh key_file spark_master_ip"
        exit 1
fi
#./setupGlutenWithCHStandard.sh /home/ubuntu/ckops-awscn.pem localhost

echo "$(date '+%F %T'): setup GlutenWithCHStandard service"

key_file=$1
spark_master_ip=$2

#spark version is a variable
ansible --key-file ${key_file} tcluster -m shell -a "mkdir -p ${spark_base}"

#setup spark node
echo "$(date '+%F %T'): setup spark node environment"
if [ ! -d "${spark_home}" ];then 
	echo "$(date '+%F %T'): Spark not found,start downloading" 
	cd ${spark_base}
	wget ${spark_bin_url}
	#dispatch to all nodes
	ansible --key-file ${key_file} workers -m copy -a "src=spark-3.2.2-bin-hadoop2.7.tgz dest=${spark_base}"
	ansible --key-file ${key_file} tcluster -m shell -a "cd ${spark_base};tar -xzvf spark-3.2.2-bin-hadoop2.7.tgz"
	ansible --key-file ${key_file} tcluster -m shell -a "cd ${spark_home}/jars;rm -f protobuf-java-2.5.0.jar gluten*.jar;wget https://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/3.13.0/protobuf-java-3.13.0.jar;wget https://repo1.maven.org/maven2/io/delta/delta-core_2.12/1.2.1/delta-core_2.12-1.2.1.jar;wget https://repo1.maven.org/maven2/io/delta/delta-storage/1.2.1/delta-storage-1.2.1.jar"
	ansible --key-file ${key_file} tcluster -m copy -a "src=${gluten_standard_jar} dest=${spark_home}/jars/"
	ansible --key-file ${key_file} workers  -m copy -a "src=${libch_standard_so} dest=${libch_standard_so}"
	
fi

#start master
echo "$(date '+%F %T'): start master"
cd ${spark_home}
./sbin/start-master.sh -h ${spark_master_ip}

#start workers
echo "$(date '+%F %T'): start workers"
ansible --key-file ${key_file} workers -m shell -a "cd ${spark_home};./sbin/start-worker.sh spark://${spark_master_ip}:7077"

spark_event_logs="${spark_home}/spark_event_logs"
ansible --key-file ${key_file} tcluster -m shell -a "mkdir -p ${spark_event_logs}"
echo "$(date '+%F %T'): start thrift server"
#start thrift server
./sbin/start-thriftserver.sh \
  --master spark://${spark_master_ip}:7077 --deploy-mode client \
  --driver-memory 30g --driver-cores 6 \
  --total-executor-cores 30 --executor-memory 30g --executor-cores 15 \
  --conf spark.driver.memoryOverhead=8G \
  --conf spark.serializer=org.apache.spark.serializer.JavaSerializer \
  --conf spark.default.parallelism=120 \
  --conf spark.sql.shuffle.partitions=120 \
  --conf spark.sql.files.minPartitionNum=1 \
  --conf spark.sql.files.maxPartitionBytes=671088640 \
  --conf spark.sql.files.openCostInBytes=671088640 \
  --conf spark.sql.adaptive.enabled=false \
  --conf spark.sql.parquet.filterPushdown=true \
  --conf spark.sql.parquet.enableVectorizedReader=true \
  --conf spark.locality.wait=0 \
  --conf spark.locality.wait.node=0 \
  --conf spark.locality.wait.process=0 \
  --conf spark.sql.columnVector.offheap.enabled=true \
  --conf spark.memory.offHeap.enabled=true \
  --conf spark.memory.offHeap.size=21474836480 \
  --conf spark.plugins=io.glutenproject.GlutenPlugin \
  --conf spark.gluten.sql.columnar.columnartorow=true \
  --conf spark.gluten.sql.columnar.loadnative=true \
  --conf spark.gluten.sql.columnar.libpath=${libch_standard_so} \
  --conf spark.gluten.sql.columnar.iterator=true \
  --conf spark.gluten.sql.columnar.loadarrow=false \
  --conf spark.gluten.sql.columnar.backend.lib=ch \
  --conf spark.gluten.sql.columnar.hashagg.enablefinal=true \
  --conf spark.gluten.sql.enable.native.validation=false \
  --conf spark.io.compression.codec=snappy \
  --conf spark.gluten.sql.columnar.backend.ch.use.v2=false \
  --conf spark.sql.exchange.reuse=true \
  --conf spark.sql.autoBroadcastJoinThreshold=10MB \
  --conf spark.gluten.sql.columnar.forceshuffledhashjoin=true \
  --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.execution.datasources.v2.clickhouse.ClickHouseSparkCatalog \
  --conf spark.databricks.delta.maxSnapshotLineageLength=20 \
  --conf spark.databricks.delta.snapshotPartitions=1 \
  --conf spark.databricks.delta.properties.defaults.checkpointInterval=5 \
  --conf spark.databricks.delta.stalenessLimit=3600000 \
  --conf spark.gluten.sql.columnar.backend.ch.worker.id=1 \
  --conf spark.gluten.sql.columnar.coalesce.batches=true \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=file://${spark_event_logs} \
  --conf spark.eventLog.compress=true \
  --conf spark.eventLog.compression.codec=snappy
#  --files ${spark_home}/conf/log4j_thrift.properties


#start spark history server
export SPARK_HISTORY_OPTS=" -Dspark.history.ui.port=12222 -Dspark.history.fs.logDirectory=file://${spark_event_logs} -Dspark.history.retainedApplications=200 -Dspark.history.fs.update.interval=30s"
echo "$(date '+%F %T'): start history server"
./sbin/start-history-server.sh

#use beeline do a connection test
echo "$(date '+%F %T'): do a connect test"
sleep 5
./bin/beeline -u jdbc:hive2://${spark_master_ip}:10000/ -n root -e "select 1;"
if [ $? -ne 0 ];then
	sleep 5
	./bin/beeline -u jdbc:hive2://${spark_master_ip}:10000/ -n root -e "select 1;"
	if [ $? -ne 0 ];then
		echo "$(date '+%F %T'): Spark not launched!Have a check!"
		exit 102
	fi
fi


echo "$(date '+%F %T'): GlutenWithCHStandard service is on" 
