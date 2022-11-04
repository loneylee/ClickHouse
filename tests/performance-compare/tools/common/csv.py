NAME_SPLIT_CHAR = "|"
DATA_SPLIT_CHAR = ","


def write_csv_detail_result(file, stats_entries):
    with open(file, "w") as file:
        for key in stats_entries:
            file.write(key[0] + NAME_SPLIT_CHAR + locust_group_to_times(stats_entries[key].response_times))
            file.write("\n")


def locust_group_to_times(dicts):
    result = ""
    for elapsed in dicts:
        if result == "":
            result = append_times(dicts[elapsed], elapsed)
        else:
            result += DATA_SPLIT_CHAR + append_times(dicts[elapsed], elapsed)

    return result


def append_times(times, elapsed):
    r = ""
    for i in range(times):
        if i == 0:
            r = str(elapsed)
        else:
            r += DATA_SPLIT_CHAR + str(elapsed)
    return r


def read_csv_result(file):
    dicts = {}
    with open(file, "r") as file:
        lines = file.read().splitlines()

    for line in lines:
        if line != "":
            data = line.split(NAME_SPLIT_CHAR)
            dicts[data[0]] = [int(x) for x in data[1].split(DATA_SPLIT_CHAR)]

    return dicts
