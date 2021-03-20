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

class vip_axi4s_agent #(
  vip_axi4s_cfg_t CFG_P = '{default: '0}
  ) extends uvm_agent;

  protected virtual vip_axi4s_if #(CFG_P) vif;
  protected int                           id;

  vip_axi4s_monitor   #(CFG_P) monitor;
  vip_axi4s_driver    #(CFG_P) driver;
  vip_axi4s_sequencer #(CFG_P) sequencer;
  vip_axi4s_config    cfg;

  `uvm_component_param_utils_begin(vip_axi4s_agent #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
    `uvm_field_object(cfg, UVM_DEFAULT | UVM_REFERENCE)
  `uvm_component_utils_end;


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db #(virtual vip_axi4s_if #(CFG_P))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
    end

    if (!uvm_config_db #(vip_axi4s_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Agent has no config, creating a default config", UVM_LOW)
      cfg = vip_axi4s_config::type_id::create("default_config", this);
    end

    monitor      = vip_axi4s_monitor #(CFG_P)::type_id::create("monitor", this);
    monitor.cfg  = cfg;

    if (cfg.is_active == UVM_ACTIVE) begin
      driver     = vip_axi4s_driver #(CFG_P)::type_id::create("driver", this);
      driver.cfg = cfg;
      sequencer  = vip_axi4s_sequencer #(CFG_P)::type_id::create("sequencer", this);
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.rst_n);
      `uvm_info(get_name(), $sformatf("[rst_n] Calling reset handler"), UVM_LOW)
      passive_reset('0);
      handle_reset(phase);
      @(posedge vif.rst_n);
      passive_reset('1);
    end
 endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void handle_reset(uvm_phase phase);
    monitor.handle_reset();
    if (cfg.is_active == UVM_ACTIVE) begin
      driver.handle_reset();
      sequencer.handle_reset(phase);
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  task passive_reset(logic reset);
    if (cfg.is_active == UVM_PASSIVE && cfg.vip_axi4s_agent_type == VIP_AXI4S_SLAVE_AGENT_E) begin
      vif.tready <= '1;
    end
  endtask

endclass
