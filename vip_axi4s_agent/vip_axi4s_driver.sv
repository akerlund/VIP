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

class vip_axi4s_driver #(
  vip_axi4s_cfg_t CFG_P = '{default: '0}
  ) extends uvm_driver #(vip_axi4s_item #(CFG_P));

  protected virtual vip_axi4s_if #(CFG_P) vif;
  protected int    id;
  vip_axi4s_config cfg;


  `uvm_component_param_utils_begin(vip_axi4s_driver #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
  `uvm_component_utils_end

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
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
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);

    fork
      reset_vif();
    join_none

    forever begin
      @(posedge vif.rst_n);
      fork
        driver_start();
      join_none
      @(negedge vif.rst_n);
      disable fork;
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  task driver_start();
    if (cfg.vip_axi4s_agent_type == VIP_AXI4S_MASTER_AGENT_E) begin
      fork
        master_drive();
      join
    end else begin
      fork
        slave_drive();
      join
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void handle_reset();
  endfunction

  // ---------------------------------------------------------------------------
  // Reset VIF
  // ---------------------------------------------------------------------------
  protected task reset_vif();

    if (cfg.vip_axi4s_agent_type == VIP_AXI4S_MASTER_AGENT_E) begin
      forever begin
        @(negedge vif.rst_n);
        vif.tvalid <= '0;
        vif.tdata  <= '0;
        vif.tstrb  <= '0;
        vif.tkeep  <= '0;
        vif.tlast  <= '0;
        vif.tid    <= '0;
        vif.tdest  <= '0;
        vif.tuser  <= '0;
      end
    end else begin
      forever begin
        @(negedge vif.rst_n);
        vif.tready <= '0;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task master_drive();
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      drive_axi4s_item();
      seq_item_port.item_done();
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task drive_axi4s_item();

    int beat_counter = 0;
    int burst_length = req.tdata.size();

    vif.tlast <= '0;
    vif.tid   <= req.tid;
    vif.tdest <= req.tdest;

    if (cfg.tvalid_delay_enabled) begin
      fork
        begin
          drive_tvalid();
        end
      join_none
    end else begin
      vif.tvalid <= '1;
    end

    while (beat_counter != burst_length) begin

      vif.tdata <= req.tdata[beat_counter];
      vif.tstrb <= req.tstrb[beat_counter];
      vif.tkeep <= req.tkeep[beat_counter];
      vif.tuser <= req.tuser[beat_counter];

      beat_counter++;

      if (beat_counter == burst_length) begin
        vif.tlast <= '1;
      end

      @(posedge vif.clk);
      while (!(vif.tvalid === '1 && vif.tready === '1)) begin
        @(posedge vif.clk);
      end

      if (beat_counter == burst_length) begin
        if (cfg.tvalid_delay_enabled) begin
          vif.tvalid <= '0;
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task drive_tvalid();

    int clock_counter       = 0;
    int tvalid_delay_time   = 0;
    int tvalid_delay_period = $urandom_range(cfg.max_tvalid_delay_period, cfg.min_tvalid_delay_period);

    vif.tvalid <= '1;

    while (1) begin

      @(posedge vif.clk);
      if (vif.tvalid === '1 && vif.tready === '1 && vif.tlast === '1) begin
        @(posedge vif.clk);
        vif.tvalid <= '0;
        break;
      end

      clock_counter++;

      if (clock_counter >= tvalid_delay_period &&
          vif.tvalid === '1 && vif.tready === '1) begin
        vif.tvalid         <= '0;
        clock_counter       = 0;
        tvalid_delay_time   = $urandom_range(cfg.max_tvalid_delay_time,   cfg.min_tvalid_delay_time);
        tvalid_delay_period = $urandom_range(cfg.max_tvalid_delay_period, cfg.min_tvalid_delay_period);
        `uvm_info(get_name(), $sformatf("De-asserting 'tvalid' for (%0d) clock periods", tvalid_delay_time), UVM_HIGH)
        repeat (tvalid_delay_time) @(posedge vif.clk);
      end
      else begin
        vif.tvalid <= '1;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task slave_drive();
    drive_tready();
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task drive_tready;

    int clock_counter       = 0;
    int tready_delay_time   = 0;
    int tready_delay_period = $urandom_range(cfg.max_tready_delay_period, cfg.min_tready_delay_period);

    if (!cfg.tready_delay_enabled) begin
      vif.tready <= '1;
      return;
    end

    forever begin

      vif.tready <= '1;
      @(posedge vif.clk);

      while (!(vif.tvalid === '1 && vif.tlast === '1)) begin

        clock_counter++;
        if ((clock_counter % tready_delay_period) == 0) begin

          clock_counter  = 0;
          vif.tready    <= '0;

          tready_delay_time   = $urandom_range(cfg.max_tready_delay_time,   cfg.min_tready_delay_time);
          tready_delay_period = $urandom_range(cfg.max_tready_delay_period, cfg.min_tready_delay_period);
          `uvm_info(get_name(), $sformatf("De-asserting 'tready' for (%0d) clock periods", tready_delay_time), UVM_HIGH)
          repeat (tready_delay_time) @(posedge vif.clk);

          vif.tready <= '1;

        end
        @(posedge vif.clk);
      end
      vif.tready <= '0;
    end
  endtask

endclass
