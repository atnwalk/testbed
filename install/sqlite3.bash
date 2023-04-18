export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash fossil.bash
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -f sqlite3/sqlite.fossil; then
  rm -rf ~/sqlite3
  mkdir -p ~/sqlite3
  cd ~/sqlite3/
  echo y | fossil clone https://www.sqlite.org/src sqlite.fossil
  echo y | fossil open sqlite.fossil
fi

cd ~
if ! sqlite3/sqlite3 --version; then
  cd sqlite3/

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  ./configure

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  make sqlite3.c

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  AFL_USE_ASAN=1 \
  ~/AFLplusplus/afl-cc -O3 \
    -DSQLITE_DEBUG \
    -DSQLITE_MAX_EXPR_DEPTH=0 \
    -DSQLITE_THREADSAFE=0 \
    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
    -DSQLITE_OMIT_LOAD_EXTENSION \
    -DSQLITE_OMIT_JSON \
    -DSQLITE_OMIT_DEPRECATED \
    -I. shell.c sqlite3.c -o sqlite3

  ~/sqlite3/sqlite3 --version
fi
