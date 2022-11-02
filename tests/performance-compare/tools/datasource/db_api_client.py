import os
import sys
import time
from abc import abstractmethod, ABCMeta

from common import config


def init_stmt(dialect):
    stmts = {}
    root_path = os.path.join(config.DIALECT_ROOT_PATH, dialect)

    if not os.path.exists(root_path):
        return stmts

    for file_name in os.listdir(root_path):
        full_path = os.path.join(root_path, file_name)
        if os.path.isfile(full_path) and file_name.endswith(".sql"):
            with open(full_path, "r") as file:
                stmts[file_name] = file.read()

    return stmts


class DBApiClient(metaclass=ABCMeta):
    def __init__(self, environment):
        self.env = environment
        self.stmt = init_stmt(config.DEFAULT_DIALECT)
        other = init_stmt(self.get_dialect())
        for k in other:
            if self.stmt[k]:
                self.stmt[k] = other[k]
        try:
            self.connection = self.create_connection()
        except Exception as e:
            print(e)
            sys.exit(-1)

    @abstractmethod
    def create_connection(self):
        pass

    def query(self):
        for name in self.stmt:
            self.locust_statistic(name, self.stmt[name])

    def locust_statistic(self, name, stmt):
        request_meta = {
            "request_type": "python",
            "name": name,
            "start_time": time.time(),
            "response_length": 0,
            "exception": None,
            "context": None,
            "response": None,
        }
        start_perf_counter = time.perf_counter()
        try:
            request_meta["response"] = self.execute(stmt)
            request_meta["response_length"] = len(request_meta["response"])
        except Exception as e:
            print(e)
            request_meta["exception"] = e
        request_meta["response_time"] = int((time.perf_counter() - start_perf_counter) * 1000)
        self.env.events.request.fire(**request_meta)
        return request_meta["response"]

    def execute(self, stmt):
        cursor = self.connection.cursor()
        cursor.execute(stmt)
        cursor.close()
        return "success"

    @abstractmethod
    def get_dialect(self):
        pass
