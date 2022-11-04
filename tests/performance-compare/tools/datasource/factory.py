import logging
import sys

from common import config
from datasource import clickhouse
from datasource import hive
from datasource import mysql


def get_client(environment):
    client = str.lower(config.CLIENT)
    if client == str.lower(clickhouse.client):
        return clickhouse.ClickhouseDBApiClient(environment)
    elif client == str.lower(hive.client):
        return hive.HiveDBApiClient(environment)
    elif client == str.lower(mysql.client):
        return mysql.MysqlDBApiClient(environment)
    else:
        logging.getLogger("Engine").error("Engine {} not support", client)
        sys.exit(10)
