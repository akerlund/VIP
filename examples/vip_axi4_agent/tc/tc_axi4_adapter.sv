////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
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

class tc_axi4_adapter extends axi4_base_test;

  `uvm_component_utils(tc_axi4_adapter)

  logic [63 : 0] configuration;

  function new(string name = "tc_axi4_adapter", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_mem_cfg0.mem_addr_width = VIP_AXI4_MEM_SIZE_4KB_E;
  endfunction


  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    phase.raise_objection(this);

    // Write and read
    configuration = $urandom_range(2**31, 0);
    reg_model.axi4.configuration.write(uvm_status, configuration);
    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("Wrote %0d", configuration), UVM_LOW)
    `uvm_info(get_name(), $sformatf("Read  %0d", value), UVM_LOW)

    // Reset and read
    reset_seq0.start(v_sqr.clk_rst_sequencer0);
    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("Read  %0d", value), UVM_LOW)

    // Write and read
    configuration = $urandom_range(2**31, 0);
    reg_model.axi4.configuration.write(uvm_status, configuration);
    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("Wrote %0d", configuration), UVM_LOW)
    `uvm_info(get_name(), $sformatf("Read  %0d", value), UVM_LOW)

    #200ns;

    phase.drop_objection(this);

  endtask

endclass