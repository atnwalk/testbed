for fuzzer in {atnwalk,gramatron,nautilus};
do
  for program in {jerry,lua,mruby,php,sqlite3};
  do
    y_max=$(tail -n1 -q ./summary/*".${program}".*.coverage.normalized.csv | cut -d',' -f4 | sort -n | tail -n1)
    python3 plot_iqr_over_time.py --column 'branches_covered' --y-max "${y_max}" --y-label 'Covered Branches' --out "graphs/${fuzzer}.${program}.branches.plot.pdf" ./summary/"${fuzzer}.${program}".*.coverage.normalized.csv
  done
done
