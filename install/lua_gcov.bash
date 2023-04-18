if [ -z "${1+x}" ]; then
  export TARGET_DIR=~/lua_gcov
else
  export TARGET_DIR="${1}"
  if [[ "$(realpath -m -L "${TARGET_DIR}")" == "$(realpath "$(pwd)")" ]]; then
    TARGET_DIR="$(realpath -m -L ./lua_gcov)"
  elif [[ $(realpath -m -L "${TARGET_DIR}") == "/" ]]; then
    TARGET_DIR=/lua_gcov
  else
    TARGET_DIR="$(realpath -m -L "${TARGET_DIR}")"
  fi
fi

export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash lua.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d "${TARGET_DIR}" || ! "${TARGET_DIR}"/lua -v; then
  rm -rf "${TARGET_DIR}"
  cp -rp ~/lua/. "${TARGET_DIR}"
  cd "${TARGET_DIR}"
  git clean -xdf
  git restore .

  sed -i 's/^CC=.*$/CC=\gcc/' makefile
  sed -i '/^MYCFLAGS=.*$/ s/$/ -fprofile-arcs -ftest-coverage/' makefile
  sed -i '/^MYLDFLAGS=.*$/ s/$/ -lgcov --coverage/' makefile

  CC=gcc \
  CXX=g++ \
  CFLAGS=" -fprofile-arcs -ftest-coverage" \
  LDFLAGS=" -lgcov --coverage" \
  make -j$(nproc)

  "${TARGET_DIR}"/lua -v
fi
