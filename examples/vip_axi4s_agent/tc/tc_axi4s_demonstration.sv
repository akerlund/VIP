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

class tc_axi4s_demonstration extends axi4s_base_test;

  `uvm_component_utils(tc_axi4s_demonstration)


  function new(string name = "tc_axi4s_demonstration", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction


  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    phase.raise_objection(this);

    vip_axi4s_seq0.set_burst_delay_enabled(TRUE);
    vip_axi4s_seq0.set_burst_delay_min(32);
    vip_axi4s_seq0.set_burst_delay_max(32);
    vip_axi4s_seq0.set_clock_period(clk_rst_config0.clock_period);

    vip_axi4s_seq0.set_nr_of_bursts(4);

    vip_axi4s_seq0.set_data_type(VIP_AXI4S_TDATA_COUNTER_E);
    vip_axi4s_seq0.set_burst_length(16);
    vip_axi4s_seq0.set_tstrb(VIP_AXI4S_TSTRB_ALL_E);
    vip_axi4s_seq0.start(v_sqr.mst_sequencer);

    vip_axi4s_seq0.set_data_type(VIP_AXI4S_TDATA_COUNTER_E);
    vip_axi4s_seq0.set_burst_length(8);
    vip_axi4s_seq0.set_tstrb(VIP_AXI4S_TSTRB_ALL_E);
    vip_axi4s_seq0.start(v_sqr.mst_sequencer);

    vip_axi4s_seq0.set_data_type(VIP_AXI4S_TDATA_COUNTER_E);
    vip_axi4s_seq0.set_burst_length(4);
    vip_axi4s_seq0.set_tstrb(VIP_AXI4S_TSTRB_ALL_E);
    vip_axi4s_seq0.start(v_sqr.mst_sequencer);

    `uvm_info(get_name(), $sformatf("Done!"), UVM_LOW)
    phase.drop_objection(this);

  endtask


endclass
