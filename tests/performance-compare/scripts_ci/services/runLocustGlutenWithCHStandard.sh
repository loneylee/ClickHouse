#!/bin/bash

if [ $# -ne 8 ];then
        echo "Usage: ./runLocustGlutenWithCHStandard.sh sqls_home private_namenode_ip iteration result_dir private_driver_host locust_home spark_home emr_namenode_user"
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
if [ ${inner_table} -ne 1 ];then
  # starrocks create table 2 and query
  echo "$(date '+%F %T'): GlutenWithCHStandard create external table and make query test"
  python3 ${locust_home}/statistic.py --iterations ${iteration} --sql-path ${sqls_home} --dialect gluten --engine gluten --output-dir ${result_dir} \
        -p 10000 --host ${private_driver_host} --user root --database tpch100_external --external-path hdfs://${private_namenode_ip}:8020/tmp/tpch-data-sf100 \
        --data-format parquet --drop-table-before-create True
fi

if [ ${inner_table} -eq 1 ];then
echo "$(date '+%F %T'): GlutenWithCHStandard create inner table"
python3 ${locust_home}/statistic.py --iterations ${iteration} --sql-path ${sqls_home} --dialect gluten --engine gluten --output-dir ${result_dir}"_inner" \
        -p 10000 --host ${private_driver_host} --user root --database tpch100 --external-path ${data_home}/tpch100_ch_data \
        --data-format mergetree --create-table-only True --drop-table-before-create True --column-nullable ${column_nullable}

echo "$(date '+%F %T'): GlutenWithCHStandard copy metadata to all workers"

for table in $(ls -A ${data_home}/tpch100_ch_data)
do
  echo "$(date '+%F %T'): copy metadata of table ${table}"
  ansible --key-file ${key_file} workers  -m copy -a "src=${data_home}/tpch100_ch_data/${table}/_metadata_log dest=${data_home}/tpch100_ch_data/${table}/"
done

echo "$(date '+%F %T'): GlutenWithCHStandard make query test"
python3 ${locust_home}/statistic.py --iterations ${iteration} --sql-path ${sqls_home} --dialect gluten --engine gluten --output-dir ${result_dir}"_inner" \
        -p 10000 --host ${private_driver_host} --user root --database tpch100 --external-path ${data_home}/tpch100_ch_data \
        --data-format mergetree --column-nullable ${column_nullable}

fi
