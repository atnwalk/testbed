import math
import statistics
import sys
import argparse
import csv


def get_quartile_percentiles(data):
    sorted_data = list(sorted(map(float, data)))
    # use first value to obtain the 0th- (Q0, minimum) and the last value to obtain the 100th- (Q4, maximum) percentiles
    # use nearest-rank method to obtain 25th- (Q1), 50th- (Q2, median), and 75th- (Q3) percentiles
    return [
        round(sorted_data[0], 4),
        round(sorted_data[math.ceil(float(len(sorted_data)) * 0.25) - 1], 4),
        round(sorted_data[math.ceil(float(len(sorted_data)) * 0.50) - 1], 4),
        round(sorted_data[math.ceil(float(len(sorted_data)) * 0.75) - 1], 4),
        round(sorted_data[-1], 4)
    ]


def get_mean_sd_var(data):
    return [
        round(statistics.mean(map(float, data)), 4),
        round(statistics.stdev(map(float, data)), 4),
        round(statistics.variance(map(float, data)), 4)
    ]


def main(argv):
    parser = argparse.ArgumentParser(prog=argv[0])
    parser.add_argument("csv_file", type=str)
    parser.add_argument("--format-str", type=str, default=None)
    args = parser.parse_args(argv[1:])

    rows_data = None
    with open(args.csv_file, 'r') as f:
        reader = csv.reader(f)
        rows_data = list(reader)
    cols_data = list(map(list, zip(*rows_data)))

    result = [[], []]
    for col in rows_data[0]:
        col_index = rows_data[0].index(col)
        result[0] += [col + appendix for appendix in
                      ["_min", "_q1", "_median", "_q3", "_max", "_mean", "_sd", "_var", "_non_zero", "_sample_size"]]
        data = cols_data[col_index][1:]
        result[1] += (
                get_quartile_percentiles(data)
                + get_mean_sd_var(data)
                + [sum(1 for val in data if float(val) > 0.0)]
                + [len(data)]
        )

    if not args.format_str:
        writer = csv.writer(sys.stdout)
        writer.writerows(result)
    else:
        data_dict = dict()
        for i, key in enumerate(result[0]):
            data_dict[key] = result[1][i]
        sys.stdout.write(args.format_str.encode().decode('unicode_escape').format(**data_dict))
        sys.stdout.flush()


if __name__ == '__main__':
    sys.exit(main(sys.argv))
