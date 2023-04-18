import os
import re
import sys
import argparse
import subprocess
import shutil
import csv


def update_trace_map(trace_map, txt, detailed=False):
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
    if detailed:
        trace_map[edge] = {'n': bucket, 'c': set([count])}
    else:
        trace_map[edge] = bucket


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

    edges_max_possible = int(
        re.match(
            r'.*\s([1-9][0-9]+)',
            list(filter(lambda x: 'Target map size' in x, stdout.decode('utf-8').splitlines()))[0].split(':')[1]
        ).group(1)
    )
    sys.stdout.write(f"trace map size: {str(edges_max_possible)}\n")

    # get a sorted list of files with their timestamp in seconds in the form of [(timestamp1, 'filename1'), ...]
    files = list(sorted(
        [tuple((int(os.stat(os.path.join(args.path, f)).st_mtime), f))
         for f in os.listdir(args.path)
         if os.path.isfile(os.path.join(args.path, f)) and not f.startswith('.')]
    ))
    sys.stdout.write(f"total number of input files: {str(len(files))}\n")

    results = []

    relative_time = 0
    global_trace_map = dict()
    total_edges_max_1x = set()
    total_edges_min_2x = set()
    traces = set()
    corpus_count = 0

    start = files[0][0]

    processing_fmt_str = "\rdetermining singletons:{: " + str(len(str(len(files)))) + "d}" + f"/{str(len(files))}"

    # first we need to find edge singletons
    i = 0
    for t, f in files:
        # print status
        i += 1
        sys.stdout.write(processing_fmt_str.format(i))
        sys.stdout.flush()

        # it may happen that some inputs time out and no trace files was created for those, skip those files
        if not os.path.isfile(os.path.join(tmp_trace_dir, f)):
            continue

        with open(os.path.join(tmp_trace_dir, f), 'r') as trace_file:
            cur_trace_map = dict()
            for line in trace_file.read().splitlines():
                update_trace_map(cur_trace_map, line.strip(), detailed=True)
            for k, v in cur_trace_map.items():
                if k not in global_trace_map:
                    global_trace_map[k] = cur_trace_map[k]
                else:
                    global_trace_map[k]['n'] |= cur_trace_map[k]['n']
                    # Theoretically, we could add each different occurrence in the global trace map, but
                    # we only need to know whether a certain tuple-count combination occurred exactly once or more
                    # than once. Thus, if we observe that we had already more than 1 combination, we stop growing
                    # that set, to avoid further memory allocations.
                    if len(global_trace_map[k]['c']) == 1:
                        global_trace_map[k]['c'] = global_trace_map[k]['c'].union(cur_trace_map[k]['c'])
                if len(global_trace_map[k]['c']) == 1:
                    total_edges_max_1x.add(k)
                else:
                    if k in total_edges_max_1x:
                        total_edges_max_1x.remove(k)
                    total_edges_min_2x.add(k)
    sys.stdout.write("\n")

    # collect the data over time
    processing_fmt_str = "\robtaining data over time:{: " + str(len(str(len(files)))) + "d}" + f"/{str(len(files))}"
    global_trace_map.clear()
    diff_trace_map = dict()
    bit_count = 0
    i = 0
    for t, f in files:
        # print status
        i += 1
        sys.stdout.write(processing_fmt_str.format(i))
        sys.stdout.flush()

        diff_trace_map.clear()
        relative_time = t - start
        with open(os.path.join(tmp_trace_dir, f), 'r') as trace_file:
            cur_trace_map = dict()
            for line in trace_file.read().splitlines():
                update_trace_map(cur_trace_map, line.strip())
            traces.add(','.join(sorted(cur_trace_map.keys())))
            for k, v in cur_trace_map.items():

                if k not in global_trace_map:
                    diff_trace_map[k] = None
                    global_trace_map[k] = cur_trace_map[k]
                else:
                    diff_trace_map[k] = global_trace_map[k]
                    global_trace_map[k] |= cur_trace_map[k]
        corpus_count += 1

        cur_edges_max_1x = total_edges_max_1x.intersection(global_trace_map.keys())
        cur_edges_min_2x = total_edges_min_2x.intersection(global_trace_map.keys())

        # calculate bit-coverage of non-singletons
        bit_cov = "0.0"
        if len(cur_edges_min_2x) > 0:
            for k in cur_edges_min_2x:
                if k not in diff_trace_map:
                    continue
                if diff_trace_map[k] is None:
                    bit_count += count_bits(global_trace_map[k])
                else:
                    bit_count -= count_bits(diff_trace_map[k])
                    bit_count += count_bits(global_trace_map[k])

            bit_cov = f"{float(bit_count) / float(len(cur_edges_min_2x)):.4f}"

        results.append(
            [relative_time,
             len(traces), corpus_count,
             len(cur_edges_max_1x), len(cur_edges_min_2x), len(global_trace_map.keys()), edges_max_possible,
             bit_cov,
             f"{round(float(len(global_trace_map.keys())) / float(edges_max_possible), 4):.4f}"]
        )

    sys.stdout.write(f"\nwriting results to: {args.out}\n")
    with open(args.out, 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'relative_time',
            'traces', 'corpus_count',
            'edges_max_1x', 'edges_min_2x', 'edges_unique', 'edges_max_possible',
            'coverage_bits_edges_min_2x', 'coverage_edges_unique'
        ])
        writer.writerows(results)

    # delete tmp_trace_dir
    sys.stdout.write(f"deleting: {tmp_trace_dir}\n")
    shutil.rmtree(tmp_trace_dir, ignore_errors=True)

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

