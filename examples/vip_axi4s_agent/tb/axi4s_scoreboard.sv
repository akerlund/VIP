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

`uvm_analysis_imp_decl(_mst_port)
`uvm_analysis_imp_decl(_slv_port)

class axi4s_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi4s_scoreboard)

  // Master (Write) Agent
  uvm_analysis_imp_mst_port #(vip_axi4s_item #(VIP_AXI4S_CFG_C), axi4s_scoreboard) mst_port;
  uvm_analysis_imp_slv_port #(vip_axi4s_item #(VIP_AXI4S_CFG_C), axi4s_scoreboard) slv_port;

  // Storage for comparison
  vip_axi4s_item #(VIP_AXI4S_CFG_C) mst_items [$];
  vip_axi4s_item #(VIP_AXI4S_CFG_C) slv_items [$];
  // For raising objections
  uvm_phase current_phase;

  // Transaction counters
  int number_of_mst_items = 0;
  int number_of_slv_items = 0;

  // Test counters
  int number_of_compared    = 0;
  int number_of_passed      = 0;
  int number_of_failed      = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mst_port = new("mst_port", this);
    slv_port = new("slv_port", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void start_of_simulation_phase(uvm_phase phase);
    current_phase = phase;
    super.start_of_simulation_phase(phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    current_phase = phase;
    super.connect_phase(current_phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    current_phase = phase;
    super.run_phase(current_phase);
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void check_phase(uvm_phase phase);

    current_phase = phase;
    super.check_phase(current_phase);

    if (number_of_failed != 0) begin
      `uvm_error(get_name(), $sformatf("Test failed! (%0d) mismatches", number_of_failed))
    end
    else begin
      `uvm_info(get_name(), $sformatf("Test passed (%0d/%0d) finished transfers", number_of_passed, number_of_compared), UVM_LOW)
    end

  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void handle_reset();
    mst_items.delete();
    slv_items.delete();
  endfunction

  //----------------------------------------------------------------------------
  // Master Agent
  //----------------------------------------------------------------------------
  virtual function void write_mst_port(vip_axi4s_item #(VIP_AXI4S_CFG_C) trans);
    number_of_mst_items++;
    mst_items.push_back(trans);
  endfunction

  //----------------------------------------------------------------------------
  // Slave Agent
  //----------------------------------------------------------------------------
  virtual function void write_slv_port(vip_axi4s_item #(VIP_AXI4S_CFG_C) trans);
    number_of_slv_items++;
    slv_items.push_back(trans);
  endfunction

endclass
