export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash rust.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d nautilus; then
  git clone https://github.com/nautilus-fuzz/nautilus.git
fi

if ! ~/nautilus/target/release/fuzzer --help; then
  cd nautilus/
  git checkout 7b013f2ef0531fe4dbe24e34169653cce1f2a3b9
  cargo build --release
  ~/nautilus/target/release/fuzzer --help
fi
