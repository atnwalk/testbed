import math
import os.path
import sys
import argparse
import csv
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon


def get_quantiles(data):
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
    parser.add_argument("--format-str", type=str, default="{x:,.0f}")
    parser.add_argument("--y-label", type=str)
    parser.add_argument("--out", type=str)
    parser.add_argument("--column", type=str, required=True)
    parser.add_argument("--data", "-d", type=str, nargs=2, action='append',
                        metavar=("FUZZER", "CSV_FILE"), required=True)
    args = parser.parse_args(argv[1:])

    FUZZER = 0
    CSV_FILE = 1

    boxes = []
    global_min = None
    global_max = None
    check_single_value = set()
    for d in args.data:
        rows = None
        with open(d[CSV_FILE], 'r') as src:
            reader = csv.reader(src)
            rows = list(reader)
        col_index = rows[0].index(args.column)
        col_data = [row[col_index] for row in rows[1:]]
        quantiles = get_quantiles(col_data)
        boxes.append({
            'label': d[FUZZER],
            'whislo': quantiles[0],
            'q1': quantiles[1],
            'med': quantiles[2],
            'q3': quantiles[3],
            'whishi': quantiles[4],
            'fliers': []
        })
        if len(check_single_value) <= 1:
            check_single_value = check_single_value.union(quantiles)
        if not global_min or global_min > quantiles[0]:
            global_min = quantiles[0]
        if not global_max or global_max < quantiles[4]:
            global_max = quantiles[4]

    properties = {
        'showfliers': False,
        'widths': 0.9,
        'boxprops': {'linewidth': 0.0},
        'medianprops': {'linestyle': '-', 'linewidth': 1.5, 'color': 'navy'},
        'whiskerprops': {'linestyle': '--', 'color': 'navy'},
        'capprops': {'linestyle': '-', 'linewidth': 1.25, 'color': 'navy'}
    }

    font_size = 18
    plt.rc('font', size=font_size)
    plt.rc('xtick', labelsize=font_size)
    plt.rc('ytick', labelsize=font_size)

    fig, ax = plt.subplots()
    ax.set_ylim(global_min * 0.80, global_max * 1.12)
    bp = ax.bxp(boxes, **properties)
    # y_limits = ax.get_ylim()
    # ax.set_ylim(y_limits[0], y_limits[1]*1.12)

    # Now fill the boxes with desired colors
    medians = []
    for i in range(len(args.data)):
        box = bp['boxes'][i]
        box_x = []
        box_y = []
        for j in range(5):
            box_x.append(box.get_xdata()[j])
            box_y.append(box.get_ydata()[j])
        box_coords = list(zip(box_x, box_y))
        # Alternate between Dark Khaki and Royal Blue
        ax.add_patch(Polygon(box_coords, facecolor='royalblue', alpha=0.8))
        # Now draw the median lines back over what we just filled in
        med = bp['medians'][i]
        median_x = []
        median_y = []
        for j in range(2):
            median_x.append(med.get_xdata()[j])
            median_y.append(med.get_ydata()[j])
            ax.plot(median_x, median_y, 'k')

        medians.append(median_y[0])

    # Due to the Y-axis scale being different across samples, it can be
    # hard to compare differences in medians across the samples. Add upper
    # X-axis tick labels with the sample medians to aid in comparison
    # (just use two decimal places of precision)
    pos = list(range(1, len(args.data) + 1))
    if args.format_str:
        upper_labels = [args.format_str.format(x=s) for s in medians]
    else:
        upper_labels = medians
    for tick, label in zip(range(len(args.data)), ax.get_xticklabels()):
        ax.text(pos[tick], 0.94, upper_labels[tick],
                transform=ax.get_xaxis_transform(),
                horizontalalignment='center', size='small',
                weight='bold', color='navy')

    if args.format_str:
        plt.gca().yaxis.set_major_formatter(plt.matplotlib.ticker.StrMethodFormatter(args.format_str))

    if args.y_label:
        ax.set_ylabel(args.y_label)
    else:
        ax.set_ylabel(args.column)

    if len(check_single_value) == 1:
        ax.set_ylim(0.0, ax.get_ylim()[1])
        ax.set_yticks([0.0, list(check_single_value)[0]])

    plt.tight_layout()

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
