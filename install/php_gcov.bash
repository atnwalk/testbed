if [ -z "${1+x}" ]; then
  export TARGET_DIR=~/php-src_gcov
else
  export TARGET_DIR="${1}"
  if [[ "$(realpath -m -L "${TARGET_DIR}")" == "$(realpath "$(pwd)")" ]]; then
    TARGET_DIR="$(realpath -m -L ./php-src_gcov)"
  elif [[ $(realpath -m -L "${TARGET_DIR}") == "/" ]]; then
    TARGET_DIR=/php-src_gcov
  else
    TARGET_DIR="$(realpath -m -L "${TARGET_DIR}")"
  fi
fi

export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash php.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d "${TARGET_DIR}" || ! "${TARGET_DIR}"/sapi/cli/php --version; then
  rm -rf "${TARGET_DIR}"
  cp -rp ~/php-src/. "${TARGET_DIR}"
  cd "${TARGET_DIR}"
  git clean -xdf
  git restore .

  ./buildconf
  ./configure --enable-gcov --disable-all --enable-debug-assertions --enable-option-checking=fatal --without-pcre-jit --disable-cgi --with-pic
  CC=gcc \
  CXX=g++ \
  CFLAGS=" -fprofile-arcs -ftest-coverage" \
  CXXFLAGS=" -fprofile-arcs -ftest-coverage" \
  LDFLAGS=" -lgcov --coverage" \
  make -j$(nproc)

  "${TARGET_DIR}"/sapi/cli/php --version
fi
