import sys
import csv


def main(argv):
    rows_in = None
    rows_out = []
    sys.stdout.write(f"reading: {argv[1]}\n")
    with open(argv[1], 'r') as src:
        reader = csv.reader(src)
        rows_in = list(reader)

    rows_out.append(rows_in[0][:])

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
        t += 60

    sys.stdout.write(f"\nwriting to: {argv[2]}\n")
    with open(argv[2], 'w') as dest:
        writer = csv.writer(dest)
        writer.writerows(rows_out)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
