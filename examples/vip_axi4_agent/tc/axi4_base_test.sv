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

class axi4_base_test extends uvm_test;

  `uvm_component_utils(axi4_base_test)

  // ---------------------------------------------------------------------------
  // UVM variables
  // ---------------------------------------------------------------------------

  uvm_table_printer uvm_table_printer0;
  report_server     report_server0;

  // ---------------------------------------------------------------------------
  // Testbench variables
  // ---------------------------------------------------------------------------

  axi4_env               tb_env;
  axi4_virtual_sequencer v_sqr;
  register_model         reg_model;
  uvm_status_e           uvm_status;
  uvm_reg_data_t         value;
  real                   memory_size;

  // ---------------------------------------------------------------------------
  // VIP Agent configurations
  // ---------------------------------------------------------------------------

  clk_rst_config  clk_rst_config0;
  vip_axi4_config axi4_wr_cfg0;
  vip_axi4_config axi4_rd_cfg0;
  vip_axi4_config axi4_mem_cfg0;
  vip_axi4_config axi4_rd_cfg1;
  vip_axi4_config axi4_rd_cfg2;

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------

  reset_sequence                          reset_seq0;
  vip_axi4_write_seq    #(VIP_AXI4_CFG_C) vip_axi4_write_seq0;
  vip_axi4_read_seq     #(VIP_AXI4_CFG_C) vip_axi4_read_seq0;
  vip_axi4_response_seq #(VIP_AXI4_CFG_C) vip_axi4_response_seq0;

  function new(string name = "axi4_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    // UVM
    uvm_config_db #(uvm_verbosity)::set(this, "*", "recording_detail", UVM_FULL);

    report_server0 = new("report_server0");
    uvm_report_server::set_server(report_server0);

    uvm_table_printer0                     = new();
    uvm_table_printer0.knobs.depth         = 3;
    uvm_table_printer0.knobs.default_radix = UVM_DEC;

    // Environment
    tb_env = axi4_env::type_id::create("tb_env", this);

    // Configurations
    clk_rst_config0 = clk_rst_config::type_id::create("clk_rst_config0", this);
    axi4_wr_cfg0    = vip_axi4_config::type_id::create("axi4_wr_cfg0",   this);
    axi4_rd_cfg0    = vip_axi4_config::type_id::create("axi4_rd_cfg0",   this);
    axi4_mem_cfg0   = vip_axi4_config::type_id::create("axi4_mem_cfg0",  this);
    axi4_rd_cfg1    = vip_axi4_config::type_id::create("axi4_rd_cfg1",   this);
    axi4_rd_cfg2    = vip_axi4_config::type_id::create("axi4_rd_cfg2",   this);

    axi4_wr_cfg0.min_wvalid_delay_period = 10;
    axi4_wr_cfg0.max_wvalid_delay_period = 10;

    axi4_mem_cfg0.vip_axi4_agent_type     = VIP_AXI4_SLAVE_AGENT_E;
    axi4_mem_cfg0.mem_slave               = TRUE;
    axi4_mem_cfg0.min_wready_delay_period = 8;
    axi4_mem_cfg0.max_wready_delay_period = 8;
    axi4_mem_cfg0.min_rvalid_delay_period = 8;
    axi4_mem_cfg0.max_rvalid_delay_period = 8;

    axi4_rd_cfg0.min_rready_delay_period = 10;
    axi4_rd_cfg0.max_rready_delay_period = 10;

    axi4_rd_cfg1.vip_axi4_agent_type = VIP_AXI4_SLAVE_AGENT_E;
    axi4_rd_cfg1.monitor_merge_reads = FALSE;
    axi4_rd_cfg2.vip_axi4_agent_type = VIP_AXI4_MASTER_AGENT_E;
    axi4_rd_cfg2.is_active           = UVM_PASSIVE;
    axi4_rd_cfg2.monitor_merge_reads = FALSE;

    uvm_config_db #(clk_rst_config)::set(this,  {"tb_env.clk_rst_agent0", "*"}, "cfg", clk_rst_config0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.wr_agent0",      "*"}, "cfg", axi4_wr_cfg0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.rd_agent0",      "*"}, "cfg", axi4_rd_cfg0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.mem_agent0",     "*"}, "cfg", axi4_mem_cfg0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.scoreboard0",    "*"}, "cfg", axi4_mem_cfg0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.rd_agent1",      "*"}, "cfg", axi4_rd_cfg1);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.rd_agent2",      "*"}, "cfg", axi4_rd_cfg2);

  endfunction


  function void end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    if (!uvm_config_db #(register_model)::get(null, "*", "reg_model", reg_model)) begin
      `uvm_fatal("NOREG", "No registered register model in the factory")
    end

    v_sqr = tb_env.virtual_sequencer;

    `uvm_info(get_type_name(), $sformatf("Topology of the test:\n%s", this.sprint(uvm_table_printer0)), UVM_LOW)

    `uvm_info(get_name(), {"VIP AXI4 Agent (Write):\n",  axi4_wr_cfg0.sprint()},  UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Read0):\n",  axi4_rd_cfg0.sprint()},  UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Memory):\n", axi4_mem_cfg0.sprint()}, UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Read1):\n",  axi4_rd_cfg1.sprint()},  UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Read2):\n",  axi4_rd_cfg2.sprint()},  UVM_LOW)

  endfunction


  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    reset_seq0             = reset_sequence::type_id::create("reset_seq0");
    vip_axi4_write_seq0    = vip_axi4_write_seq#(VIP_AXI4_CFG_C)::type_id::create("vip_axi4_write_seq0");
    vip_axi4_read_seq0     = vip_axi4_read_seq#(VIP_AXI4_CFG_C)::type_id::create("vip_axi4_read_seq0");
    vip_axi4_response_seq0 = vip_axi4_response_seq#(VIP_AXI4_CFG_C)::type_id::create("vip_axi4_response_seq0");
  endfunction


  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    clk_delay(32);
    reset_seq0.start(v_sqr.clk_rst_sequencer0);
    phase.drop_objection(this);
  endtask


  task clk_delay(int delay);
    #(delay*clk_rst_config0.clock_period);
  endtask

endclass
