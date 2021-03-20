#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

# Specify the top files
rtl_top="axi4_axi_slave"
uvm_top="axi4_tb_top"

# Specify other file lists
source $git_root/bool/files.lst
source $git_root/vip_axi4_agent/files.lst
source $git_root/vip_clk_rst_agent/files.lst
source $git_root/report_server/files.lst

# Source the module's file lists
source ./rtl/files.lst
source ./tb/files.lst

# Parameters
