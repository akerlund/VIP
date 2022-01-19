#!/bin/bash
################################################################################
##
## Copyright (C) 2021 Fredrik Åkerlund
## https:##github.com/akerlund/VIP
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
## along with this program.  If not, see <https:##www.gnu.org/licenses/>.
##
## Description:
##
################################################################################

# ------------------------------------------------------------------------------
# Input parameters
# ------------------------------------------------------------------------------

if [ "$#" -lt 5 ]; then
  echo "ERROR: Vivado run script missing input parameters"
else
  make_root=$1
  file_list=$2
  rundir=$3
  viv_run=$4
  viv_ooc=$5
  usecase=$6
fi

echo "INFO [run_tools] make_root = $make_root"
echo "INFO [run_tools] Sourcing files"
source $file_list

# ------------------------------------------------------------------------------
# FPGA parameters
# ------------------------------------------------------------------------------

# Default FPGA part
if [ -z "${FPGA_PART+_null}" ]; then
  echo "WARNING [run_tools] Using default FPGA part"
  FPGA_PART="7z020clg484-1"
fi

# Default max threads
if [ -z ${VIV_THREADS+_null} ]; then
  echo "WARNING [run_tools] Using default threads (8)"
  VIV_THREADS=8
fi

# Default clock period
if [ -z ${FCLK_T+_null} ]; then
  echo "WARNING [run_tools] Using default clock period (8.0)"
  FCLK_T="8.0"
fi

# Rundir
viv_dir=$rundir/vivado
if [[ ! -d "$viv_dir" ]]; then
  mkdir -p $viv_dir
fi

DEFINES=__NOTHING__
if [ ! -z "$usecase" ]; then
  DEFINES=${usecase}
fi

# ------------------------------------------------------------------------------
# Setting parameters in the TCL files
# ------------------------------------------------------------------------------
echo "INFO [run_tools] Setting parameters"
cd   $viv_dir
echo $rtl_dirs   > rtl_dirs.lst
echo $rtl_files  > rtl_files.lst
echo $vhdl_files > vhdl_files.lst
echo $uvm_files  > uvm_files.lst
echo $uvm_dirs   > uvm_dirs.lst
cp   $make_root/scripts/vivado/build_normal.tcl ./
cp   $make_root/scripts/vivado/start_vivado_notrace.tcl ./
cp   $make_root/scripts/vivado/timing_constraints.xdc ./

for p in ${parameters[@]}; do
  vivado_params+="$p "
done

sed -i "s|_FCLK_T|${FCLK_T}|g"            timing_constraints.xdc
sed -i "s|_FWAVE|${FWAVE}|g"              timing_constraints.xdc
sed -i "s|_DEFINES|${DEFINES}|g"          build_normal.tcl
sed -i "s|_THREADS|${VIV_THREADS}|g"      build_normal.tcl
sed -i "s|_FPGA_PART|${FPGA_PART}|g"      build_normal.tcl
sed -i "s|_RTL_TOP|${rtl_top}|g"          build_normal.tcl
sed -i "s|_UVM_TOP|${uvm_top}|g"          build_normal.tcl
sed -i "s|_RPT_DIR|reports|g"             build_normal.tcl
sed -i "s|_PARAMETERS|${vivado_params}|g" build_normal.tcl
if [ $viv_ooc -ge 1 ]; then
  sed -i "s|_MODE|out_of_context|g"       build_normal.tcl
else
  sed -i "s|_MODE|default|g"              build_normal.tcl
fi
if [ $viv_run -ge 1 ]; then
  sed -i "s|_RUN_TYPE|1|g"                build_normal.tcl
else
  sed -i "s|_RUN_TYPE|0|g"                build_normal.tcl
fi

# Save the start time
start=`date +%s`

echo -e "\n--------------------------------------------------------------------------------"
echo -e "INFO [run_tools] Starting Vivado"
echo -e "--------------------------------------------------------------------------------\n"

export LC_ALL="en_US.UTF-8"
vivado -source start_vivado_notrace.tcl -mode batch

# Print utilization report if successful
status=$?
if [ $status -ne 0 ]; then
  echo "ERROR [run_tools] Vivado failed"
else

  if [ "$viv_run" -ge 1 ]; then
    echo -e "\n--------------------------------------------------------------------------------"
    echo -e "INFO [run_tools] post_synth_util.rpt"
    echo -e "--------------------------------------------------------------------------------\n"
    echo -e ""
    sed -n '/^+-/,/^* Warning/p;/^* Warning/q' $viv_dir/reports/post_synth_util.rpt
    grep ^"Synthesis finished" $viv_dir/vivado.log || echo "ERROR [run_tools] Synthesis did not finish"
    python3 $make_root/scripts/vivado/post_run.py -d $viv_dir $viv_waiver
    status=$?
  fi
fi


# Print the runtime
end=`date +%s`
runtime=$((end-start))
echo -e "INFO [run_tools] Execution time: $(($runtime/3600))h $((($runtime/60)%60 ))m $(($runtime%60))s\n"
exit $status
