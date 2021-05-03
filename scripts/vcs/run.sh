#!/bin/bash

set -e
set -o pipefail

git_root=$(git rev-parse --show-toplevel)
script_dir=$(dirname $0)

if [ "$#" -lt 3 ]; then
  echo "ERROR [vcs] run script missing input parameters"
else
  file_list=$1
  rundir=$2
  cov_en=$3
fi

function pretty_print {
  echo -e "\n--------------------------------------------------------------------------------\n"
  echo $1
  echo -e "\n--------------------------------------------------------------------------------\n"
}

function check_status {
  status=$1
  msg=$2
  if [ $status -ne 0 ]; then
    echo -e $msg
    exit $status
  fi
}

source $script_dir/vlogan_args.sh
source $script_dir/vcs_args.sh

vlogan_junk_filter+="/^$/d;"                                     # Empty lines
vlogan_junk_filter+="/Package previously wildcard imported/,+5d" # Package multiple wildcard import note
SECONDS=0

if [ $cov_en -eq 1 ]; then
  vcs_args+="-cm line+cond+fsm -cm_hier ../scripts/cov_cfg.txt"
fi

echo "$file_list"
source $file_list

if [ ! -e $rundir ]; then
  mkdir $rundir
  cd $rundir
  pretty_print "INFO [vlogan] Analyzing UVM"
  vlogan $vlogan_args
  check_status $? "ERROR [vlogan] Analysing failed, returned ("$status")\n"
else
  cd $rundir
fi

pretty_print "INFO [vlogan] Analyzing source files"
vlogan $vlogan_args $rtl_dirs $rtl_files | sed "$vlogan_junk_filter"
check_status $? "ERROR [vlogan] Analysing failed, returned ("$status")\n"

if [ ! -z "$uvm_dirs" ]; then
  pretty_print "INFO [vlogan] Analyzing testbench files"
  vlogan $vlogan_args $uvm_dirs $uvm_files | sed "$vlogan_junk_filter"
  check_status $? "ERROR [vlogan] Analysing failed, returned ("$status")\n"
fi

pretty_print "INFO [vcs] Elaborating $uvm_top with VCS"
vcs $vcs_args $uvm_top
check_status $? "ERROR [vcs] Elaboration failed, returned ("$status")\n"

duration=$SECONDS
echo "INFO [run] Finished: $(($duration / 60)) minutes, $(($duration % 60)) seconds elapsed."
