////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
// https://github.com/akerlund/VIP
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Description:
//
////////////////////////////////////////////////////////////////////////////////

class bch_base_test extends uvm_test;

  `uvm_component_utils(bch_base_test)

  uvm_table_printer uvm_table_printer0;
  report_server     report_server0;

  function new(string name = "bch_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(uvm_verbosity)::set(this, "*", "recording_detail", UVM_FULL);
    report_server0 = new("report_server0");
    uvm_report_server::set_server(report_server0);
    uvm_table_printer0                     = new();
    uvm_table_printer0.knobs.depth         = 3;
    uvm_table_printer0.knobs.default_radix = UVM_DEC;
  endfunction


  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction


  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask

endclass
