export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! fossil version; then
  FOSSIL_TAR=$(curl https://fossil-scm.org/home/juvlist 2>/dev/null | python3 -c$'import sys, json\nversions = json.loads(sys.stdin.read())\nprint(sorted(list(filter(lambda x: x["name"].startswith("fossil-linux-x64-"), versions)), key=lambda y: y["name"])[-1]["name"])\n')
  wget https://fossil-scm.org/home/uv/"${FOSSIL_TAR}"
  test -d ~/.fossil_install && chmod -R +w ~/.fossil_install/ && rm -rf ~/.fossil_install
  mkdir -p .fossil_install/fossil/bin
  tar -xzf "${FOSSIL_TAR}" -C ~/.fossil_install/fossil/bin
  rm -f "${FOSSIL_TAR}"
  echo 'if [[ "${PATH}" != *?(*:)"${HOME}"'"'"'/.fossil_install/fossil/bin'"'"'?(*:)* ]]; then export PATH="${HOME}/.fossil_install/fossil/bin:${PATH}"; fi' > ~/.fossil_install/env.bash
  source ~/.fossil_install/env.bash
  if ! grep -F -q '. "${HOME}"/.fossil_install/env.bash' "${HOME}/.bashrc"; then
    echo '. "${HOME}"/.fossil_install/env.bash' >> ~/.bashrc
  fi
  fossil version
  echo "To enable fossil in your shell exit and login or run: source ~/.fossil_install/env.bash"
fi
