export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! test -d grammars; then
  git clone git@github.com:atnwalk/grammars.git
fi

