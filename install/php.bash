export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d php-src; then
  git clone https://github.com/php/php-src.git
fi

cd ~
if ! ~/php-src/sapi/cli/php --version; then
  cd php-src/

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=CLASSIC \
  AFL_USE_ASAN=1 \
  ./buildconf

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=CLASSIC \
  AFL_USE_ASAN=1 \
  ./configure --disable-all --enable-debug-assertions --enable-option-checking=fatal --without-pcre-jit --disable-cgi --with-pic

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=CLASSIC \
  AFL_USE_ASAN=1 \
  make -j$(nproc)

  ~/php-src/sapi/cli/php --version
fi
