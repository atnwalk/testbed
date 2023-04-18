if [ -z "${1+x}" ]; then
  export TARGET_DIR=~/sqlite3_gcov
else
  export TARGET_DIR="${1}"
  if [[ "$(realpath -m -L "${TARGET_DIR}")" == "$(realpath "$(pwd)")" ]]; then
    TARGET_DIR="$(realpath -m -L ./sqlite3_gcov)"
  elif [[ $(realpath -m -L "${TARGET_DIR}") == "/" ]]; then
    TARGET_DIR=/sqlite3_gcov
  else
    TARGET_DIR="$(realpath -m -L "${TARGET_DIR}")"
  fi
fi

export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash sqlite3.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d "${TARGET_DIR}" || ! "${TARGET_DIR}"/sqlite3 --version; then
  rm -rf "${TARGET_DIR}"
  cp -rp ~/sqlite3/. "${TARGET_DIR}"
  cd "${TARGET_DIR}"
  fossil clean -x
  fossil revert

  CC=gcc \
  CXX=g++ \
  ./configure --enable-gcov

  make sqlite3.c

  gcc -fprofile-arcs -ftest-coverage -lgcov --coverage \
    -O3 \
    -DSQLITE_DEBUG \
    -DSQLITE_MAX_EXPR_DEPTH=0 \
    -DSQLITE_THREADSAFE=0 \
    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
    -DSQLITE_OMIT_LOAD_EXTENSION \
    -DSQLITE_OMIT_JSON \
    -DSQLITE_OMIT_DEPRECATED \
    -I. shell.c sqlite3.c -o sqlite3

  "${TARGET_DIR}"/sqlite3 --version
fi
