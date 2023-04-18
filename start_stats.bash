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

declare -A GRAMMARS=(
  [mruby_nautilus]=${HOME}/grammars/nautilus/Ruby.py
  [sqlite3_nautilus]=${HOME}/grammars/nautilus/SQLite.py
  [php_nautilus]=${HOME}/grammars/nautilus/Php.py
  [lua_nautilus]=${HOME}/grammars/nautilus/Lua.py
  [jerry_nautilus]=${HOME}/grammars/nautilus/JavaScript.py

  [mruby_gramatron]=${HOME}/grammars/gramatron/Ruby_automata.json
  [sqlite3_gramatron]=${HOME}/grammars/gramatron/SQLite_automata.json
  [php_gramatron]=${HOME}/grammars/gramatron/Php_automata.json
  [lua_gramatron]=${HOME}/grammars/gramatron/Lua_automata.json
  [jerry_gramatron]=${HOME}/grammars/gramatron/JavaScript_automata.json

  [mruby_atnwalk]=${HOME}/atnwalk/build/ruby/bin/server
  [sqlite3_atnwalk]=${HOME}/atnwalk/build/sqlite/bin/server
  [php_atnwalk]=${HOME}/atnwalk/build/php/bin/server
  [lua_atnwalk]=${HOME}/atnwalk/build/lua/bin/server
  [jerry_atnwalk]=${HOME}/atnwalk/build/javascript/bin/server
)

mkdir -p ~/campaign/"${STATS_DIR}"/{nautilus,gramatron,atnwalk}

pids=""

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
      cd ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/
      mkdir -p ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/corpus/"${campaign_date}"/atnwalk/"${target_name}"/"${i}"
      echo "${campaign_date}/atnwalk/"${target_name}"/"${i}" ${NEW_RUN_COUNT}"
      j=1
      total_files=$(find ~/campaign/"${campaign_date}/atnwalk/"${target_name}"/"${i}/out/default/queue/ -maxdepth 1 -type f | wc -l)
      for f in $(find ~/campaign/"${campaign_date}/atnwalk/"${target_name}"/"${i}/out/default/queue/ -maxdepth 1 -type f)
      do
        printf '\rdecoding: %d / %d' ${j} ${total_files}
        cat "${f}" | $(dirname ${GRAMMARS[${target_name}_atnwalk]})/client -t ${RUN_TIMEOUT} -d > ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/corpus/"${campaign_date}"/atnwalk/"${target_name}"/"${i}"/$(basename "${f}")
        touch -r "${f}" ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/corpus/"${campaign_date}"/atnwalk/"${target_name}"/"${i}"/$(basename "${f}")
        (( j++ ))
      done
      printf '\n'
      mkdir -p ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      cd ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      nohup python3 ~/testbed/afl_stats.py --out ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/"${target_name}"."${NEW_RUN_COUNT}"."${campaign_date}"."${i}".raw.csv ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/corpus/"${campaign_date}"/atnwalk/"${target_name}"/"${i}"/ -- ${target_bin} && \
      python3 ~/testbed/normalize.py ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.${campaign_date}.${i}.raw.csv ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.normalized.csv &
      pids="${pids} $!"
      (( NEW_RUN_COUNT++ ))
      sleep 1
    done
  done
  cd ~/campaign/"${STATS_DIR}"/atnwalk/"${target_name}"/
  kill -9 $(cat atnwalk.pid)
  sleep 1
  rm server.log
  rm atnwalk.pid
  rm atnwalk.socket
done
wait ${pids}

pids=""
for target_bin in ${TARGETS[@]}
do
  NEW_RUN_COUNT=1
  cd ~/campaign/"${STATS_DIR}"/gramatron/
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  cd ${target_name}
  for campaign_date in ${CAMPAIGNS[@]}
  do
    for i in $(seq 1 ${RUNS})
    do
      cd ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/
      mkdir -p ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/corpus/"${campaign_date}"/gramatron/"${target_name}"/"${i}"
      echo "${campaign_date}/gramatron/"${target_name}"/"${i}" ${NEW_RUN_COUNT}"
      echo "copying queue..."
      find ~/campaign/"${campaign_date}"/gramatron/"${target_name}"/"${i}"/out/default/queue/ -maxdepth 1 -not -name '*.aut' -type f -print0 | xargs -0 -I'{}' cp -p '{}' ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/corpus/"${campaign_date}"/gramatron/"${target_name}"/"${i}"/
      mkdir -p ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      cd ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      nohup python3 ~/testbed/afl_stats.py --out ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/"${target_name}"."${NEW_RUN_COUNT}"."${campaign_date}"."${i}".raw.csv ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/corpus/"${campaign_date}"/gramatron/"${target_name}"/"${i}"/ -- ${target_bin} && \
      python3 ~/testbed/normalize.py ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.${campaign_date}.${i}.raw.csv ~/campaign/"${STATS_DIR}"/gramatron/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.normalized.csv &
      pids="${pids} $!"
      (( NEW_RUN_COUNT++ ))
    done
  done
done
wait ${pids}

pids=""
for target_bin in ${TARGETS[@]}
do
  NEW_RUN_COUNT=1
  cd ~/campaign/"${STATS_DIR}"/nautilus/
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  cd ${target_name}
  for campaign_date in ${CAMPAIGNS[@]}
  do
    for i in $(seq 1 ${RUNS})
    do
      cd ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/
      mkdir -p ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/corpus/"${campaign_date}"/nautilus/"${target_name}"/"${i}"
      echo "${campaign_date}/nautilus/"${target_name}"/"${i}" ${NEW_RUN_COUNT}"
      echo "copying queue..."
      find ~/campaign/"${campaign_date}"/nautilus/"${target_name}"/"${i}"/out/outputs/queue/ -maxdepth 1 -not -name '*Signaled*' -type f -print0 | xargs -0 -I'{}' cp -p '{}' ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/corpus/"${campaign_date}"/nautilus/"${target_name}"/"${i}"/
      mkdir -p ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      cd ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/workdir/"${NEW_RUN_COUNT}"
      nohup python3 ~/testbed/afl_stats.py --out ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/"${target_name}"."${NEW_RUN_COUNT}"."${campaign_date}"."${i}".raw.csv ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/corpus/"${campaign_date}"/nautilus/"${target_name}"/"${i}"/ -- ${target_bin} && \
      python3 ~/testbed/normalize.py ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.${campaign_date}.${i}.raw.csv ~/campaign/"${STATS_DIR}"/nautilus/"${target_name}"/"${target_name}".${NEW_RUN_COUNT}.normalized.csv &
      pids="${pids} $!"
      (( NEW_RUN_COUNT++ ))
    done
  done
done
wait ${pids}
