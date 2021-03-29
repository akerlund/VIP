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

# Check input paramters
if [ "$#" -lt 2 ]; then
  echo "ERROR: Verilator run script missing input parameters"
else
  file_list=$1
  rundir=$2
fi

# Locate configuration and waiver file
module_path=$(pwd)
v_config=$module_path/verilator/configuration.vlt
v_waiver=$module_path/verilator/waiver.wv

# Source module file list
git_root=$(git rev-parse --show-toplevel)
source $file_list
echo $file_list
echo $rtl_files

################################################################################
# Verilator variables
################################################################################
# Common flags
verilator_flags+="-cc --exe "                     # Generate C++ in executable form
verilator_flags+="-Os -x-assign 0 "               # Optimize
verilator_flags+="-sv "                           # Enable SystemVerilog parsing
verilator_flags+="--assert "                      # Check SystemVerilog assertions
verilator_flags+="--lint-only "                   # Lint, but do not make output
verilator_flags+="--stats "
verilator_flags+="-Wno-fatal "                    # Disable fatal exit on warnings
verilator_flags+="-Wno-fatal "                    # Disable fatal exit on warnings
verilator_flags+="--waiver-output all_waived.wv " # Write a waiver template
#verilator_flags+="-MMD "                         # Generate makefile dependencies (not shown as complicates the Makefile)
#verilator_flags+="-Wall "                        # Warn abount lint issues; may not want this on less solid designs
#verilator_flags+="--trace "                      # Make waveforms
#verilator_flags+="--quiet-exit "                 # Don't print the command on failure
#verilator_flags+="--clk clk "                    # Define the clock port
#verilator_flags+="--coverage "                   # Generate coverage analysis
#verilator_flags+="--debug "                      # Run Verilator in debug mode
#verilator_flags+="--gdbbt "                      # Add this trace to get a backtrace in gdb

echo ""
echo "--------------------------------------------------------------------------------"
echo "INFO [run_verilator] Starting Verilator"
echo "--------------------------------------------------------------------------------"
echo ""

# Create rundir if needed and analyze source code
ver_dir=$rundir/verilator
if [ ! -e $ver_dir ]; then
  mkdir -p $ver_dir
  echo "INFO [run_verilator] Created run directory: $ver_dir"
fi

cd $ver_dir

# Use a wrapper? We do this becuase some modules use SV interfaces
if [ -n "$rtl_wrapper" ]; then
  rtl_top=$rtl_wrapper
  src_paths="$wrp_path $src_paths"
fi

# Submodule waivers?
if [ -n "$v_sub_waivers" ]; then
  v_waiver="$v_waiver $v_sub_waivers"
fi


for p in ${parameters[@]}; do
  verilator_params+="-pvalue+$p "
done

verilator $verilator_flags $v_config $v_waiver --top-module $rtl_top $verilator_params $rtl_files $rtl_dirs
_file="$rundir/verilator/all_waived.wv"
if [ -f $_file ]; then
  if grep -q -w "No waivers needed - great!" $_file; then
    echo -e "\nINFO [run_verilator] No waivers needed - great!\n"
  else
    echo -e "\nINFO [run_verilator] Suggested waivers of ($_file):\n"
    cat $rundir/verilator/all_waived.wv
  fi

else
  echo -e "\nERROR [run_verilator] A file with suggested waivers was not created!"
fi
