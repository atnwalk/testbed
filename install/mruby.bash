export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d mruby; then
  git clone https://github.com/mruby/mruby.git
fi

cd ~
if ! ~/mruby/bin/mruby --version; then
  cd mruby/

  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  AFL_USE_ASAN=1 \
  make -j$(nproc)

  ~/mruby/bin/mruby --version
fi

