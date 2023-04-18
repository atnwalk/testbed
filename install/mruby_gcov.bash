if [ -z "${1+x}" ]; then
  export TARGET_DIR=~/mruby_gcov
else
  export TARGET_DIR="${1}"
  if [[ "$(realpath -m -L "${TARGET_DIR}")" == "$(realpath "$(pwd)")" ]]; then
    TARGET_DIR="$(realpath -m -L ./mruby_gcov)"
  elif [[ $(realpath -m -L "${TARGET_DIR}") == "/" ]]; then
    TARGET_DIR=/mruby_gcov
  else
    TARGET_DIR="$(realpath -m -L "${TARGET_DIR}")"
  fi
fi

export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash mruby.bash
source "${SCRIPT_DIR}"/env.bash

if ! test -d "${TARGET_DIR}" || ! "${TARGET_DIR}"/bin/mruby --version; then
  rm -rf "${TARGET_DIR}"
  mkdir -p "${TARGET_DIR}"
  cp -rp ~/mruby/. "${TARGET_DIR}"
  cd "${TARGET_DIR}"
  git clean -xdf
  git restore .

  CC=gcc \
  CXX=g++ \
  CFLAGS=" -fprofile-arcs -ftest-coverage" \
  CXXFLAGS=" -fprofile-arcs -ftest-coverage" \
  LDFLAGS=" -lgcov --coverage" \
  make -j$(nproc)

  "${TARGET_DIR}"/bin/mruby --version
fi
