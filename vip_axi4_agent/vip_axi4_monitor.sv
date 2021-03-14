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

class vip_axi4_monitor #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_monitor;

  // Analysis ports
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) awaddr_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) wdata_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) bresp_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) araddr_port;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rdata_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) rd_request_fifo;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rd_response_port;

  // Callback
  `uvm_register_cb(vip_axi4_monitor #(CFG_P), vip_axi4_monitor_callback)

  // Class variables
  protected virtual vip_axi4_if #(CFG_P) vif;
  protected process monitor_process;
  protected int   id;
  vip_axi4_config cfg;

  // Driver's read address channel items: expected response to sequence
  vip_axi4_item #(CFG_P) driver_item;
  vip_axi4_item #(CFG_P) driver_items [int][$];
  int                    nr_of_driver_items;

  // Events to the Driver and sequence
  protected string    _ev_id = "";
  protected uvm_event _ev_monitor_wdata;
  protected uvm_event _ev_monitor_araddr;

  vip_axi4_item #(CFG_P) awaddr_items [$];
  vip_axi4_item #(CFG_P) araddr_items [int][$];

  // Ingress data is saved in dynamic list
  logic [CFG_P.VIP_AXI4_DATA_WIDTH_P : 0] wdata_beats [$];
  logic [CFG_P.VIP_AXI4_STRB_WIDTH_P : 0] wstrb_beats [$];
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P : 0] wuser_beats [$];
  logic [CFG_P.VIP_AXI4_DATA_WIDTH_P : 0] rdata_beats [$];
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P : 0] ruser_beats [$];


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
    rd_request_fifo  = new("rd_request_fifo",  this);
    rd_response_port = new("rd_response_port", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db #(virtual vip_axi4_if #(CFG_P))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
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
          disable fork;
        end
      join
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual protected task monitor_start();
    wait (!cfg.monitor_disabled);
    fork
      monitor_process = process::self();
      collect_write_channel();
      collect_read_channel();
    join
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void handle_reset();
    if (monitor_process != null) begin
      monitor_process.kill();
    end
    awaddr_items.delete();
    araddr_items.delete();
    wdata_beats.delete();
    wstrb_beats.delete();
    wuser_beats.delete();
    rdata_beats.delete();
    ruser_beats.delete();
    driver_items.delete();
    rd_request_fifo.flush();
    nr_of_driver_items = 0;
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
    int beat_counter = 0;

    forever begin

      @(posedge vif.clk iff vif.rst_n === '1);

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

        awaddr_items.push_back(awaddr_item);
        awaddr_port.write(awaddr_item);

        `uvm_info(get_name(), $sformatf("Collected Write Address Channel:\n%s", awaddr_item.sprint()), UVM_HIGH)
      end

      // -----------------------------------------------------------------------
      // Write Data Channel
      // -----------------------------------------------------------------------
      if (vif.wvalid === '1 && vif.wready === '1) begin
        wdata_beats.push_back(vif.wdata);
        wstrb_beats.push_back(vif.wstrb);
        wuser_beats.push_back(vif.wuser);
        //beat_counter++;
      end

      if (vif.wlast === '1 && vif.wvalid === '1 && vif.wready === '1) begin

        wdata_item = awaddr_items.pop_front();

        wdata_item.wdata = new[wdata_beats.size()];
        wdata_item.wstrb = new[wstrb_beats.size()];
        wdata_item.wuser = new[wuser_beats.size()];
        foreach (wdata_item.wdata[i]) begin wdata_item.wdata[i] = wdata_beats[i]; end
        foreach (wdata_item.wstrb[i]) begin wdata_item.wstrb[i] = wstrb_beats[i]; end
        foreach (wdata_item.wuser[i]) begin wdata_item.wuser[i] = wuser_beats[i]; end

        `uvm_info(get_name(), $sformatf("Collected Write Data Channel:\n%s", wdata_item.sprint()), UVM_HIGH)

        wdata_port.write(wdata_item);

        if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_enabled == TRUE) begin
          _ev_monitor_wdata.trigger(wdata_item);
        end

      end

      // -----------------------------------------------------------------------
      // Write Response Channel
      // -----------------------------------------------------------------------
      if (vif.bvalid === '1 && vif.bready === '1) begin

        wdata_item.bid   = vif.bid;
        wdata_item.bresp = vif.bresp;
        wdata_item.buser = vif.buser;

        `uvm_info(get_name(), $sformatf("Collected Write Response Channel:\n%s", wdata_item.sprint()), UVM_HIGH)
        bresp_port.write(wdata_item);
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
    vip_axi4_item #(CFG_P) rdata_item1;
    vip_axi4_item #(CFG_P) rdata_item2;

    forever begin

      @(posedge vif.clk iff vif.rst_n === '1);

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
        araddr_items[channel_id].push_back(araddr_item);

        araddr_port.write(araddr_item);

        if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
          _ev_monitor_araddr.trigger(araddr_item);
        end

        `uvm_info(get_name(), $sformatf("Collected Read Address Channel:\n%s", araddr_item.sprint()), UVM_HIGH)

        // This read transaction's response is requested by a sequence
        if (!rd_request_fifo.is_empty()) begin
          rd_request_fifo.get(driver_item);
          driver_arid = int'(driver_item.arid);
          driver_items[driver_arid].push_back(driver_item);
          nr_of_driver_items++;
        end

      end

      // -----------------------------------------------------------------------
      // Read Data Channel
      // -----------------------------------------------------------------------
      if (vif.rvalid === '1 && vif.rready === '1) begin

        rdata_beats.push_back(vif.rdata);
        ruser_beats.push_back(vif.ruser);

        if (vif.rlast === '1) begin

          rdata_item = new();

          if (cfg.monitor_merge_reads == TRUE) begin

            channel_id = int'(vif.rid);
            if (!araddr_items.exists(channel_id)) begin
              `uvm_fatal(get_name(), $sformatf("Collected rid (%0d = %0h) which cannot be associated with any arid", channel_id, channel_id))
            end

            rdata_item = araddr_items[channel_id].pop_front();

            if (araddr_item == null) begin
              `uvm_fatal(get_name(), $sformatf("Fetched NULL object with rid (%0d = %0h)", channel_id, channel_id))
            end
          end

          rdata_item.rid   = vif.rid;
          rdata_item.rresp = vif.rresp;

          rdata_item.rdata = new[rdata_beats.size()];
          rdata_item.ruser = new[ruser_beats.size()];
          foreach (rdata_item.rdata[i]) begin rdata_item.rdata[i] = rdata_beats[i]; end
          foreach (rdata_item.ruser[i]) begin rdata_item.ruser[i] = ruser_beats[i]; end

          rdata_beats.delete();
          ruser_beats.delete();

          `uvm_info(get_name(), $sformatf("Collected Read Data Channel:\n%s", rdata_item.sprint()), UVM_HIGH)

          rdata_port.write(rdata_item);

          // Checking if the driver has registered any ID's that should be forwarded back
          if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E && cfg.is_active == UVM_ACTIVE) begin
            if (nr_of_driver_items != 0) begin
              if (driver_items.exists(channel_id) && driver_items[channel_id].size() != 0) begin
                void'(driver_items[channel_id].pop_front());
                rd_response_port.write(rdata_item);
                nr_of_driver_items--;
              end
            end
          end
        end
      end
    end
  endtask

endclass
