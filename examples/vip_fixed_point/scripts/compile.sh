#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

rtl_top="fixed_point_tb_top"
uvm_top="fixed_point_tb_top"

source $git_root/bool/files.lst
source $git_root/vip_fixed_point/files.lst

source ./tb/files.lst
