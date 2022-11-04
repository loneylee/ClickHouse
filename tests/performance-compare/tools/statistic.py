import argparse
import os
import sys

from common import config
from core import locust_test

parser = argparse.ArgumentParser(description='command line arguments')
parser.add_argument('--iterations', '-i', type=int,
                    help='Iteration limit , stops Locust after a certain number of task iterations', required=False,
                    default=7)
parser.add_argument('--output-dir', '-o', type=str, help='', required=True)
parser.add_argument('--client', "-c", type=str, help='used connection client, eg. mysql, clickhouse, hive',
                    required=True)
parser.add_argument('--sql-path', type=str, help='sql full path which search sql dialect. eg. /temp', required=True)
parser.add_argument('--dialect', type=str,
                    help='dialect. Will find sql in {sql-path}/{dialect}/. Support starrocks, clickhouse, ansi',
                    default="ansi")
parser.add_argument('--host', type=str, help='host', required=False,
                    default=os.getenv("TEST_CONNECTION_HOST", "localhost"))
parser.add_argument('--port', '-p', type=int, help='port', required=False,
                    default=os.getenv("TEST_CONNECTION_PORT", 80))
parser.add_argument('--user', '-u', type=str, help='user', required=False,
                    default=os.getenv("TEST_CONNECTION_USER", "default"))
parser.add_argument('--password', type=str, help='password', required=False,
                    default=os.getenv("TEST_CONNECTION_PASSWORD", ""))
parser.add_argument('--database', "-d", type=str, help='database', required=False,
                    default=os.getenv("TEST_CONNECTION_DATABASE", "default"))

if __name__ == "__main__":
    args = vars(parser.parse_args())
    sys.argv = [sys.argv[0]]
    config.ITERATIONS = args["iterations"]
    config.OUTPUT_FILE = args["output_dir"]
    config.SQL_PATH = args["sql_path"]
    config.CONNECTION_HOST = args["host"]
    config.CONNECTION_PORT = args["port"]
    config.CONNECTION_USER = args["user"]
    config.CONNECTION_PASSWORD = args["password"]
    config.CONNECTION_DATABASE = args["database"]
    config.CLIENT = args["client"]
    config.DIALECT = args["dialect"]
    locust_test.run()
