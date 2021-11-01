#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

rtl_top="bch_tb_top"
uvm_top="bch_tb_top"

source $git_root/bool/files.lst
source $git_root/report_server/files.lst
source $git_root/vip_bch/files.lst

source ./tb/files.lst
