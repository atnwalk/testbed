import os
import re
import sys
import argparse
import subprocess
import shutil
import csv


def update_trace_map(trace_map, txt):
    edge, count = txt.split(':')
    count = int(count)
    if count <= 1:
        bucket = 1
    elif count <= 2:
        bucket = 2
    elif count < 4:
        bucket = 4
    elif count < 8:
        bucket = 8
    elif count < 16:
        bucket = 16
    elif count < 32:
        bucket = 32
    elif count < 64:
        bucket = 64
    else:
        bucket = 128
    if edge not in trace_map:
        trace_map[edge] = bucket
    else:
        trace_map[edge] |= bucket


def count_bits(byte_num):
    count = 0
    for i in range(8):
        if byte_num & (1 << i) > 0:
            count += 1
    return count


def main(argv):
    usage_txt = f"usage: {argv[0]} [-h|--help] [-a|--afl-path AFL_PATH] PATH -- PROGRAM [ARGS ...]\n"
    if len(argv) == 1 or argv[1] == "--help" or argv[1] == "-h":
        print(usage_txt)
        return 1

    # separate the arguments to this script and to the program
    index = -1
    try:
        index = argv.index('--')
    except ValueError:
        sys.stderr.write("missing: -- PROGRAM [ARGS ...]\n")
        sys.stdout.write(usage_txt)
        return 1
    args_script = argv[:index]
    args_prog = argv[index + 1:]

    # parse script arguments
    parser = argparse.ArgumentParser(prog=argv[0])
    parser.add_argument("-a", "--afl-path", dest="afl_path")
    parser.add_argument("-t", "--timeout", dest="timeout")
    parser.add_argument("-o", "--out", dest="out")
    parser.add_argument("path", type=str)
    args = parser.parse_args(args_script[1:])

    # set default value for the AFL PATH
    if args.afl_path is None:
        args.afl_path = os.path.join(os.getenv("HOME"), 'AFLplusplus')

    # set default value for the execution timeout
    if args.timeout is None:
        args.timeout = '100'

    # set default value for the output CSV file
    if args.out is None:
        args.out = 'out.csv'

    tmp_trace_dir = '.tmp_trace'

    # delete '.tmp_trace/'
    sys.stdout.write(f"deleting: {tmp_trace_dir}\n")
    
    # when running in a docker container, it seems to be necessary to flush stdout at least once before
    # output is printed when attached to a container, thus do it here
    sys.stdout.flush()

    shutil.rmtree(tmp_trace_dir, ignore_errors=True)

    # execute afl-showmap to obtain
    proc_args = [
                    os.path.join(args.afl_path, 'afl-showmap'),
                    '-q', '-r',
                    '-t', args.timeout,
                    '-i', args.path,
                    '-o', tmp_trace_dir,
                    '--',
                ] + args_prog
    sys.stdout.write(f"executing: {' '.join(proc_args)}\n")
    proc = subprocess.Popen(proc_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = proc.communicate()

    edges_total = int(
        re.match(
            r'.*\s([1-9][0-9]+)',
            list(filter(lambda x: 'Target map size' in x, stdout.decode('utf-8').splitlines()))[0].split(':')[1]
        ).group(1)
    )
    sys.stdout.write(f"trace map size: {str(edges_total)}\n")

    # get a sorted list of files with their timestamp in seconds in the form of [(timestamp1, 'filename1'), ...]
    files = list(sorted(
        [tuple((int(os.stat(os.path.join(args.path, f)).st_mtime), f))
         for f in os.listdir(args.path)
         if os.path.isfile(os.path.join(args.path, f)) and not f.startswith('.')]
    ))
    sys.stdout.write(f"total number of input files: {str(len(files))}\n")

    results = []

    relative_time = 0
    corpus_count = 0
    trace_map = dict()

    start = files[0][0]

    sys.stdout.write("\n")

    # collect the data over time
    processing_fmt_str = "\robtaining data over time:{: " + str(len(str(len(files)))) + "d}" + f"/{str(len(files))}"
    cur_trace_map = dict()
    global_trace_map = dict()
    bit_count = 0
    i = 0
    for t, f in files:
        # print status
        i += 1
        sys.stdout.write(processing_fmt_str.format(i))
        sys.stdout.flush()

        corpus_count += 1
        relative_time = t - start
        with open(os.path.join(tmp_trace_dir, f), 'r') as trace_file:
            cur_trace_map.clear()
            for line in trace_file.read().splitlines():
                update_trace_map(cur_trace_map, line.strip())

        # calculate bit-coverage
        for k, v in cur_trace_map.items():
            if v == 0:
                continue
            if k not in global_trace_map:
                global_trace_map[k] = v
                bit_count += count_bits(v)
            else:
                bit_count -= count_bits(global_trace_map[k])
                global_trace_map[k] |= v
                bit_count += count_bits(global_trace_map[k])
        bit_cov = f"{float(bit_count) / (float(len(global_trace_map))):.4f}"

        results.append(
            [relative_time, corpus_count, len(global_trace_map), edges_total, bit_cov, "8.0000"]
        )

    sys.stdout.write(f"\nwriting results to: {args.out}\n")
    with open(args.out, 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'time', 'corpus_count', 'edges_covered', 'edges_total', 'bits_covered', 'bits_total', 
        ])
        writer.writerows(results)

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
