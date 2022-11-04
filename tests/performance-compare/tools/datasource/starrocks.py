import logging

from common import config
from datasource import mysql

logger = logging.getLogger()

ENGINE = "starrocks"


class StarrocksDBApiClient(mysql.MysqlDBApiClient):
    resource_name = "gluten_test"

    def other_sql(self, table):
        return """
         properties (
            "resource" = "{}",
            "table" = "{}",
            "database" = "{}"
        )
        """.format(self.resource_name, table.name, config.CONNECTION_DATABASE)

    def random_column(self):
        return " random_key int default uuid(), "

    def engine_sql(self):
        if config.EXTERNAL_PATH != "":
            return "ENGINE=hive"
        return " ENGINE=OLAP "

    def pre_create_table(self):
        if config.EXTERNAL_PATH == "":
            return ""
        return """
            DROP RESOURCE {resource_name};
            CREATE EXTERNAL RESOURCE "{resource_name}" PROPERTIES (
              "type" = "hive",
              "hive.metastore.uris" = "{metastore_uris}"
            );
        """.format(resource_name=self.resource_name, metastore_uris=config.METASTORE_URIS)
