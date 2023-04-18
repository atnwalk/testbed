if [ -z "${1+x}" ]; then
  export TARGET_DIR=~/jerryscript_gcov
else
  export TARGET_DIR="${1}"
  if [[ "$(realpath -m -L "${TARGET_DIR}")" == "$(realpath "$(pwd)")" ]]; then
    TARGET_DIR="$(realpath -m -L ./jerryscript_gcov)"
  elif [[ $(realpath -m -L "${TARGET_DIR}") == "/" ]]; then
    TARGET_DIR=/jerryscript_gcov
  else
    TARGET_DIR="$(realpath -m -L "${TARGET_DIR}")"
  fi
fi

export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash jerryscript.bash
source "${SCRIPT_DIR}"/env.bash

if ! test -d "${TARGET_DIR}" || ! "${TARGET_DIR}"/build/bin/jerry --version; then
  rm -rf "${TARGET_DIR}"
  mkdir -p "${TARGET_DIR}"
  cp -rp ~/jerryscript/. "${TARGET_DIR}"
  cd "${TARGET_DIR}"
  git clean -xdf
  git restore .

  CC=gcc \
  CXX=gcc \
  CFLAGS=" -fprofile-arcs -ftest-coverage" \
  CXXFLAGS=" -fprofile-arcs -ftest-coverage" \
  LDFLAGS=" -lgcov --coverage" \
  python3 tools/build.py --lto=off

  "${TARGET_DIR}"/build/bin/jerry --version
fi
