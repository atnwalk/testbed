#!/bin/bash

executions_column='executions'
executions_y_label="Executions"
executions_format_str='{x:,.2e}'
corpus_count_column='corpus_count'
corpus_count_y_label="Corpus Count"
corpus_count_format_str='{x:,.0f}'
edges_covered_column='edges_covered'
edges_covered_y_label="Covered Edges"
edges_covered_format_str='{x:,.0f}'
bits_covered_column='bits_covered'
bits_covered_y_label="Covered Bits"
bits_covered_format_str='{x:,.4f}'
lines_covered_column='lines_covered'
lines_covered_y_label="Covered Lines"
lines_covered_format_str='{x:,.0f}'
branches_covered_column='branches_covered'
branches_covered_y_label="Covered Branches"
branches_covered_format_str='{x:,.0f}'
functions_covered_column='functions_covered'
functions_covered_y_label="Covered Functions"
functions_covered_format_str='{x:,.0f}'
files_covered_column='files_covered'
files_covered_y_label="Covered Files"
files_covered_format_str='{x:,.0f}'

for target in {jerry,lua,mruby,php,sqlite3};
do
  data_args=""
  for fuzzer in {atnwalk,nautilus,gramatron}
  do
      data_args="${data_args} --data ${fuzzer} summary/${fuzzer}.${target}.summary.csv"
  done

  python3 plot_box_plot.py \
    --format-str "${executions_format_str}" \
    --y-label "${executions_y_label}" \
    --out "graphs/${target}.${executions_column}.boxplot.pdf" \
    --column "${executions_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${corpus_count_format_str}" \
    --y-label "${corpus_count_y_label}" \
    --out "graphs/${target}.${corpus_count_column}.boxplot.pdf" \
    --column "${corpus_count_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${edges_covered_format_str}" \
    --y-label "${edges_covered_y_label}" \
    --out "graphs/${target}.${edges_covered_column}.boxplot.pdf" \
    --column "${edges_covered_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${bits_covered_format_str}" \
    --y-label "${bits_covered_y_label}" \
    --out "graphs/${target}.${bits_covered_column}.boxplot.pdf" \
    --column "${bits_covered_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${lines_covered_format_str}" \
    --y-label "${lines_covered_y_label}" \
    --out "graphs/${target}.${lines_covered_column}.boxplot.pdf" \
    --column "${lines_covered_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${branches_covered_format_str}" \
    --y-label "${branches_covered_y_label}" \
    --out "graphs/${target}.${branches_covered_column}.boxplot.pdf" \
    --column "${branches_covered_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${functions_covered_format_str}" \
    --y-label "${functions_covered_y_label}" \
    --out "graphs/${target}.${functions_covered_column}.boxplot.pdf" \
    --column "${functions_covered_column}" \
    ${data_args}

  python3 plot_box_plot.py \
    --format-str "${files_covered_format_str}" \
    --y-label "${files_covered_y_label}" \
    --out "graphs/${target}.${files_covered_column}.boxplot.pdf" \
    --column "${files_covered_column}" \
    ${data_args}
done
