from datasource import hive

ENGINE = "gluten"


class GlutenDBApiClient(hive.HiveDBApiClient):
    def engine_sql(self):
        return """
            USING clickhouse
            TBLPROPERTIES (engine='MergeTree')
        """

    def location_sql(self, location_uri):
        return " LOCATION '{}'".format(location_uri)
