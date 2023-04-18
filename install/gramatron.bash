export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash aflplusplus.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -f AFLplusplus/custom_mutators/gramatron/gramatron.so; then
  cd ~/AFLplusplus/custom_mutators/gramatron

  # for some reason the repo stores the .git folder as a file for that submodul
  # fix the script to test for a file instead of a directory
  sed -i 's/test -d json-c\/.git/test -f json-c\/.git/g' build_gramatron_mutator.sh

  ./build_gramatron_mutator.sh
fi

echo "[ check for gramatron.so ] "$(ls ~/AFLplusplus/custom_mutators/gramatron/gramatron.so)
