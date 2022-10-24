from common import config
from datasource import clickhouse_db_api_client
from datasource import hive_db_api_client


def get_client(environment):
    if config.ENGINE == clickhouse_db_api_client.SQL_DIALECT:
        return clickhouse_db_api_client.ClickhouseDBApiClient(environment)
    elif config.ENGINE == hive_db_api_client.SQL_DIALECT:
        return hive_db_api_client.HiveDBApiClient(environment)
    else:
        return clickhouse_db_api_client.ClickhouseDBApiClient(environment)
