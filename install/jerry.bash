export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d jerryscript; then
  git clone https://github.com/jerryscript-project/jerryscript.git
fi

cd ~
if ! ~/jerryscript/build/bin/jerry --version; then
  cd jerryscript/
  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  AFL_USE_ASAN=1 \
  python3 tools/build.py --lto=off

  ~/jerryscript/build/bin/jerry --version
fi
