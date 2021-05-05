#!/bin/bash

# If any command returns an error, exit/abort
set -e
set -o pipefail

_rundir=$1
_tc=$2
_verbosity=$3
_gui=$4
_quiet=$5

testplusargs+="-testplusarg UVM_TESTNAME=$_tc "
testplusargs+="-testplusarg UVM_VERBOSITY=$_verbosity "

if [ $_gui -eq 1 ]; then
  _gui="-gui"
  testplusargs+="-testplusarg UVM_REPORT_NOCOLOR"
else
  _gui="-R -onfinish quit"
fi

if [ $_quiet -eq 1 ]; then
  exec 3>&1 &>/dev/null
else
  exec 3>&1
fi

_tc_label_size="32"
_color_red="$(tput setaf 1)"
_color_green="$(tput setaf 2)"
_color_def="$(tput sgr0)"
_run_str="\e[sRunning"          # Saves position before "Running": can delete later
_del_str="\e[u\e[K"             # Move back to the stored position: delete to end of line

echo -e "\n--------------------------------------------------------------------------------"
echo -e "INFO [run_tools] Starting XSim"
echo -e "--------------------------------------------------------------------------------\n"

cd $_rundir/vivado
printf "%-${_tc_label_size}s${_run_str}" $_tc >&3
t_sec=-$SECONDS

xsim top -maxdeltaid 100000 $testplusargs $_gui --log $_tc.log

t_sec=$((t + SECONDS))
t_str=$(date -d@$t_sec -u +%H:%M:%S)

_warning_cnt=$(sed -n -e 's/^UVM_WARNING\s*:\s*//p' $_tc.log)
_error_cnt=$(sed   -n -e 's/^UVM_ERROR\s*:\s*//p'   $_tc.log)
_fatal_cnt=$(sed   -n -e 's/^UVM_FATAL\s*:\s*//p'   $_tc.log)

if [[ $_error_cnt -gt 0 || $_fatal_cnt -gt 0 ]]; then
  _status="${_color_red}Failed${_color_def}"
else
  _status="${_color_green}Passed${_color_def}"
fi

# Append to XSim's log, this is used to check if a test failed by the summary_report script
printf "%-${_tc_label_size}s%s %s\n" $_tc $_status $t_str | tee -a $_tc.log

# In quiet mode, only the output status is printed to stdout
if [ $_quiet -eq 1 ]; then
  printf "${_del_str}%s | %8d | %6d | %8d | %s\n" $_status $_warning_cnt $_error_cnt $_fatal_cnt $t_str >&3
fi

# If not in quiet mode, throw an error if test fails
if [[ $_quiet -eq 0 && "$_status" =~ "Failed" ]]; then
  exit -1
fi
