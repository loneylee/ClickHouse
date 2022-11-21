#!/bin/bash

if [ $# -ne 8 ];then
        echo "Usage: ./runLocustStarrocks.sh sqls_home private_namenode_ip iteration result_dir private_driver_host locust_home spark_home emr_namenode_user"
        exit 1
fi

sqls_home=$1
private_namenode_ip=$2
iteration=$3
result_dir=$4
private_driver_host=$5
locust_home=$6
spark_home=$7
emr_namenode_user=$8

echo "$(date '+%F %T'): Hive create databases"
${spark_home}/bin/beeline -u jdbc:hive2://${private_namenode_ip}:10000/ -n root -e "create database if not exists tpch100_external;create database if not exists tpch1000_external;"

#python3 ./test.py --iterations 10 --dialect-path ${sqls_home} --output-file ${result_home}/${sv}/$(date '+%Y-%m-%d-%H-%M-%S').csv -p 10000 --engine hive --host ${private_driver_host} --user root --password root
# hive star rocks create table 1
#<< EOF
echo "$(date '+%F %T'): Starrocks external table test(link to hive)"
echo "$(date '+%F %T'): Starrocks create hive table"
python3 ${locust_home}/statistic.py --sql-path ${sqls_home} --dialect hive --engine hive -p 10000 --host ${private_namenode_ip} \
        --output-dir ${result_dir} --user root --database tpch100_external --external-path hdfs://${private_namenode_ip}:8020/tmp/tpch-data-sf100 \
        --create-table-only True --drop-table-before-create True
# starrocks create table 2 and query
echo "$(date '+%F %T'): Starrocks create external table and make query test"
python3 ${locust_home}/statistic.py --iterations ${iteration} --sql-path ${sqls_home} --dialect starrocks --engine starrocks \
        --output-dir ${result_dir} -p 9030 --host ${private_driver_host} --user root --database tpch100_external \
        --external-path hdfs://${private_namenode_ip}:8020/tmp/tpch-data-sf100 \
        --metastore-uris thrift://${private_namenode_ip}:9083 --drop-table-before-create True
#EOF

<< EOF
echo "$(date '+%F %T'): Starrocks inner table test"
echo "$(date '+%F %T'): Starrocks create inner table"
python3 ${locust_home}/statistic.py --sql-path ${sqls_home} --dialect starrocks --engine starrocks -p 9030 --host ${private_driver_host} \
        --output-dir ${result_dir}"_inner" --user root --database tpch100 --create-table-only True --drop-table-before-create True
echo "$(date '+%F %T'): Starrocks load data into inner table"
tpch100_tables=(customer lineitem nation orders part partsupp region supplier)
for table in ${tpch100_tables[@]};do
  label="label"$(echo $RANDOM|md5sum|cut -c 1-8)
  echo "$(date '+%F %T'): load table ${table},label ${label}"
  mysql -h ${private_driver_host} -P9030 -uroot -e "
LOAD LABEL tpch100.${label}
(
    DATA INFILE(\"hdfs://${private_namenode_ip}:8020/tmp/tpch-data-sf100/${table}/*.parquet\")
    INTO TABLE ${table}
    FORMAT AS \"parquet\"
)
WITH BROKER \"broker_gluten\"
(
    \"username\" = \"${emr_namenode_user}\",
    \"password\" = \"\"
)
PROPERTIES
(
    \"timeout\" = \"3600\"
);"

  #wait for load end
  echo "$(date '+%F %T'): loading table ${table},label ${label},waiting for job done"
  while true
  do
    sleep 10
    mysql -h ${private_driver_host} -P9030 -uroot -e "
    use tpch100;
    Show load where label=\"${label}\"\G
    "|grep "State: FINISHED"
    if [ $? -ne 0 ];then
      echo "$(date '+%F %T'): loading table ${table},label ${label} not finished,still waiting"
    else
      echo "$(date '+%F %T'): loading table ${table},label ${label} finished"
      break
    fi
  done
done

echo "$(date '+%F %T'): Starrocks inner table query test"
python3 ${locust_home}/statistic.py --sql-path ${sqls_home} --dialect starrocks --engine starrocks -p 9030 --host ${private_driver_host} \
        --output-dir ${result_dir}"_inner" --user root --database tpch100
EOF
