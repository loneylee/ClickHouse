import logging

from clickhouse_driver import dbapi

from common import config
from datasource import db_api_client

logger = logging.getLogger()

client = "clickhouse"


class ClickhouseDBApiClient(db_api_client.DBApiClient):
    # stmt = {}

    def __init__(self, environment):
        super().__init__(environment)

    def create_connection(self):
        return dbapi.connect(database=config.CONNECTION_DATABASE, user=config.CONNECTION_USER,
                             password=config.CONNECTION_PASSWORD, host=config.CONNECTION_HOST,
                             port=config.CONNECTION_PORT)
