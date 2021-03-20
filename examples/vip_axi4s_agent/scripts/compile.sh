#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

# Specify the top files
rtl_top="dummy"
uvm_top="axi4s_tb_top"

# Specify other file lists
source $git_root/vip_axi4s_agent/files.lst
source $git_root/vip_clk_rst_agent/files.lst
source $git_root/report_server/files.lst

# Source the module's file lists
source ./rtl/files.lst
source ./tb/files.lst

# Parameters
