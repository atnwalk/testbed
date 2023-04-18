import math
import os.path
import sys
import argparse
import csv
import matplotlib.pyplot as plt


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


def main(argv):
    parser = argparse.ArgumentParser(prog=argv[0])
    parser.add_argument("--column", type=str, default="branches_covered")
    parser.add_argument("--y-max", type=float)
    parser.add_argument("--y-label", type=str)
    parser.add_argument("--out", type=str)
    parser.add_argument("csv_files", type=str, nargs='+')
    args = parser.parse_args(argv[1:])

    rows_all_files = []
    for f in args.csv_files:
        with open(f, 'r') as src:
            reader = csv.reader(src)
            rows_all_files.append(list(reader))

    col_index = rows_all_files[0][0].index(args.column)
    rows_out = [['time'] + [args.column + appendix for appendix in ["_p0", "_p25", "_p50", "_p75", "_p100"]]]
    rows_out.append([0, 0, 0, 0, 0, 0])
    for row_index in range(1, len(rows_all_files[0])):
        relative_time = int(rows_all_files[0][row_index][0])
        data = [int(rows_all_files[file_index][row_index][col_index]) for file_index in range(len(rows_all_files))]
        rows_out.append([relative_time] + get_quartile_percentiles(data))

    data = list(map(list, zip(*rows_out[1:])))

    font_size = 18
    plt.rc('font', size=font_size)
    plt.rc('xtick', labelsize=font_size)
    plt.rc('ytick', labelsize=font_size)

    plt.figure()

    # plot median
    plt.plot(data[0], data[3], linewidth=1.5, color='navy')

    # fill area between min and max values with low alpha
    plt.fill_between(data[0], data[1], data[5], color='royalblue', alpha=0.6, linewidth=0.0)

    # fill area between 1st and 3rd quartiles, i.e. IQR, with high alpha
    plt.fill_between(data[0], data[2], data[4], color='royalblue', alpha=0.8, linewidth=0.0)

    plt.xlabel('Time (hours)')
    if args.y_label:
        plt.ylabel(args.y_label)
    else:
        plt.ylabel(args.column)
    plt.xlim(left=-(86400.0*0.05), right=(86400.0*1.05))
    if args.y_max:
        plt.ylim(bottom=-(args.y_max*0.05), top=args.y_max*1.05)
    else:
        plt.ylim(bottom=-float(data[5][-1])*0.05, top=float(data[5][-1])*1.05)
    plt.xticks(range(0, 86401, 10800), range(0, 25, 3))
    plt.tight_layout()

    plt.gca().yaxis.set_major_formatter(plt.matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))

    if args.out:
        # make sure the directory exists
        # if it doesn't exist create it
        # if it is something else than a directory then show the plot and exit with an error
        out_dir = os.path.dirname(os.path.abspath(args.out))
        if not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)
        elif not os.path.isdir(out_dir):
            plt.show()
            return 1
        plt.savefig(f"{args.out}", dpi=300.0)
        print(f"Saved to: {args.out}")
    else:
        plt.show()

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
