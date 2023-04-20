export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash go.bash
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
cd "${SCRIPT_DIR}" && bash grammars.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d atnwalk; then
  git clone https://github.com/atnwalk/atnwalk.git
fi

if ! test -L atnwalk/grammars; then
  ln -s ~/grammars/antlr4 ~/atnwalk/grammars
fi

cd ~/atnwalk/
./build.bash

cd ~
if ! test -f AFLplusplus/custom_mutators/atnwalk/atnwalk.so; then
  cd ~/AFLplusplus/custom_mutators/atnwalk
  gcc -I ~/AFLplusplus/include/ -shared -fPIC -Wall -O3 atnwalk.c -o atnwalk.so
fi

echo "[ check for atnwalk.so ] "$(ls ~/AFLplusplus/custom_mutators/atnwalk/atnwalk.so)
find ~/atnwalk/build/ -type d -name bin -print0 | xargs -0 -I'{}' bash -c 'echo "[ check for server and client ] "$(ls "{}"/{server,client})'
