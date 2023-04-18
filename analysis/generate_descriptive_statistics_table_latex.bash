#!/bin/bash

executions_fmt='{executions_min:,.0f} & {executions_q1:,.0f} & {executions_median:,.0f} & {executions_q3:,.0f} & {executions_max:,.0f} & {executions_mean:,.1f} & {executions_sd:,.1f} & NA \\\\\n'
corpus_fmt='{corpus_count_min:,.0f} & {corpus_count_q1:,.0f} & {corpus_count_median:,.0f} & {corpus_count_q3:,.0f} & {corpus_count_max:,.0f} & {corpus_count_mean:,.1f} & {corpus_count_sd:,.1f} & NA \\\\\n'
edges_fmt='{edges_covered_min:,.0f} & {edges_covered_q1:,.0f} & {edges_covered_median:,.0f} & {edges_covered_q3:,.0f} & {edges_covered_max:,.0f} & {edges_covered_mean:,.1f} & {edges_covered_sd:,.1f} & {edges_total_max:,.0f} \\\\\n'
bits_fmt='{bits_covered_min:,.4f} & {bits_covered_q1:,.4f} & {bits_covered_median:,.4f} & {bits_covered_q3:,.4f} & {bits_covered_max:,.4f} & {bits_covered_mean:,.4f} & {bits_covered_sd:,.4f} & {bits_total_max:,.4f} \\\\\n'
lines_fmt='{lines_covered_min:,.0f} & {lines_covered_q1:,.0f} & {lines_covered_median:,.0f} & {lines_covered_q3:,.0f} & {lines_covered_max:,.0f} & {lines_covered_mean:,.1f} & {lines_covered_sd:,.1f} & {lines_total_max:,.0f} \\\\\n'
branches_fmt='{branches_covered_min:,.0f} & {branches_covered_q1:,.0f} & {branches_covered_median:,.0f} & {branches_covered_q3:,.0f} & {branches_covered_max:,.0f} & {branches_covered_mean:,.1f} & {branches_covered_sd:,.1f} & {branches_total_max:,.0f} \\\\\n'
functions_fmt='{functions_covered_min:,.0f} & {functions_covered_q1:,.0f} & {functions_covered_median:,.0f} & {functions_covered_q3:,.0f} & {functions_covered_max:,.0f} & {functions_covered_mean:,.1f} & {functions_covered_sd:,.1f} & {functions_total_max:,.0f} \\\\\n'
files_fmt='{files_covered_min:,.0f} & {files_covered_q1:,.0f} & {files_covered_median:,.0f} & {files_covered_q3:,.0f} & {files_covered_max:,.0f} & {files_covered_mean:,.1f} & {files_covered_sd:,.1f} & {files_total_max:,.0f} \\\\\n'



table_rows=""


for target in {jerry,lua,mruby,php,sqlite3}
do

cat <<EOF
\begin{table*}[!t]
\renewcommand{\arraystretch}{1.3}
\caption{Descriptive statistics for the fuzz target \textbf{${target}}. (Campaign length: 24 hours, Repetitions: 20)}
\label{stats_${target}}
EOF

cat <<'EOF'
\centering
\begin{tabular}{llrrrrrrrr}
\hline
Variable & Fuzzer & Minimum & 1st Quart. & Median & 3rd Quart. & Maximum & Mean & Std.~Dev. & Max.~Possible \\
\hline
EOF

python3 descriptive_statistics.py --format-str "executions & atnwalk & ${executions_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${executions_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${executions_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "corpus & atnwalk & ${corpus_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${corpus_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${corpus_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "edges & atnwalk & ${edges_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${edges_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${edges_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "bits & atnwalk & ${bits_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${bits_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${bits_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "lines & atnwalk & ${lines_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${lines_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${lines_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "branches & atnwalk & ${branches_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${branches_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${branches_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "functions & atnwalk & ${functions_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${functions_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${functions_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"
python3 descriptive_statistics.py --format-str "files & atnwalk & ${files_fmt}" summary/atnwalk."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& nautilus & ${files_fmt}" summary/nautilus."${target}".summary.csv
python3 descriptive_statistics.py --format-str "& gramatron & ${files_fmt}" summary/gramatron."${target}".summary.csv
echo "\hline"

cat <<'EOF'
\end{tabular}
\end{table*}

EOF

done

