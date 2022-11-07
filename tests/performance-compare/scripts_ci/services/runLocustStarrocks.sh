#!/bin/bash

if [ $# -ne 1 ];then
        echo "Usage: ./cleanStarrocks.sh key_file"
        exit 1
fi

key_file=$1

#call locust script,tbd
	echo "$(date '+%F %T'): call call locust script"

	python3 ./test.py --iterations 10 --dialect-path ${sqls_home} --output-file ${result_home}/${sv}/$(date '+%Y-%m-%d-%H-%M-%S').csv -p 10000 --engine hive --host ${private_driver_host} --user root --password root
 # hive star rocks create table 1
  python3 ./statistic.py
--iterations
10
--sql-path
/home/admin123/Documents/work/code/Clickhouse-Dev/tests/performance-compare/sqls
--dialect
hive
--engine
hive
-p
10000
--host
52.82.18.132
--user
root
--database
test
--external-path
hdfs:///tmp/tpch-data-sf100
--create-table-only
True

# starrocks create table 2 and query
python3 statistic.py
--iterations
1
--sql-path
/home/admin123/Documents/work/code/Clickhouse-Dev/tests/performance-compare/sqls
--dialect
starrocks
--engine
starrocks
--output-dir
/home/admin123/Documents/work/code/Clickhouse-Dev/tests/performance-compare
-p
9030
--host
ec2-52-82-65-142.cn-northwest-1.compute.amazonaws.com.cn
--user
root
--database
test
--external-path
hdfs:///tmp/tpch-data-sf100
--metastore-uris
thrift://52.82.18.132:9083
