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

class vip_axi4_monitor #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_monitor;

  // Analysis ports
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) awaddr_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) wdata_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) bresp_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) araddr_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rdata_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) wr_request_fifo;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) wr_response_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) rd_request_fifo;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rd_response_port;

  // Callback
  `uvm_register_cb(vip_axi4_monitor #(CFG_P), vip_axi4_monitor_callback)

  // Class variables
  protected virtual vip_axi4_if #(CFG_P) vif;
  protected int   id;
  vip_axi4_config cfg;

  // Driver's read address channel items: expected response to sequence
  protected vip_axi4_item #(CFG_P) _driver_rd_item;
  protected vip_axi4_item #(CFG_P) _driver_rd_items [int][$];
  protected int                    _nr_of_driver_rd_items;

  // Driver's write address channel items: expected response to sequence
  protected vip_axi4_item #(CFG_P) _driver_wr_item;
  protected vip_axi4_item #(CFG_P) _driver_wr_items [int][$];
  protected int                    _nr_of_driver_wr_items;

  // Events to the Driver and sequence
  protected string    _ev_id = "";
  protected uvm_event _ev_monitor_wdata;
  protected uvm_event _ev_monitor_araddr;

  protected vip_axi4_item #(CFG_P) _awaddr_items [$];
  protected vip_axi4_item #(CFG_P) _araddr_items [int][$];

  // Ingress data is saved in dynamic list
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P : 0] _wdata_beats [$];
  protected logic [CFG_P.VIP_AXI4_STRB_WIDTH_P : 0] _wstrb_beats [$];
  protected logic [CFG_P.VIP_AXI4_USER_WIDTH_P : 0] _wuser_beats [$];
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P : 0] _rdata_beats [$];
  protected logic [CFG_P.VIP_AXI4_USER_WIDTH_P : 0] _ruser_beats [$];


  `uvm_component_param_utils_begin(vip_axi4_monitor #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
  `uvm_component_utils_end

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    awaddr_port      = new("awaddr_port",      this);
    wdata_port       = new("wdata_port",       this);
    bresp_port       = new("bresp_port",       this);
    araddr_port      = new("araddr_port",      this);
    rdata_port       = new("rdata_port",       this);
    wr_request_fifo  = new("wr_request_fifo",  this);
    wr_response_port = new("wr_response_port", this);
    rd_request_fifo  = new("rd_request_fifo",  this);
    rd_response_port = new("rd_response_port", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db #(virtual vip_axi4_if #(CFG_P))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"FATAL [AXI4] Virtual interface must be set for: ", get_full_name(), ".vif"});
    end

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
      _ev_id.itoa(id);
      _ev_monitor_wdata  = uvm_event_pool::get_global({"EV_MONITOR_WDATA_",  _ev_id});
      _ev_monitor_araddr = uvm_event_pool::get_global({"EV_MONITOR_ARADDR_", _ev_id});
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      fork
        begin
          @(posedge vif.rst_n);
          monitor_start();
        end
      join_none
      @(negedge vif.rst_n);
      disable fork;
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task monitor_start();
    wait (!cfg.monitor_disabled);
    fork
      collect_write_channel();
      collect_read_channel();
    join
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void handle_reset();
    _awaddr_items.delete();
    _araddr_items.delete();
    _wdata_beats.delete();
    _wstrb_beats.delete();
    _wuser_beats.delete();
    _rdata_beats.delete();
    _ruser_beats.delete();
    _driver_wr_items.delete();
    _driver_rd_items.delete();
    wr_request_fifo.flush();
    rd_request_fifo.flush();
    _nr_of_driver_wr_items = 0;
    _nr_of_driver_rd_items = 0;
    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
      _ev_monitor_wdata.reset();
      _ev_monitor_araddr.reset();
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task collect_write_channel();

    vip_axi4_item #(CFG_P) awaddr_item;
    vip_axi4_item #(CFG_P) wdata_item;
    vip_axi4_item #(CFG_P) bresp_item;
    int                    channel_id;
    int                    beat_counter = 0;
    int                    driver_awid;

    forever begin

      @(posedge vif.clk);

      // -----------------------------------------------------------------------
      // Write Address Channel
      // -----------------------------------------------------------------------
      if (vif.awvalid === '1 && vif.awready === '1) begin

        awaddr_item = new();

        awaddr_item.awid     = vif.awid;
        awaddr_item.awaddr   = vif.awaddr;
        awaddr_item.awlen    = vif.awlen;
        awaddr_item.awsize   = vif.awsize;
        awaddr_item.awburst  = vif.awburst;
        awaddr_item.awlock   = vif.awlock;
        awaddr_item.awcache  = vif.awcache;
        awaddr_item.awprot   = vif.awprot;
        awaddr_item.awqos    = vif.awqos;
        awaddr_item.awregion = vif.awregion;
        awaddr_item.awuser   = vif.awuser;

        awaddr_item.wdata = new[vif.awlen+1];
        awaddr_item.wstrb = new[vif.awlen+1];
        awaddr_item.wuser = new[vif.awlen+1];

        awaddr_port.write(awaddr_item);
        $cast(awaddr_item, awaddr_item.clone());
        _awaddr_items.push_back(awaddr_item);

        `uvm_info(get_name(), $sformatf("INFO [AXI4] Collected Write Address Channel:\n%s", awaddr_item.sprint()), UVM_HIGH)

        // This read transaction's response is requested by a sequence
        if (!wr_request_fifo.is_empty()) begin
          wr_request_fifo.get(_driver_wr_item);
          driver_awid = int'(_driver_wr_item.awid);
          _driver_wr_items[driver_awid].push_back(_driver_wr_item);
          _nr_of_driver_wr_items++;
        end
      end

      // -----------------------------------------------------------------------
      // Write Data Channel
      // -----------------------------------------------------------------------
      if (vif.wvalid === '1 && vif.wready === '1) begin
        _wdata_beats.push_back(vif.wdata);
        _wstrb_beats.push_back(vif.wstrb);
        _wuser_beats.push_back(vif.wuser);
      end

      if (vif.wlast === '1 && vif.wvalid === '1 && vif.wready === '1) begin

        wdata_item = _awaddr_items.pop_front();

        if (wdata_item == null) begin
          `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Fetched NULL object from the awaddr queue"))
        end

        if (wdata_item.awlen+1 != _wdata_beats.size()) begin
          `uvm_error(get_name(), $sformatf(
          "ERROR [AXI4] Transaction length mismatch: awlen+1 != #beats (%0d != %0d)",
          wdata_item.awlen+1, _wdata_beats.size()))
        end

        wdata_item.wdata = new[_wdata_beats.size()];
        wdata_item.wstrb = new[_wstrb_beats.size()];
        wdata_item.wuser = new[_wuser_beats.size()];
        foreach (wdata_item.wdata[i]) begin wdata_item.wdata[i] = _wdata_beats[i]; end
        foreach (wdata_item.wstrb[i]) begin wdata_item.wstrb[i] = _wstrb_beats[i]; end
        foreach (wdata_item.wuser[i]) begin wdata_item.wuser[i] = _wuser_beats[i]; end
        _wdata_beats.delete();
        _wstrb_beats.delete();
        _wuser_beats.delete();

        `uvm_info(get_name(), $sformatf("Collected Write Data Channel:\n%s", wdata_item.sprint()), UVM_HIGH)

        wdata_port.write(wdata_item);

        if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
          _ev_monitor_wdata.trigger(wdata_item);
        end

      end

      // -----------------------------------------------------------------------
      // Write Response Channel
      // -----------------------------------------------------------------------
      if (vif.bvalid === '1 && vif.bready === '1) begin

        $cast(bresp_item, wdata_item.clone());
        bresp_item.bid   = vif.bid;
        bresp_item.bresp = vif.bresp;
        bresp_item.buser = vif.buser;
        `uvm_info(get_name(), $sformatf("Collected Write Response Channel:\n%s", bresp_item.sprint()), UVM_HIGH)
        bresp_port.write(bresp_item);

        // Checking if the driver has registered any ID's that should be forwarded back
        if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E && cfg.is_active == UVM_ACTIVE) begin
          if (_nr_of_driver_wr_items != 0) begin
            channel_id = int'(vif.bid);
            if (_driver_wr_items.exists(channel_id) && _driver_wr_items[channel_id].size() != 0) begin
              void'(_driver_wr_items[channel_id].pop_front());
              wr_response_port.write(bresp_item);
              _nr_of_driver_wr_items--;
            end
          end
        end
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task collect_read_channel();

    int                    channel_id;
    int                    driver_arid;
    vip_axi4_item #(CFG_P) araddr_item;
    vip_axi4_item #(CFG_P) rdata_item;

    forever begin

      @(posedge vif.clk);

      // -----------------------------------------------------------------------
      // Read Address Channel
      // -----------------------------------------------------------------------
      if (vif.arvalid === '1 && vif.arready === '1) begin

        araddr_item = new();

        araddr_item.arid     = vif.arid;
        araddr_item.araddr   = vif.araddr;
        araddr_item.arlen    = vif.arlen;
        araddr_item.arsize   = vif.arsize;
        araddr_item.arburst  = vif.arburst;

        araddr_item.arlock   = vif.arlock;
        araddr_item.arcache  = vif.arcache;
        araddr_item.arprot   = vif.arprot;
        araddr_item.arqos    = vif.arqos;
        araddr_item.arregion = vif.arregion;
        araddr_item.aruser   = vif.aruser;

        channel_id = int'(vif.arid);
        // NOTE: Vivado does not support push_back(araddr_item.clone())
        _araddr_items[channel_id].push_back(araddr_item);
        $cast(araddr_item, araddr_item.clone());

        araddr_port.write(araddr_item);

        if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
          _ev_monitor_araddr.trigger(araddr_item);
        end

        `uvm_info(get_name(), $sformatf("Collected Read Address Channel:\n%s", araddr_item.sprint()), UVM_HIGH)

        // This read transaction's response is requested by a sequence
        if (!rd_request_fifo.is_empty()) begin
          rd_request_fifo.get(_driver_rd_item);
          driver_arid = int'(_driver_rd_item.arid);
          _driver_rd_items[driver_arid].push_back(_driver_rd_item);
          _nr_of_driver_rd_items++;
        end

      end

      // -----------------------------------------------------------------------
      // Read Data Channel
      // -----------------------------------------------------------------------
      if (vif.rvalid === '1 && vif.rready === '1) begin

        _rdata_beats.push_back(vif.rdata);
        _ruser_beats.push_back(vif.ruser);

        if (vif.rlast === '1) begin

          rdata_item = new();

          if (cfg.monitor_merge_reads == TRUE) begin

            channel_id = int'(vif.rid);
            if (!_araddr_items.exists(channel_id)) begin
              `uvm_fatal(get_name(), $sformatf(
              "FATAL [AXI4] Collected rid (%0d = %0h) which cannot be associated with any arid",
              channel_id, channel_id))
            end

            rdata_item = _araddr_items[channel_id].pop_front();

            if (rdata_item == null) begin
              `uvm_fatal(get_name(), $sformatf(
              "FATAL [AXI4] Fetched NULL object with rid (%0d = %0h)",
              channel_id, channel_id))
            end

            if (rdata_item.arlen+1 != _rdata_beats.size()) begin
              if (vif.rresp === '0) begin
                `uvm_error(get_name(), $sformatf(
                "ERROR [AXI4] Transaction length mismatch: arlen+1 != #beats (%0d != %0d)",
                rdata_item.arlen+1, _rdata_beats.size()))
              end
              else begin
                `uvm_warning(get_name(), $sformatf(
                "WARNING [AXI4] Transaction length mismatch: arlen+1 != #beats (%0d != %0d)",
                rdata_item.arlen+1, _rdata_beats.size()))
              end
            end
          end

          rdata_item.rid   = vif.rid;
          rdata_item.rresp = vif.rresp;

          rdata_item.rdata = new[_rdata_beats.size()];
          rdata_item.ruser = new[_ruser_beats.size()];
          foreach (rdata_item.rdata[i]) begin rdata_item.rdata[i] = _rdata_beats[i]; end
          foreach (rdata_item.ruser[i]) begin rdata_item.ruser[i] = _ruser_beats[i]; end

          _rdata_beats.delete();
          _ruser_beats.delete();

          `uvm_info(get_name(), $sformatf("Collected Read Data Channel:\n%s", rdata_item.sprint()), UVM_HIGH)

          rdata_port.write(rdata_item);

          // Checking if the driver has registered any ID's that should be forwarded back
          if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E && cfg.is_active == UVM_ACTIVE) begin
            if (_nr_of_driver_rd_items != 0) begin
              if (_driver_rd_items.exists(channel_id) && _driver_rd_items[channel_id].size() != 0) begin
                void'(_driver_rd_items[channel_id].pop_front());
                rd_response_port.write(rdata_item);
                _nr_of_driver_rd_items--;
              end
            end
          end
        end
      end
    end
  endtask

endclass
