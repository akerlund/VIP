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

class vip_axi4_agent #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_agent;

  protected virtual vip_axi4_if #(CFG_P) vif;
  protected int                          id;
  protected string                       _id_str;

  // For future features
  //axi4_monitor_callback            monitor_callback;
  //axi4_driver_callback             driver_callback;

  vip_axi4_monitor   #(CFG_P) monitor;
  vip_axi4_driver    #(CFG_P) driver;
  vip_axi4_sequencer #(CFG_P) sequencer;
  vip_axi4_config             cfg;

  `uvm_component_param_utils_begin(vip_axi4_agent #(CFG_P));
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

    if (!uvm_config_db #(virtual vip_axi4_if #(CFG_P))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"FATAL [AXI4] Virtual interface must be set for: ", get_full_name(), ".vif"});
    end

    if (!uvm_config_db #(vip_axi4_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_name(), "INFO [AXI4] Agent has no config, creating a default config", UVM_LOW)
      cfg = vip_axi4_config::type_id::create("default_config", this);
    end

    //monitor_callback = axi4_monitor_callback::type_id::create("monitor_callback", this);
    //driver_callback  = axi4_driver_callback::type_id::create("driver_callback", this);
    _id_str.itoa(id);
    monitor      = vip_axi4_monitor #(CFG_P)::type_id::create({"vip_axi4_monitor_", _id_str}, this);
    monitor.cfg  = cfg;

    if (cfg.is_active == UVM_ACTIVE) begin
      driver     = vip_axi4_driver #(CFG_P)::type_id::create({"vip_axi4_driver_", _id_str}, this);
      driver.cfg = cfg;
      sequencer  = vip_axi4_sequencer #(CFG_P)::type_id::create({"vip_axi4_sequencer_", _id_str}, this);
    end

    // Register callbacks to objects
    //uvm_callbacks #(axi4_driver  #(CFG_P),  axi4_driver_callback)::add(driver,  driver_callback);
    //uvm_callbacks #(axi4_monitor #(CFG_P), axi4_monitor_callback)::add(monitor, monitor_callback);

  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);

    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end

    if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E && cfg.is_active == UVM_ACTIVE) begin
      driver.wr_request_port.connect(monitor.wr_request_fifo.analysis_export);
      monitor.wr_response_port.connect(driver.wr_response_fifo.analysis_export);
      driver.rd_request_port.connect(monitor.rd_request_fifo.analysis_export);
      monitor.rd_response_port.connect(driver.rd_response_fifo.analysis_export);
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.rst_n);
      `uvm_info(get_name(), $sformatf("INFO [AXI4] Calling reset handler"), UVM_LOW)
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
    if (cfg.is_active == UVM_PASSIVE) begin
      if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E) begin
        vif.bready  <= reset;
        vif.rready  <= reset;
      end else begin
        vif.awready <= reset;
        vif.wready  <= reset;
        vif.arready <= reset;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // This function will set all data in the memory to zero
  // ---------------------------------------------------------------------------
  function void memory_reset();
    driver.memory_reset();
  endfunction

  // ---------------------------------------------------------------------------
  // This function will randomize all data in the memory
  // ---------------------------------------------------------------------------
  function void memory_randomize();
    driver.memory_randomize();
  endfunction

  // ---------------------------------------------------------------------------
  // Write an array of data (data) to the memory starting at some address (addr)
  // ---------------------------------------------------------------------------
  function void memory_write(
      logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] addr,
      logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] data[$]
    );
    driver.memory_write(addr, data);
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data for an index in the memory array
  // ---------------------------------------------------------------------------
  function logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] memory_read_index(longint index);
    return driver.memory_read_index(index);
  endfunction

endclass
