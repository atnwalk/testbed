import csv
import sys
import argparse
from scipy.stats import mannwhitneyu
from scipy.stats import rankdata


def main(argv):
    parser = argparse.ArgumentParser(prog=argv[0])
    parser.add_argument("--data", "-d", type=str, nargs=3, action='append',
                        metavar=("FUZZER", "TARGET", "CSV_FILE"), required=True)
    parser.add_argument("--column", type=str, default="branches_covered")
    parser.add_argument("--out", type=str, default="stat_tests.csv")
    args = parser.parse_args(argv[1:])

    FUZZER = 0
    TARGET = 1
    CSV_FILE = 2

    work = dict()
    for d in args.data:
        rows = None
        with open(d[CSV_FILE], 'r') as f:
            reader = csv.reader(f)
            rows = list(reader)
        # read the CSV data of the column specified in args
        if d[FUZZER] not in work:
            work[d[FUZZER]] = {d[TARGET]: list(map(float, list(map(list, zip(*rows[1:])))[rows[0].index(args.column)]))}
        else:
            work[d[FUZZER]][d[TARGET]] = list(map(float, list(map(list, zip(*rows[1:])))[rows[0].index(args.column)]))

    rows_out = [["target", "fuzzer1", "fuzzer2", "mann_whitney_u_p_value", "vargha_delaney_a12"]]
    for fuzzer1 in work:
        for fuzzer2 in work:
            if fuzzer1 == fuzzer2:
                continue
            for target in work[fuzzer1]:
                # Mann-Whitney U test (nonparametric statistical test)
                # reference why to use:
                # Böhme, M., Szekeres, L., & Metzman, J. (2022).
                # On the Reliability of Coverage-Based Fuzzer Benchmarking.
                # In 44th IEEE/ACM International Conference on Software Engineering, ser. ICSE (Vol. 22).
                # https://doi.org/10.1145/3510003.3510230
                p_val = mannwhitneyu(work[fuzzer1][target], work[fuzzer2][target], alternative='two-sided').pvalue

                # Vargha-Delaney's A12 (nonparametric effect size measure)
                # reference how to calculate and interpret it
                # limits for "verbal" interpretation: >= 0.56 small, >= 0.64 medium, and >= 0.71 large
                # Vargha, A., & Delaney, H. D. (2000).
                # A Critique and Improvement of the CL Common Language Effect Size Statistics of McGraw and Wong.
                # Journal of Educational and Behavioral Statistics, 25(2), 101–132.
                # https://doi.org/10.3102/10769986025002101

                # additional reference of why and how to use Vargha-Delaney's A12
                # in software engineering with example explanation of the variables below
                # "If the two algorithms are equivalent, then A12=0.5. [...]. For example, A12=0.7 entails one would
                # obtain better results 70% of the time with [algorithm] A [over algorithm B]."
                # Arcuri, A. and Briand, L. (2014),
                # A Hitchhiker's guide to statistical tests for assessing randomized algorithms in software engineering.
                # Softw. Test. Verif. Reliab., 24: 219-250.
                # https://doi.org/10.1002/stvr.1486
                R1 = float(sum(rankdata(work[fuzzer1][target] + work[fuzzer2][target])[:len(work[fuzzer1][target])]))
                m = float(len(work[fuzzer1][target]))
                n = float(len(work[fuzzer2][target]))
                A12 = (R1 / m - (m + 1.0) / 2.0) / n

                p_val_str = f"{p_val:.2e}" if p_val < 0.0001 and p_val != 0.0 else f"{p_val:.4f}"
                a12_str = f"{A12:.2e}" if A12 < 0.0001 and A12 != 0. else f"{A12:.4f}"

                rows_out.append([target, fuzzer1, fuzzer2, p_val_str, a12_str])

    # with open(args.out, 'w') as f:
    writer = csv.writer(sys.stdout)
    writer.writerow(rows_out[0])
    writer.writerows(sorted(rows_out[1:]))


if __name__ == '__main__':
    sys.exit(main(sys.argv))
