data_args=""
for fuzzer in {atnwalk,nautilus,gramatron}
do
  for program in {jerry,lua,mruby,php,sqlite3}
  do
    data_args="${data_args} --data ${fuzzer} ${program} summary/${fuzzer}.${program}.summary.csv"
  done
done
python3 statistical_tests.py ${data_args}