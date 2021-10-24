#!/bin/bash
# Formal Coverage Analyzer

# Abort this script if command returns error
set -e
set -o pipefail

vcs_args+="-notice "   # Enables verbose diagnostic messages
vcs_args+="-licqueue " # Tells VCS MX to try for the license till it finds the license.
vcs_args+="-j8 "
vcs_args+="-ntb_opts uvm-1.2 "

if [ "$#" -lt 4 ]; then
  echo "ERROR: FCA run script missing input parameters"
else
  make_root=$1
  file_list=$2
  rundir=$3
  gui=$4
fi

mod_path=$(pwd)

echo "INFO [fca] Sourcing compile.sh"
source $file_list

# Rundir
fca_dir=$rundir/fca
if [[ ! -d "$fca_dir" ]]; then
  mkdir -p $fca_dir
fi
cd $fca_dir

echo "INFO [fca] Creating file list"
echo "-sverilog " > files.lst
echo $rtl_files   >> files.lst
echo $uvm_files   >> files.lst
echo $sva_files   >> files.lst
echo $rtl_dirs    >> files.lst
echo $uvm_dirs    >> files.lst
echo $sva_dirs    >> files.lst

echo "INFO [fca] Copying FCA TCL file"
cp $mod_path/scripts/fca.tcl $fca_dir

# GUI
if [ $gui -ge 1 ]; then
  gui="-verdi-sx"
else
  gui=""
fi

echo "INFO [fca] Creating simv.vdb by calling VCS"
vcs -f files.lst -cm line+cond+tgl+fsm -R $vcs_args

echo "INFO [fca] Starting Verdi with the FCA TCL file"
vcf -f fca.tcl $gui
