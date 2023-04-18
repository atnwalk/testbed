#!/bin/bash

CAMPAIGNS=("${@}")
FUZZER=nautilus
STATS_DIR="stats"$(printf "_%s" "${CAMPAIGNS[@]}")

# 24h = 86400
TIMEOUT=86400 
RUNS=5
RUN_TIMEOUT=100
TARGETS=(
  "${HOME}/mruby/bin/mruby"
  "${HOME}/sqlite3/sqlite3"
  "${HOME}/php-src/sapi/cli/php"
  "${HOME}/lua/lua"
  "${HOME}/jerryscript/build/bin/jerry"
)

mkdir -p ~/campaign/"${STATS_DIR}"/${FUZZER}

pids=""
NEW_RUN_COUNT=1
for campaign_date in "${CAMPAIGNS[@]}"
do
  for target_bin in ${TARGETS[@]}
  do
    cd ~/campaign/"${STATS_DIR}"/${FUZZER}/
    target_name=$(basename ${target_bin})
    mkdir -p ${target_name}
    cd ${target_name}
    for i in $(seq 1 ${RUNS})
    do
      mkdir -p ~/campaign/"${STATS_DIR}"/${FUZZER}/"${target_name}"/"${NEW_RUN_COUNT}"/{corpus,workdir}
      this_run_dir=~/campaign/"${STATS_DIR}"/${FUZZER}/"${target_name}"/"${NEW_RUN_COUNT}"/
      cd "${this_run_dir}"
      touch campaign.${FUZZER}."${target_name}"."${campaign_date}"."${i}"
      echo "${FUZZER}: ${target_name} ${NEW_RUN_COUNT} (${i} / ${campaign_date})"
      echo "copying queue..."
      find ~/campaign/"${campaign_date}"/nautilus/"${target_name}"/"${i}"/out/outputs/queue/ -maxdepth 1 -not -name '*Signaled*' -type f -print0 | xargs -0 -I'{}' cp -p '{}' "${this_run_dir}/corpus/"
      bash ~/testbed/install/${target_name}_gcov.bash "${this_run_dir}/src/"
      cd "${this_run_dir}/workdir/"

      nohup \
        python3 ~/testbed/coverage.py \
          --test-input-dir "${this_run_dir}/corpus/" \
          --gcov-csv-bin ~/go/bin/gcov-csv \
          --gcov-src-dir "${this_run_dir}/src/" \
          --use-stdin \
          --timeout "${RUN_TIMEOUT}" \
          --csv-file "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".coverage.csv \
          "${this_run_dir}/src/$(printf "${target_bin#${HOME}}" | cut -d'/' -f3-)" > "${this_run_dir}"/coverage.log 2>&1 \
        && \
        python3 ~/testbed/normalize.py \
          "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".coverage.csv \
          "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".coverage.normalized.csv > "${this_run_dir}"/coverage_normalize.log 2>&1 &
      pids="${pids} $!"

      nohup \
        python3 ~/testbed/afl_stats.py \
          --out "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".afl_stats.csv \
          "${this_run_dir}/corpus/" -- "${target_bin}" > "${this_run_dir}"/afl_stats.log 2>&1 \
        && \
        python3 ~/testbed/normalize.py \
          "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".afl_stats.csv \
          "${this_run_dir}"/"${FUZZER}.${target_name}.${NEW_RUN_COUNT}".afl_stats.normalized.csv > "${this_run_dir}"/afl_normalize.log 2>&1 &
      pids="${pids} $!"

      grep -F 'Execution Count:' ~/campaign/"${campaign_date}"/"${FUZZER}"/"${target_name}"/"${i}"/nautilus.log | tail -n1 | cut -d':' -f2 | xargs > "${this_run_dir}"/"${FUZZER}"."${target_name}".${NEW_RUN_COUNT}.total_execs.txt
      find ~/campaign/"${campaign_date}"/"${FUZZER}"/"${target_name}"/"${i}"/out/outputs/signaled/ -maxdepth 1 -type f -printf x | wc -c > "${this_run_dir}"/"${FUZZER}"."${target_name}".${NEW_RUN_COUNT}.total_crashes.txt

      (( NEW_RUN_COUNT++ ))
    done
    (( NEW_RUN_COUNT -= RUNS ))
  done
  (( NEW_RUN_COUNT += RUNS ))
done
wait ${pids}
