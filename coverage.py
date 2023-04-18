import os
import sys
import argparse
import subprocess


def main(argv):
    # parse script arguments
    parser = argparse.ArgumentParser(prog=argv[0], add_help=False)
    required_args = parser.add_argument_group('required arguments')
    required_args.add_argument("--test-input-dir", type=str, dest="test_input_dir", required=True)
    required_args.add_argument("--gcov-csv-bin", type=str, dest="gcov_csv_bin", required=True)
    required_args.add_argument("--gcov-src-dir", type=str, dest="gcov_src_dir", required=True)
    optional_args = parser.add_argument_group('optional arguments')
    optional_args.add_argument('--help', action='help', default=argparse.SUPPRESS)
    optional_args.add_argument("--use-stdin", action="store_true", dest="use_stdin", default=False)
    optional_args.add_argument("--timeout", type=float, dest="timeout", default=100.0)
    optional_args.add_argument("--csv-file", type=str, dest="csv_file", default="out.csv")
    parser.add_argument("program", type=str)
    parser.add_argument("args", type=str, nargs="*")
    args = parser.parse_args(argv[1:])

    # get a list of files with their timestamp, sorted by timestamp,
    # in the form of [(timestamp1, 'filename1'), ...]
    files = []
    for f in os.listdir(args.test_input_dir):
        if os.path.isfile(os.path.join(args.test_input_dir, f)) and not f.startswith('.'):
            files.append(
                tuple((
                    int(os.stat(os.path.join(args.test_input_dir, f)).st_mtime),
                    os.path.join(args.test_input_dir, f)
                ))
            )
    files = list(sorted(files))
    sys.stdout.write(f"total test inputs: {str(len(files))}\n")
    sys.stdout.flush()

    # reset Gcov counters (*.gcda files)
    proc = subprocess.Popen([os.path.abspath(args.gcov_csv_bin), "--reset"],
                            cwd=os.path.abspath(args.gcov_src_dir),
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    proc.wait()

    # create or empty the CSV file and write the CSV header line
    csv_file = open(args.csv_file, "w")
    csv_file.seek(0)
    csv_file.truncate()
    csv_file.write("time,lines_covered,lines_total,branches_covered,branches_total,"
                   "functions_covered,functions_total,files_covered,files_total\n")
    i = 0
    start = files[0][0]
    processing_fmt_str = "\rprocessing:{: " + str(len(str(len(files)))) + "d}" + f"/{str(len(files))}"
    for t, f in files:
        # print status
        i += 1
        sys.stdout.write(processing_fmt_str.format(i))
        sys.stdout.flush()

        # execute the test input
        proc_args = list(map(lambda x: f if x == "@@" else x, args.args))
        proc = subprocess.Popen([os.path.abspath(args.program)] + proc_args,
                                stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            if args.use_stdin:
                input_file = open(f, "rb")
                proc.communicate(input=input_file.read(), timeout=args.timeout / 1000.0)
                input_file.close()
            else:
                proc.communicate(timeout=args.timeout / 1000.0)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

        # obtain coverage information with gcov-csv
        proc = subprocess.Popen([os.path.abspath(args.gcov_csv_bin)],
                                cwd=os.path.abspath(args.gcov_src_dir),
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        output, _ = proc.communicate()
        csv_file.write(f"{t - start:d},{output.decode().rstrip()}\n")
    sys.stdout.write("\n")
    sys.stdout.flush()
    csv_file.close()
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

