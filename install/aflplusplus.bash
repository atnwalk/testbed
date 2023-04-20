export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d AFLplusplus; then
  git clone https://github.com/atnwalk/AFLplusplus.git
fi

cd ~/AFLplusplus/
if ! test -x ~/AFLplusplus/afl-fuzz; then
  make all
fi

~/AFLplusplus/afl-fuzz -h | head -n1
