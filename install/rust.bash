export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}"/env.bash

if ! rustup --version || ! cargo version; then
  cd ~
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
  sh rustup.sh --default-toolchain nightly -y -q
  source "${HOME}/.cargo/env"
  rm -f rustup.sh
  rustup --version
  cargo version
  echo "To enable rustup and cargo in your shell exit and login or run: source "~/.cargo/env""
fi

