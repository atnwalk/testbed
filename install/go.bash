export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}"/env.bash

if ! go version; then
  cd ~
  LATEST_GO_VERSION=$(git ls-remote --tags https://go.googlesource.com/go | grep -E 'refs/tags/go1\.[0-9][0-9]*\.[0-9][0-9]*$' | awk -F'refs/tags/go' '{print $2}' | python3 -c $'import sys\nprint(".".join(map(str, list(sorted([[int(x) for x in line.split(".")] for line in filter(None, sys.stdin.read().splitlines())]))[-1])))')
  wget https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
  test -d .go_install && rm -rf ~/.go_install
  mkdir -p .go_install
  tar -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz -C ~/.go_install
  rm -f go${LATEST_GO_VERSION}.linux-amd64.tar.gz
  echo 'if [[ "${PATH}" != *?(*:)"${HOME}"'"'"'/.go_install/go/bin'"'"'?(*:)* ]]; then export PATH="${HOME}/.go_install/go/bin:${PATH}"; fi' > ~/.go_install/env.bash
  source ~/.go_install/env.bash
  if ! grep -F -q '. "${HOME}"/.go_install/env.bash' "${HOME}/.bashrc"; then
    echo '. "${HOME}"/.go_install/env.bash' >> ~/.bashrc
  fi
  go version
  echo "To enable go in your shell exit and login or run: source ~/.go_install/env.bash"
fi

