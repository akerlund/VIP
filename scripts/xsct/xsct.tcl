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

set _run_dir       RUNDIR
set _vitis_dir     VITIS_DIR
set _jtag_name     JTAG_NAME

set _platform_name PLATFORM_NAME
set _app_name      APP_NAME
set _domain_name   DOMAIN_NAME
set _proc          PROCESSOR

set _xsa_file      XSA_FILE
set _bit_file      BIT_FILE
set _fsbl_file     FSBL_FILE
set _app_elf_file  APP_ELF_FILE

set _src_dir       "SRC_DIR"
set _inc_dir       "INC_DIR"

setws RUNDIR
source $_vitis_dir/scripts/vitis/util/zynqmp_utils.tcl

proc upload_to_fpga {_jtag_name _bitstream _xsa _fsbl _app_name} {

  reset_cpu
  after 3000

  # Set current target to entry single entry in list.
  targets -set -filter {jtag_cable_name =~ $_jtag_name && level==0} -index 0
  fpga -file $_bitstream

  targets -set -nocase -filter {name =~"APU*"}
  loadhw -hw $_xsa -mem-ranges [list {0x80000000 0xbfffffff} {0x400000000 0x5ffffffff} {0x1000000000 0x7fffffffff}]
  configparams force-mem-access 1

  targets -set -nocase -filter {name =~"APU*"}
  set mode [expr [mrd -value 0xFF5E0200] & 0xf]

  targets -set -nocase -filter {name =~ "*A9*#0"}
  rst -processor

  # Download ELF and binary file to target
  dow $_fsbl

  # Resume active target.
  con -block -timeout 60

  # Processor Reset
  targets -set -nocase -filter {name =~ "*A9*#0"}
  rst -processor

  # Download application to target
  dow $_app_name
  configparams force-mem-access 0

  # execute apllication
  con
}

if {[lindex $argv 0] == "vitis_create"} {

  platform create -name "$_platform_name" -hw $_xsa_file -proc $_proc -os standalone
  platform active $_platform_name

  domain   create -name "$_domain_name" -proc $_proc -os standalone
  domain   active $_domain_name
  platform generate -domains $_domain_name
  app      create -name "$_app_name" -lang c++ -template "Empty Application (C++)" -platform $_platform_name

  importsources   -name "$_app_name" INC_DIR -soft-link
  app build -name $_app_name
  build_app       $_app_name
}

if {[lindex $argv 0] == "vitis_compile"} {
  importprojects -path RUNDIR
  importsources  -name $_app_name INC_DIR -soft-link
  app build      -name $_app_name
  build_app      $_app_name
}

if {[lindex $argv 0] == "fpga_upload"} {
  puts "INFO \[FPGA\] Upload not tested yet"
  #upload_to_fpga $_jtag_name $_bitstream $_xsa $_fsbl $_app_name
}

