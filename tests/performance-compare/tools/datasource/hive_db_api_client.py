import logging
import os

from pyhive import hive

from common import config
from datasource import db_api_client

logger = logging.getLogger()

SQL_DIALECT = "hive"


class HiveDBApiClient(db_api_client.DBApiClient):
    # stmt = {}

    def __init__(self, environment):
        super().__init__(environment)

    def create_connection(self):
        password = None
        if config.CONNECTION_PASSWORD != "":
            password = config.CONNECTION_PASSWORD
        return hive.Connection(database=config.CONNECTION_DATABASE, username=config.CONNECTION_USER, password=password,
                               host=config.CONNECTION_HOST,
                               port=config.CONNECTION_PORT)

    def overwrite_stmt(self):
        return db_api_client.init_stmt(os.path.join(config.DIALECT_ROOT_PATH, SQL_DIALECT))

    def get_stmt(self):
        return self.stmt
