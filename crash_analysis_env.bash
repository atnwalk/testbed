export HISTORY_FILE=~/.filter_history

function next_input() {
  src_dir="${1}"
  export TARGET="${2}"
  if [[ $(find "${src_dir}" -maxdepth 1 -type f | wc -l) -eq 0 ]]; then
    echo "DONE"
    unset IN
    unset TARGET
    return
  fi
  export IN="${src_dir}/$(find "${src_dir}" -maxdepth 1 -type f | tail -n1 | awk '{print $NF}')"
  cat "${IN}"
  echo -e '\n\n\n\n--------------------------------------------------------------------------------\n\n\n'
  cat "${IN}" | "${TARGET}"
}


function filter_by_output() {
  src_dir="${1}"
  dest_dir="${2}"
  filter_str="${3}"
  mkdir -p "${dest_dir}"
  for f in $(find "${src_dir}"/ -maxdepth 1 -type f)
  do
    if cat "${f}" | "${TARGET}" 2>&1 | grep -q "${filter_str}"; then
      mv "${f}" "${dest_dir}/"
    fi
  done
  echo "cd \"$(pwd)\" && \\" >> "${HISTORY_FILE}"
  echo "filter_by_output '${src_dir}' '${dest_dir}' '${filter_str}'" >> "${HISTORY_FILE}"
  echo "" >> "${HISTORY_FILE}"
}


function filter_by_output_regex() {
  src_dir="${1}"
  dest_dir="${2}"
  filter_str="${3}"
  mkdir -p "${dest_dir}"
  for f in $(find "${src_dir}"/ -maxdepth 1 -type f)
  do
    if cat "${f}" | "${TARGET}" 2>&1 | grep -q -E "${filter_str}"; then
      mv "${f}" "${dest_dir}/"
    fi
  done
  echo "cd \"$(pwd)\" && \\" >> "${HISTORY_FILE}"
  echo "filter_by_output_regex '${src_dir}' '${dest_dir}' '${filter_str}'" >> "${HISTORY_FILE}"
  echo "" >> "${HISTORY_FILE}"
}


function filter_by_input() {
  src_dir="${1}"
  dest_dir="${2}"
  filter_str="${3}"
  mkdir -p "${dest_dir}"
  for f in $(find "${src_dir}"/ -maxdepth 1 -type f)
  do
    if cat "${f}" | grep -q "${filter_str}"; then
      mv "${f}" "${dest_dir}/"
    fi
  done
  echo "cd \"$(pwd)\" && \\" >> "${HISTORY_FILE}"
  echo "filter_by_input '${src_dir}' '${dest_dir}' '${filter_str}'" >> "${HISTORY_FILE}"
  echo "" >> "${HISTORY_FILE}"
}


function filter_by_input_regex() {
  src_dir="${1}"
  dest_dir="${2}"
  filter_str="${3}"
  mkdir -p "${dest_dir}"
  for f in $(find "${src_dir}"/ -maxdepth 1 -type f)
  do
    if cat "${f}" | grep -q -E "${filter_str}"; then
      mv "${f}" "${dest_dir}/"
    fi
  done
  echo "cd \"$(pwd)\" && \\" >> "${HISTORY_FILE}"
  echo "filter_by_input_regex '${src_dir}' '${dest_dir}' '${filter_str}'" >> "${HISTORY_FILE}"
  echo "" >> "${HISTORY_FILE}"
}


function filter_by_exit_code() {
  src_dir="${1}"
  dest_dir="${2}"
  exit_code="${3}"
  mkdir -p "${dest_dir}"
  for f in $(find "${src_dir}"/ -maxdepth 1 -type f)
  do
    cat "${f}" | "${TARGET}" >/dev/null 2>&1
    if [[ $? -eq ${exit_code} ]]; then
      mv "${f}" "${dest_dir}/"
    fi
  done
  echo "cd \"$(pwd)\" && \\" >> "${HISTORY_FILE}"
  echo "filter_by_exit_code '${src_dir}' '${dest_dir}' '${exit_code}'" >> "${HISTORY_FILE}"
  echo "" >> "${HISTORY_FILE}"
}
