#!/bin/bash

# Abort this script if command returns error
set -e
set -o pipefail

rundir=$1
tc=$2
verbosity=$3
gui=$4

if [ $gui -eq 1 ]; then
  gui="-gui"
else
  gui="-R -onfinish quit"
fi

echo -e "\n--------------------------------------------------------------------------------"
echo -e "INFO [run_tools] Starting XSim"
echo -e "--------------------------------------------------------------------------------\n"

cd $rundir/vivado
xsim top -maxdeltaid 100000 -testplusarg UVM_TESTNAME=$tc -testplusarg  UVM_VERBOSITY=$verbosity $gui