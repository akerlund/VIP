#!/bin/bash
################################################################################
##
## Copyright (C) 2021 Fredrik Åkerlund
## https://github.com/akerlund/VIP
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## Description:
##
################################################################################

set -e

xsct_junk_filter+="/^make\[[0-9]\+\]: Entering directory/,+2d;"
xsct_junk_filter+="/^make\[[0-9]\+\]: Leaving directory/,+2d;"
xsct_junk_filter+="/^make -C ps7_cortexa9_0/,+2d;"
xsct_junk_filter+="/^Running Make include in/,+0d;"
xsct_junk_filter+="/^Running Make libs in/,+0d;"
xsct_junk_filter+="/^$/d;"

if [ "$#" -lt 4 ]; then
  echo "ERROR: Vitis run script missing input parameters"
else
  make_root=$1
  rundir=$2
  compile_sh=$3
  mode=$4
fi

if [ "$mode" -eq 0 ]; then
  _mode="vitis_create"
elif [ "$mode" -eq 1 ]; then
  _mode="vitis_compile"
else
  _mode="fpga_upload"
fi

source $compile_sh

the_time=$(date +'%d_%m_%Y_%H_%M_%S')

xsct_dir=$rundir/xsct
if [[ ! -d "$xsct_dir" ]]; then
  mkdir -p $xsct_dir
fi

cd $xsct_dir
cp $make_root/scripts/xsct/xsct.tcl ./
inc_dirs=${inc_dirs//[$'\t\r\n']}

sed -i "s|RUNDIR|${xsct_dir}|g"             xsct.tcl
sed -i "s|VITIS_DIR|${VITIS_DIR}|g"         xsct.tcl
sed -i "s|JTAG_NAME|${JTAG_NAME}|g"         xsct.tcl
sed -i "s|PLATFORM_NAME|${PLATFORM_NAME}|g" xsct.tcl
sed -i "s|APP_NAME|${APP_NAME}|g"           xsct.tcl
sed -i "s|DOMAIN_NAME|${DOMAIN_NAME}|g"     xsct.tcl
sed -i "s|PROCESSOR|${PROCESSOR}|g"         xsct.tcl
sed -i "s|XSA_FILE|${XSA_FILE}|g"           xsct.tcl
sed -i "s|BIT_FILE|${BIT_FILE}|g"           xsct.tcl
sed -i "s|FSBL_FILE|${FSBL_FILE}|g"         xsct.tcl
sed -i "s|APP_ELF_FILE|${APP_ELF_FILE}|g"   xsct.tcl
sed -i "s|INC_DIR|${inc_dirs}|g"            xsct.tcl

if [ "$mode" -eq 0 ]; then
  _mode="vitis_create"
elif [ "$mode" -eq 1 ]; then
  _mode="vitis_compile"
else
  _mode="fpga_upload"
fi

start=`date +%s`
if [ -f "$xsct_dir/.metadata/.lock" ]; then
  rm $xsct_dir/.metadata/.lock
fi
xsct xsct.tcl $_mode | sed "$xsct_junk_filter"
echo "$!"
rm $xsct_dir/.metadata/.lock
end=`date +%s`
runtime=$((end-start))

echo -e "INFO [run_tools] Execution time: $(($runtime/3600))h $((($runtime/60)%60 ))m $(($runtime%60))s\n"
