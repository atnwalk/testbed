#!/bin/bash

cd ~

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

TOTAL_RUNS=$(( ${#GRAMMARS[@]}*RUNS ))
CPU_OFFSET=$(( RANDOM % TOTAL_RUNS ))
CPU_COUNT=0

NOW=$(date +'%Y%m%d-%H%M%S')
mkdir -p ${HOME}/campaign/${NOW}/{nautilus,gramatron,atnwalk}

cd ${HOME}/campaign/${NOW}
mkdir seeds/
cd seeds
for target_bin in ${TARGETS[@]}
do
  target_name=$(basename ${target_bin})
  mkdir -p ${target_name}
  for i in $(seq 1 ${RUNS})
  do
    while true;
    do
      head -c1 /dev/urandom | $(dirname ${GRAMMARS[${target_name}_atnwalk]})/decode -wb > ${target_name}/seed.${i}.decoded 2> ${target_name}/seed.${i}.encoded
      if [[ $(ls -l ${target_name}/seed.${i}.encoded | awk '{print $5}') -eq '0' ]]; then
        continue
      fi
      if [[ $(ls -l ${target_name}/seed.${i}.decoded | awk '{print $5}') -eq '0' ]]; then
        continue
      fi
      break
    done
  done
done

cd ${HOME}/campaign/${NOW}/atnwalk/
for target_bin in ${TARGETS[@]}
do
  target_name=$(basename ${target_bin})
  for i in $(seq 1 ${RUNS})
  do
    d=${target_name}/${i}
    mkdir -p "${d}"
    cd "${d}"
    mkdir -p in/
    cp ${HOME}/campaign/${NOW}/seeds/${target_name}/seed.${i}.encoded in/seed
    echo "atnwalk: ${d} $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS ))"
    nohup taskset -c $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS )) ${GRAMMARS[${target_name}_atnwalk]} ${RUN_TIMEOUT} > server.log 2>&1 &
    AFL_SKIP_CPUFREQ=1 \
    AFL_DISABLE_TRIM=1 \
    AFL_CUSTOM_MUTATOR_ONLY=1 \
    AFL_CUSTOM_MUTATOR_LIBRARY=${HOME}/AFLplusplus/custom_mutators/atnwalk/atnwalk.so \
    AFL_POST_PROCESS_KEEP_ORIGINAL=1 \
    nohup timeout ${TIMEOUT} ${HOME}/AFLplusplus/afl-fuzz -t ${RUN_TIMEOUT} -i in/ -o out -b $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS )) -- ${target_bin} >/dev/null 2>&1 &
    nohup bash -c "sleep ${TIMEOUT}; "'kill $(cat atnwalk.pid);' >/dev/null 2>&1 &
    (( CPU_COUNT++ ))
    sleep 1
    cd - > /dev/null
  done
done

cd ${HOME}/campaign/${NOW}/gramatron/
for target_bin in ${TARGETS[@]}
do
  target_name=$(basename ${target_bin})
  for i in $(seq 1 ${RUNS})
  do
    d=${target_name}/${i}
    mkdir -p "${d}"
    cd "${d}"
    mkdir -p in/
    cp ${HOME}/campaign/${NOW}/seeds/${target_name}/seed.${i}.decoded in/seed
    echo "gramatron: ${d} $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS ))"
    AFL_SKIP_CPUFREQ=1 \
    AFL_DISABLE_TRIM=1 \
    AFL_CUSTOM_MUTATOR_ONLY=1 \
    AFL_CUSTOM_MUTATOR_LIBRARY=${HOME}/AFLplusplus/custom_mutators/gramatron/gramatron.so \
    GRAMATRON_AUTOMATION=${GRAMMARS[${target_name}_gramatron]} \
    nohup timeout ${TIMEOUT} ${HOME}/AFLplusplus/afl-fuzz -t ${RUN_TIMEOUT} -i in/ -o out -b $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS )) -- ${target_bin} >/dev/null 2>&1 &
    (( CPU_COUNT++ ))
    sleep 1
    cd - > /dev/null
  done
done

cd ${HOME}/campaign/${NOW}/nautilus/
for target_bin in ${TARGETS[@]}
do
  target_name=$(basename ${target_bin})
  for i in $(seq 1 ${RUNS})
  do
    d=${target_name}/${i}
    mkdir -p "${d}"
    cd "${d}"
    mkdir out
    echo "nautilus: ${d} $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS ))"
    cat <<EOF > config.ron
Config(
  //You probably want to change the follwoing options
  //File Paths
  path_to_bin_target:                     "${target_bin}",
  arguments:        [], //"@@" will be exchanged with the path of a file containing the current input
  path_to_grammar:                        "${GRAMMARS[${target_name}_nautilus]}",
  path_to_workdir:                        "$(pwd)/out",
  number_of_threads:      1,
  timeout_in_millis:      ${RUN_TIMEOUT},
  //The rest of the options are probably not something you want to change... 
  //Forkserver parameter
  bitmap_size:        65536, //1<<16
  //Thread Settings:
  thread_size:        4194304,
  hide_output: true, //hide stdout of the target program. Sometimes usefull for debuging
  
  //Mutation Settings
  number_of_generate_inputs:    100,  //see main.rs fuzzing_thread 
  max_tree_size:        1000,   //see state.rs generate random
  number_of_deterministic_mutations:  1,  //see main.rs process_input
)
EOF
    nohup timeout ${TIMEOUT} taskset -c $(( (CPU_OFFSET + CPU_COUNT) % TOTAL_RUNS )) ${HOME}/nautilus/target/release/fuzzer > nautilus.log 2>&1 &
    (( CPU_COUNT++ ))
    sleep 1
    cd - > /dev/null
  done
done

# safety timeout of 5 min and then wait 24h to terminate this script (used to halt termination of the docker container)
sleep 300
sleep ${TIMEOUT}
