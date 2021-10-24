#!/bin/bash
# VC Formal

if [ "$#" -lt 4 ]; then
  echo "ERROR: FPV run script missing input parameters"
else
  make_root=$1
  file_list=$2
  rundir=$3
  gui=$4
fi

mod_path=$(pwd)

echo "INFO [fpv] Sourcing files"
source $file_list

# Rundir
fpv_dir=$rundir/fpv
if [[ ! -d "$fpv_dir" ]]; then
  mkdir -p $fpv_dir
fi
cd $fpv_dir

echo "INFO [fpv] Creating file list"
echo "-sverilog "   > files.lst
echo $rtl_files    >> files.lst
echo $sva_files    >> files.lst
echo $rtl_dirs     >> files.lst
echo $sva_dirs     >> files.lst
echo "$(cat files.lst)"


echo "INFO [fpv] Copying FPV TCL file"
cp $mod_path/scripts/fpv.tcl $fpv_dir


# GUI (TODO)
# To use the SX license,      use vcf -verdi-sx
# To use Ultra license,       use vcf -verdi-ultra
# To use Verdi Base license,  use vcf -verdi-base
# To use Verdi Elite license, use vcf -verdi-elite
# To use Verdi Apex license,  use vcf -verdi-apex
if [ $gui -ge 1 ]; then
  gui="-verdi-sx"
else
  gui=""
fi
gui="-verdi-sx"

vcf -f fpv.tcl $gui

# VCF commands (TODO: Batch mode)
#check_fv –run_finish {report_fv –list > results.txt}
