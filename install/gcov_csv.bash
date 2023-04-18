export SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SCRIPT_DIR}" && bash go.bash
source "${SCRIPT_DIR}"/env.bash

cd ~
if ! ~/go/bin/gcov-csv --help; then
  go install "${SCRIPT_DIR}"/../gcov-csv.go
  ~/go/bin/gcov-csv --help
fi
