import logging
import sys

from common import config
from datasource import clickhouse
from datasource import spark
from datasource import starrocks


def get_client(environment):
    if config.ENGINE == clickhouse.SQL_DIALECT:
        return clickhouse.ClickhouseDBApiClient(environment)
    elif config.ENGINE == spark.SQL_DIALECT:
        return spark.SparkDBApiClient(environment)
    elif config.ENGINE == starrocks.SQL_DIALECT:
        return starrocks.StarrocksDBApiClient(environment)
    else:
        logging.getLogger("Engine").error("dialect {} not support", config.ENGINE)
        sys.exit(10)
