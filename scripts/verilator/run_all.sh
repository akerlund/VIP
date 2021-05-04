#!/bin/bash
export LC_ALL="en_US.UTF-8"

if [ "$#" -gt 0 ]; then
  git_root=$1
else
  git_root=$(git rev-parse --show-toplevel)
fi

cd $git_root/modules
echo $(pwd)
_v_paths=$(find -maxdepth 2 -name "verilator" -type d)

_e_total=0   # Total found errors
_e_modules=0 # Number of modules with errors
_verbosity=0 # Verbosity for print
_w_total=0   # Total found warnings, i.e., suggested waiver by Verilator

_fail=0

echo "--------------------------------------------------------------------------------"
echo "INFO [verilator] Verilating all modules"
echo "--------------------------------------------------------------------------------"

for _module in $_v_paths; do

  # Changing to each directory and calling "make lint" which runs verilator
  # whos output is stored in _vout.txt with all warnings and errors.
  cd $(dirname $_module)
  make verilate > _vout.txt 2>&1

  # We check the output file and print found errors
  if grep -q -w "^%Error" _vout.txt; then
    _e=$(grep -o "^%Error" _vout.txt | wc -l)
    _e_total=$(($_e_total + $_e))
    _e_modules=$(($_e_modules + 1))
    _fail="-1"

    if [ "$_verbosity" -gt 2 ]; then
      echo "--------------------------------------------------------------------------------"
      echo "ERROR [$(dirname $_module)] Found ($_e) errors"
      echo "--------------------------------------------------------------------------------"
      grep -w "^%Error" _vout.txt
    else
      echo "ERROR [$(dirname $_module)] Found ($_e) errors"
    fi

  # We check Verilator's output file
  else

    _file="rundir/verilator/all_waived.wv"
    if [ -f $_file ]; then

      if grep -q -w "No waivers needed - great!" $_file; then

        echo -e "INFO [$(dirname $_module)] No waivers needed - great!"
      else

        _fail="-1"
        _nr_of_lints=$(grep -o "lint_off" $_file | wc -l)
        _w_total=$(($_w_total + $_nr_of_lints))

        if [ "$_verbosity" -gt 2 ]; then
          echo -e "WARNING [$(dirname $_module)] Suggested waivers of ($_file)"
          cat rundir/verilator/all_waived.wv
        else
          echo -e "WARNING [$(dirname $_module)] Verilator suggest ($_nr_of_lints) waivers"
        fi

      fi
    else
      _fail="-1"
      echo -e "ERROR [$(dirname $_module)] A file with suggested waivers was not created!"
    fi
  fi

  rm _vout.txt
  cd $git_root/modules

done

echo "Found ($_e_total) errors in ($_e_modules) modules"
echo "Verilator suggested ($_w_total) waivers"

exit $_fail
