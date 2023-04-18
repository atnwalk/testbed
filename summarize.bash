#!/bin/bash
CAMPAIGNS=("${@}")
STATS_DIR="stats"$(printf "_%s" "${CAMPAIGNS[@]}")

summary_dir=~/campaign/"${STATS_DIR}"/summary
mkdir -p "${summary_dir}"

declare -A data_for

find ~/campaign/"${STATS_DIR}" -maxdepth 4 -type f -name 'campaign.*' -print0 | while IFS= read -r -d '' f
do
  # link each CSV file in the summary directory
  for csv_file in "$(dirname "${f}")"/*.csv
  do
    # we use a relative paths to make it more portable
    ln -s "$(realpath --relative-to="${summary_dir}"/ "${csv_file}")" "${summary_dir}"
  done

  # append the CSV header to the summary row
  prefix="$(basename "${f}" | cut -d'.' -f2-3)"
  if [[ ! -v 'data_for['"${prefix}"']' ]]; then
    first_row_afl_stats=$(head -n1 "$(dirname "${f}")"/*.afl_stats.csv | cut -d',' -f2- | tr -d '\r' | tr -d '\n')
    first_row_coverage=$(head -n1 "$(dirname "${f}")"/*.coverage.csv | cut -d',' -f2- | tr -d '\r' | tr -d '\n')
    echo "campaign,duration,${first_row_afl_stats},${first_row_coverage},crashes,executions" > "${summary_dir}"/"${prefix}".summary.csv
    data_for[${prefix}]=1
  fi

  # obtain the CSV data row and append it to the summary file
  campaign=$(basename "$(dirname "${f}")")
  duration=$(tail -n1 "$(dirname "${f}")"/*.afl_stats.normalized.csv | cut -d',' -f1 | tr -d '\r' | tr -d '\n')
  last_row_afl_stats=$(tail -n1 "$(dirname "${f}")"/*.afl_stats.csv | cut -d',' -f2- | tr -d '\r' | tr -d '\n')
  last_row_coverage=$(tail -n1 "$(dirname "${f}")"/*.coverage.csv | cut -d',' -f2- | tr -d '\r' | tr -d '\n')
  crashes=$(cat "$(dirname "${f}")"/*.total_crashes.txt)
  executions=$(cat "$(dirname "${f}")"/*.total_execs.txt)
  echo "${campaign},${duration},${last_row_afl_stats},${last_row_coverage},${crashes},${executions}" >> "${summary_dir}"/"${prefix}".summary.csv
done

cd "${summary_dir}"/..
tar -hczf summary.tar.gz summary/
