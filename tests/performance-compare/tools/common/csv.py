NAME_SPLIT_CHAR = "|"
DATA_SPLIT_CHAR = ","


def write_csv_result(file, stats_entries):
    with open(file, "w") as file:
        for key in stats_entries:
            file.write(key[0] + NAME_SPLIT_CHAR + trans_to_times(stats_entries[key].response_times))
            file.write("\n")


def trans_to_times(dicts):
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
