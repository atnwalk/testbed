#!/bin/bash

CAMPAIGNS=(
  "20221118-125610"
  "20221119-171727"
  "20221120-180154"
)

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


mkdir -p ~/campaign/"${STATS_DIR}"/{nautilus,gramatron,atnwalk}

for target_bin in ${TARGETS[@]}
do
  NEW_RUN_COUNT=1
  cd ~/campaign/"${STATS_DIR}"/atnwalk/
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  cd ${target_name}
  nohup ${GRAMMARS[${target_name}_atnwalk]} ${RUN_TIMEOUT} > server.log 2>&1 &
  sleep 1
  for campaign_date in ${CAMPAIGNS[@]}
  do
    for i in $(seq 1 ${RUNS})
    do
      grep 'execs_done' ~/campaign/"${campaign_date}/atnwalk/"${target_name}"/"${i}/out/default/fuzzer_stats | cut -d':' -f2 | xargs > ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_execs.txt
      find ~/campaign/"${campaign_date}/atnwalk/"${target_name}"/"${i}/out/default/crashes/ -maxdepth 1 -type f -not -name 'README.txt' -printf x | wc -c > ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_crashes.txt
      (( NEW_RUN_COUNT++ ))
    done
  done
done

for target_bin in ${TARGETS[@]}
do
  NEW_RUN_COUNT=1
  cd ~/campaign/"${STATS_DIR}"/gramatron/
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  cd ${target_name}
  nohup ${GRAMMARS[${target_name}_atnwalk]} ${RUN_TIMEOUT} > server.log 2>&1 &
  sleep 1
  for campaign_date in ${CAMPAIGNS[@]}
  do
    for i in $(seq 1 ${RUNS})
    do
      grep 'execs_done' ~/campaign/"${campaign_date}/gramatron/"${target_name}"/"${i}/out/default/fuzzer_stats | cut -d':' -f2 | xargs > ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_execs.txt
      find ~/campaign/"${campaign_date}/gramatron/"${target_name}"/"${i}/out/default/crashes/ -maxdepth 1 -type f -not -name 'README.txt' -printf x | wc -c > ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_crashes.txt
      (( NEW_RUN_COUNT++ ))
    done
  done
done

for target_bin in ${TARGETS[@]}
do
  NEW_RUN_COUNT=1
  cd ~/campaign/"${STATS_DIR}"/nautilus/
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  cd ${target_name}
  nohup ${GRAMMARS[${target_name}_atnwalk]} ${RUN_TIMEOUT} > server.log 2>&1 &
  sleep 1
  for campaign_date in ${CAMPAIGNS[@]}
  do
    for i in $(seq 1 ${RUNS})
    do
      grep -F 'Execution Count:' ~/campaign/"${campaign_date}/nautilus/"${target_name}"/"${i}/nautilus.log | tail -n1 | cut -d':' -f2 | xargs > ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_execs.txt
      find ~/campaign/"${campaign_date}/nautilus/"${target_name}"/"${i}/out/outputs/signaled/ -maxdepth 1 -type f -printf x | wc -c > ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.total_crashes.txt
      (( NEW_RUN_COUNT++ ))
    done
  done
done

