export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d lua; then
  git clone https://github.com/lua/lua.git
fi

cd ~
if ! ~/lua/lua -v; then
  cd lua/
  sed -i 's/^CC=.*$/CC=\~\/AFLplusplus\/afl-cc/' makefile
  
  CC=~/AFLplusplus/afl-cc \
  CXX=~/AFLplusplus/afl-c++ \
  AFL_CC_COMPILER=LLVM \
  AFL_LLVM_INSTRUMENT=PCGUARD \
  AFL_USE_ASAN=1 \
  make -j$(nproc)
  
  ~/lua/lua -v
fi

