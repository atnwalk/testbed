import sys
import csv


def append_saturation_to_last_row(rows, col_data, col_time=0):
    # if this is the first CSV entry, just append a saturation of zero
    if len(rows) <= 2:
        rows[-1].append('0.0000')
        return

    total_data = float(rows[-1][col_data])
    total_time = float(rows[-1][col_time])

    # ignore first entry, which is the CSV header
    # and the last entry, which is not a possible solution
    left = 1
    right = len(rows) - 1

    # binary search for most fitting saturation
    while right - left != 1:
        i = left + ((right - left) >> 1)
        cur_data = float(rows[i][col_data])
        cur_time = float(rows[i][col_time])
        if (cur_data / total_data) <= (1.0 - (cur_time / total_time)):
            left = i
        else:
            right = i

    # time values are more continuous thus use that value for a more accurate/smooth saturation curve
    rows[-1].append(f"{(1.0 - ((float(rows[left][col_time])) / total_time)):.4f}")


def main(argv):
    rows_in = None
    rows_out = []
    sys.stdout.write(f"reading: {argv[1]}\n")
    with open(argv[1], 'r') as src:
        reader = csv.reader(src)
        rows_in = list(reader)

    rows_out.append(rows_in[0][:])
    rows_out[0].append('saturation_traces')
    rows_out[0].append('saturation_edges_max_1x')
    rows_out[0].append('saturation_edges_min_2x')
    rows_out[0].append('saturation_edges_unique')

    processing_fmt_str = (
            "\rprocessing: row{: " + str(len(str(len(rows_in)))) + "d}" + f"/{str(len(rows_in))}"
            + " - time{: 5d}/86400"
    )

    i = 1
    t = 60
    end = 86400
    while t <= end:
        sys.stdout.write(processing_fmt_str.format(i, t))
        sys.stdout.flush()
        if i != len(rows_in) and int(rows_in[i][0]) < t:
            i += 1
            continue
        new_row = rows_in[i-1][:]
        new_row[0] = str(t)
        rows_out.append(new_row)

        append_saturation_to_last_row(rows_out, 1)  # saturation_traces
        append_saturation_to_last_row(rows_out, 3)  # saturation_edges_max_1x
        append_saturation_to_last_row(rows_out, 4)  # saturation_edges_min_2x
        append_saturation_to_last_row(rows_out, 5)  # saturation_edges_unique

        t += 60

    sys.stdout.write(f"\nwriting to: {argv[2]}\n")
    with open(argv[2], 'w') as dest:
        writer = csv.writer(dest)
        writer.writerows(rows_out)


if __name__ == '__main__':
    sys.exit(main(sys.argv))

