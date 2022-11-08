#!/bin/bash

if [ $# -ne 7 ];then
        echo "Usage: ./runLocustVanillaSpark.sh sqls_home private_namenode_ip iteration result_dir private_driver_host locust_home spark_home"
        exit 1
fi

sqls_home=$1
private_namenode_ip=$2
iteration=$3
result_dir=$4
private_driver_host=$5
locust_home=$6
spark_home=$7

#call locust script,tbd
echo "$(date '+%F %T'): call call locust script"
# starrocks create table 2 and query
echo "$(date '+%F %T'): VanillaSpark create external table and make query test"
python3 ${locust_home}/statistic.py --iterations ${iteration} --sql-path ${sqls_home} --dialect gluten --engine gluten --output-dir ${result_dir} \
        -p 10000 --host ${private_driver_host} --user root --database tpch100_external --external-path hdfs://${private_namenode_ip}:8020/tmp/tpch-data-sf100 \
        --data-format parquet
