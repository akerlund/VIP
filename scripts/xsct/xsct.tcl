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
#source /home/erland/workspace/dev/_ide/psinit/ps7_init.tcl

proc upload_to_fpga {_jtag_name _bit_file _xsa _vitis_dir _fsbl _app_elf_file} {

  puts "INFO \[FPGA\] Connect and reset"
  connect -url tcp:127.0.0.1:3121
  targets -set -nocase -filter {name =~"APU*"}
  rst -system
  puts "INFO \[FPGA\] Reset delay of 3 seconds"
  after 3000

  puts "INFO \[FPGA\] Uploading bitstream: $_bit_file"
  targets -set -filter {jtag_cable_name =~ "Digilent Arty Z7 003017A6FCE4A" && level==0 && jtag_device_ctx=="jsn-Arty Z7-003017A6FCE4A-23727093-0"}
  fpga -file $_bit_file

  puts "INFO \[FPGA\] Uploading XSA: $_xsa"
  targets -set -nocase -filter {name =~"APU*"}
  loadhw -hw $_xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
  configparams force-mem-access 1

  puts "INFO \[FPGA\] Uploading FSBL: $_fsbl"
  targets -set -nocase -filter {name =~ "*A9*#0"}
  rst -processor
  dow $_fsbl
  puts "INFO \[FPGA\] Run FSBL for 5 seconds"
  con
  after 5000
  stop

  #puts "INFO \[FPGA\] PS7 init"
  #targets -set -nocase -filter {name =~"APU*"}
  #ps7_init
  #puts "INFO \[FPGA\] PS7 post config"
  #ps7_post_config
  #targets -set -nocase -filter {name =~ "*A9*#0"}

  puts "INFO \[FPGA\] Uploading application: $_app_elf_file"
  targets -set -nocase -filter {name =~ "*A9*#0"}
  dow $_app_elf_file
  configparams force-mem-access 0
  con
}

if {[lindex $argv 0] == "vitis_create"} {

  puts "INFO \[Vitis\] Creating platform"
  platform create -name "$_platform_name" -hw $_xsa_file -proc $_proc -os standalone
  platform active $_platform_name
  platform generate -domains $_domain_name

  puts "INFO \[Vitis\] Creating domain"
  domain create -name "$_domain_name" -proc $_proc -os standalone
  domain active $_domain_name

  puts "INFO \[Vitis\] Creating application"
  app create -name "$_app_name" -lang c++ -template "Empty Application (C++)" -platform $_platform_name

  puts "INFO \[Vitis\] Importing sources"
  importsources   -name "$_app_name" INC_DIR -soft-link

  puts "INFO \[Vitis\] Building"
  app build -name $_app_name
}

if {[lindex $argv 0] == "vitis_compile"} {

  #platform active $_platform_name
  #platform -updatehw $_xsa_file
  puts "INFO \[Vitis\] Importing projects"
  importprojects -path RUNDIR
  puts "INFO \[Vitis\] Importing sources"
  importsources  -name "$_app_name" INC_DIR -soft-link -linker-script
  puts "INFO \[Vitis\] Building"
  app build -name $_app_name
}

if {[lindex $argv 0] == "fpga_upload"} {
  upload_to_fpga $_jtag_name $_bit_file $_xsa_file $_vitis_dir $_fsbl_file $_app_elf_file
}

