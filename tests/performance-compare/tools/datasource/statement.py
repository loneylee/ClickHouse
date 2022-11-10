import os
from enum import Enum

from common import config

TABLE_NAMES = ["customer", "lineitem", "nation", "orders", "part", "partsupp", "region", "supplier"]
log = config.log


class ColumnType(Enum):
    BIGINT = 1
    INT = 2
    STRING = 10
    DOUBLE = 20
    DATE = 31


class Column(object):
    def __init__(self, nm, ty, nu=False, d=""):
        self.name = nm
        self.type = ty
        self.nullable = nu
        self.default = d

    def to_sql(self, engine):
        return "{} {} {} {}".format(self.name, engine.trans_column_type(self.type),
                                    engine.trans_column_nullable(self.nullable),
                                    engine.trans_column_default_value(self.default))


class Table(object):
    def __init__(self, nm):
        self.name = nm
        self.columns = []
        self.engine = ""
        self.order_cols = []
        self.comment = ""
        self.shard_cols = []
        self.partition_cols = []
        if config.EXTERNAL_PATH == "":
            self.extrnal_path = ""
        else:
            self.extrnal_path = config.EXTERNAL_PATH + os.sep + self.name

    def to_sql(self, engine):
        sql = []

        extrnal_keyword = "EXTERNAL"
        if self.extrnal_path == "":
            extrnal_keyword = ""
        else:
            sql.append("drop table if exists {}".format(self.name))

        sql.append("""CREATE {extrnal} TABLE IF NOT EXISTS {table_name}
                    (
                    {columns}
                    )
                    {engine}
                    {order_by}
                    {shard_by}
                    {location}
                    {other}""".format(extrnal=extrnal_keyword, table_name=self.name,
                                      columns=self._column_to_sql(engine),
                                      engine=engine.engine_sql(), order_by=engine.order_by_sql(self.order_cols),
                                      shard_by=engine.shard_by_sql(self.shard_cols),
                                      location=engine.location_sql(self.extrnal_path),
                                      other=engine.other_sql(self)))

        log.info("================================================================")
        log.info(sql)
        return sql

    def _column_to_sql(self, engine):
        sql = ""
        for column in self.columns:
            if sql == "":
                sql = column.to_sql(engine)
            else:
                sql += ",\n" + column.to_sql(engine)
        return sql


class Tpch(object):
    def __init__(self):
        self.tables = {}
        for table_name in TABLE_NAMES:
            self.tables[table_name] = self.__class__.__getattribute__(self, table_name)()

    def create_table_sql(self, engine):
        sql = engine.pre_create_table()
        log.info("================================================================")
        log.info("prepare SQL:")
        log.info(sql)

        for table_name in self.tables:
            sql += self.tables[table_name].to_sql(engine)
        return sql

    def customer(self):
        t_customer = Table("customer")
        t_customer.columns.append(Column("c_custkey", ColumnType.BIGINT))
        t_customer.columns.append(Column("c_name", ColumnType.STRING))
        t_customer.columns.append(Column("c_address", ColumnType.STRING))
        t_customer.columns.append(Column("c_nationkey", ColumnType.BIGINT))
        t_customer.columns.append(Column("c_phone", ColumnType.STRING))
        t_customer.columns.append(Column("c_acctbal", ColumnType.DOUBLE))
        t_customer.columns.append(Column("c_mktsegment", ColumnType.STRING))
        t_customer.columns.append(Column("c_comment", ColumnType.STRING))
        # t.engine = "MergeTree"
        #t_customer.order_by
        return t_customer


    def lineitem(self):
        t_lineitem = Table("lineitem")
        t_lineitem.columns.append(Column("l_orderkey", ColumnType.BIGINT))
        t_lineitem.columns.append(Column("l_partkey", ColumnType.BIGINT))
        t_lineitem.columns.append(Column("l_suppkey", ColumnType.BIGINT))
        t_lineitem.columns.append(Column("l_linenumber", ColumnType.BIGINT))
        t_lineitem.columns.append(Column("l_quantity", ColumnType.DOUBLE))
        t_lineitem.columns.append(Column("l_extendedprice", ColumnType.DOUBLE))
        t_lineitem.columns.append(Column("l_discount", ColumnType.DOUBLE))
        t_lineitem.columns.append(Column("l_tax", ColumnType.DOUBLE))
        t_lineitem.columns.append(Column("l_returnflag", ColumnType.STRING))
        t_lineitem.columns.append(Column("l_linestatus", ColumnType.STRING))
        t_lineitem.columns.append(Column("l_shipdate", ColumnType.DATE))
        t_lineitem.columns.append(Column("l_commitdate", ColumnType.DATE))
        t_lineitem.columns.append(Column("l_receiptdate", ColumnType.DATE))
        t_lineitem.columns.append(Column("l_shipinstruct", ColumnType.STRING))
        t_lineitem.columns.append(Column("l_shipmode", ColumnType.STRING))
        t_lineitem.columns.append(Column("l_comment", ColumnType.STRING))
        return t_lineitem

    def nation(self):
        t_nation = Table("nation")
        t_nation.columns.append(Column("n_nationkey", ColumnType.BIGINT))
        t_nation.columns.append(Column("n_name", ColumnType.STRING))
        t_nation.columns.append(Column("n_regionkey", ColumnType.BIGINT))
        t_nation.columns.append(Column("n_comment", ColumnType.STRING))
        return t_nation

    def orders(self):
        t_orders = Table("orders")
        t_orders.columns.append(Column("o_orderkey", ColumnType.BIGINT))
        t_orders.columns.append(Column("o_custkey", ColumnType.BIGINT))
        t_orders.columns.append(Column("o_orderstatus", ColumnType.STRING))
        t_orders.columns.append(Column("o_totalprice", ColumnType.DOUBLE))
        t_orders.columns.append(Column("o_orderdate", ColumnType.DATE))
        t_orders.columns.append(Column("o_orderpriority", ColumnType.STRING))
        t_orders.columns.append(Column("o_clerk", ColumnType.STRING))
        t_orders.columns.append(Column("o_shippriority", ColumnType.BIGINT))
        t_orders.columns.append(Column("o_comment", ColumnType.STRING))
        return t_orders

    def part(self):
        t_part = Table("part")
        t_part.columns.append(Column("p_partkey", ColumnType.BIGINT))
        t_part.columns.append(Column("p_name", ColumnType.STRING))
        t_part.columns.append(Column("p_mfgr", ColumnType.STRING))
        t_part.columns.append(Column("p_brand", ColumnType.STRING))
        t_part.columns.append(Column("p_type", ColumnType.STRING))
        t_part.columns.append(Column("p_size", ColumnType.BIGINT))
        t_part.columns.append(Column("p_container", ColumnType.STRING))
        t_part.columns.append(Column("p_retailprice", ColumnType.DOUBLE))
        t_part.columns.append(Column("p_comment", ColumnType.STRING))
        return t_part

    def partsupp(self):
        t_partsupp = Table("partsupp")
        t_partsupp.columns.append(Column("ps_partkey", ColumnType.BIGINT))
        t_partsupp.columns.append(Column("ps_suppkey", ColumnType.BIGINT))
        t_partsupp.columns.append(Column("ps_availqty", ColumnType.BIGINT))
        t_partsupp.columns.append(Column("ps_supplycost", ColumnType.DOUBLE))
        t_partsupp.columns.append(Column("ps_comment", ColumnType.STRING))
        return t_partsupp

    def region(self):
        t_region = Table("region")
        t_region.columns.append(Column("r_regionkey", ColumnType.BIGINT))
        t_region.columns.append(Column("r_name", ColumnType.STRING))
        t_region.columns.append(Column("r_comment", ColumnType.STRING))
        return t_region

    def supplier(self):
        t_supplier = Table("supplier")
        t_supplier.columns.append(Column("s_suppkey", ColumnType.BIGINT))
        t_supplier.columns.append(Column("s_name", ColumnType.STRING))
        t_supplier.columns.append(Column("s_address", ColumnType.STRING))
        t_supplier.columns.append(Column("s_nationkey", ColumnType.BIGINT))
        t_supplier.columns.append(Column("s_phone", ColumnType.STRING))
        t_supplier.columns.append(Column("s_acctbal", ColumnType.DOUBLE))
        t_supplier.columns.append(Column("s_comment", ColumnType.STRING))
        return t_supplier

    # t_region.columns.append(Column("",ColumnType.) )
    # customer.columns.append(Column("",ColumnType.) )
    # customer.columns.append(Column("",ColumnType.) )
