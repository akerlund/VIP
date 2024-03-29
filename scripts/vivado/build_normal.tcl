puts "INFO \[flow\] Vivado running in:"
puts "[pwd]"


# ------------------------------------------------------------------------------
# Parameters from run.sh
# ------------------------------------------------------------------------------

set_param general.maxThreads _THREADS
set fpga_part  _FPGA_PART
set rtl_top    _RTL_TOP
set uvm_top    _UVM_TOP
set rpt_dir    _RPT_DIR
set parameters {_PARAMETERS}
set mode       _MODE
set run_mode   _RUN_TYPE
set defines    _DEFINES

file mkdir $rpt_dir

# ------------------------------------------------------------------------------
# Loading all files that were created in "scripts/vivado/run.sh"
# ------------------------------------------------------------------------------

puts "INFO \[flow\] Reading the RTL file list"
set rtl_file_list ./rtl_files.lst
set rtl_file_ref  [open $rtl_file_list r]
set rtl_file_data [read $rtl_file_ref]
close $rtl_file_ref
set rtl_files [split $rtl_file_data "\n"]

puts "INFO \[flow\] Reading the VHDL file list"
set vhdl_file_list ./vhdl_files.lst
set vhdl_file_ref  [open $vhdl_file_list r]
set vhdl_file_data [read $vhdl_file_ref]
close $vhdl_file_ref
set vhdl_files [split $vhdl_file_data "\n"]
# Remove empty entries
set vhdl_files [lsearch -all -inline -not -exact $vhdl_files {}]

puts "INFO \[flow\] Reading the RTL directories list"
set rtl_dir_list ./rtl_dirs.lst
set rtl_dir_ref  [open $rtl_dir_list r]
set rtl_dir [read $rtl_dir_ref]
close $rtl_dir_ref

puts "INFO \[flow\] Reading the UVM files list"
set uvm_file_list ./uvm_files.lst
set uvm_file_ref  [open $uvm_file_list r]
set uvm_file_data [read $uvm_file_ref]
close $uvm_file_ref
set uvm_files [split $uvm_file_data "\n"]

puts "INFO \[flow\] Reading the UVM directories list"
set uvm_dir_list ./uvm_dirs.lst
set uvm_dir_ref  [open $uvm_dir_list r]
set uvm_dir [read $uvm_dir_ref]
close $uvm_dir_ref

# ------------------------------------------------------------------------------
# Building the testbench only
# ------------------------------------------------------------------------------
if { [expr $run_mode == 0] } {


  if {[llength $vhdl_files]} {
    puts "INFO \[flow\] VHDL files found"
    set outfile [open "compile_list.txt" w];
    foreach f $vhdl_files { puts $outfile "$f" }
    close $outfile;
    puts "INFO \[xvhdl\] Parsing the compile list"
    exec xvhdl -f compile_list.txt
  } else {
    puts "INFO \[flow\] NO VHDL files found"
  }

  set outfile [open "compile_list.txt" w];

  # RTL directories
  puts "INFO \[flow\] RTL directories:"
  foreach row $rtl_dir {
    if { ![regexp {^$} $row] && ![regexp {^\s*#.*} $row] } {
      set inc [lindex [split $row "+"] 2]
      puts $outfile "-i $inc"
      puts "  $inc"
    }
  }

  # UVM directories
  puts "INFO \[flow\] UVM directories:"
  foreach row $uvm_dir {
    if { ![regexp {^$} $row] && ![regexp {^\s*#.*} $row] } {
      set inc [lindex [split $row "+"] 2]
      puts $outfile "-i $inc"
      puts "  $inc"
    }
  }

  foreach f $rtl_files { puts $outfile "$f" }
  foreach f $uvm_files { puts $outfile "$f" }

  close $outfile;

  puts "INFO \[xvlog\] Parsing the compile list"
  exec xvlog -sv -f compile_list.txt -L uvm

  puts "INFO \[xelab\] Elaborating the design"
  exec xelab $uvm_top --verbose 2 -debug all -s top -timescale 1ns/1ps

  puts "INFO \[flow\] Done!"
  quit
}

# ------------------------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------------------------

puts "INFO \[flow\] Reading the RTL files"
foreach row $rtl_files {
  if { ![regexp {^$} $row] && ![regexp {^\s*#.*} $row]} {
    read_verilog $row
    puts $row
  }
}

puts "INFO \[flow\] Override parameters of the top module"
set_property generic $parameters [current_fileset]

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] synth_design"
puts "--------------------------------------------------------------------------------\n"

read_xdc -mode out_of_context timing_constraints.xdc
synth_design -top $rtl_top -part $fpga_part -mode $mode -verilog_define $defines
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [get_ports clk]

write_checkpoint      -force $rpt_dir/post_synth.dcp
report_timing_summary -file  $rpt_dir/post_synth_timing_summary.rpt
report_utilization    -file  $rpt_dir/post_synth_util.rpt

if [expr $run_mode == 1] {
  puts "INFO \[flow\] Done!"
  quit
}

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] opt_design"
puts "--------------------------------------------------------------------------------\n"

opt_design

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] place_design"
puts "--------------------------------------------------------------------------------\n"

place_design

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] report_clock_utilization"
puts "--------------------------------------------------------------------------------\n"

report_clock_utilization -file $rpt_dir/clock_util.rpt
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
puts "Found setup timing violations => running physical optimization"
  phys_opt_design
}

write_checkpoint      -force $rpt_dir/post_place.dcp
report_utilization    -file  $rpt_dir/post_place_util.rpt
report_timing_summary -file  $rpt_dir/post_place_timing_summary.rpt

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] route_design"
puts "--------------------------------------------------------------------------------\n"

route_design
write_checkpoint      -force $rpt_dir/post_route.dcp

report_route_status   -file $rpt_dir/post_route_status.rpt
report_timing_summary -file $rpt_dir/post_route_timing_summary.rpt
report_power          -file $rpt_dir/post_route_power.rpt
report_drc            -file $rpt_dir/post_imp_drc.rpt

puts "\n--------------------------------------------------------------------------------"
puts "INFO \[flow\] write_bitstream"
puts "--------------------------------------------------------------------------------\n"

write_verilog   -force $rpt_dir/cpu_impl_netlist.v -mode timesim -sdf_anno true
write_bitstream -force $rpt_dir/cpu.bit

quit
