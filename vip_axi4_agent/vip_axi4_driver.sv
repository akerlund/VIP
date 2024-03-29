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

class vip_axi4_driver #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_driver #(vip_axi4_item #(CFG_P));

  typedef logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] mem_addr_type_t;
  typedef logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] mem_get_type_t [mem_addr_type_t];

  localparam vip_mem_cfg_t MEM_C = {
    ADDR_WIDTH_P : CFG_P.VIP_AXI4_ADDR_WIDTH_P,
    DATA_BYTES_P : CFG_P.VIP_AXI4_DATA_WIDTH_P/8
  };

  // Analysis FIFOs connected to the monitor's analysis ports
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) wr_request_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) wr_response_fifo;
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rd_request_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) rd_response_fifo;
  protected int                                   _requested_wr_responses;

  // Callback
  `uvm_register_cb(vip_axi4_driver #(CFG_P), vip_axi4_driver_callback)

  // Class variables
  protected virtual vip_axi4_if #(CFG_P) vif;
  protected int id;
  vip_axi4_config cfg;

  // Events from the Monitor and storage queues
  protected string    _ev_id;
  protected uvm_event _ev_monitor_wdata;  // Write request
  protected uvm_event _ev_monitor_araddr; // Read request
  protected vip_axi4_item #(CFG_P) _araddr_queue [$];
  protected vip_axi4_item #(CFG_P) _wdata_queue  [$]; // TODO

  // Memory
  protected vip_mem #(MEM_C) _mem;
  protected longint          _memory_depth;
            int              ooo_counter;

  // Read and Write collision detection
  protected logic  [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _current_araddr_start;
  protected logic  [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _current_araddr_stop;
  protected bool_t                                     _rdata_active;


  `uvm_component_param_utils_begin(vip_axi4_driver #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
  `uvm_component_utils_end

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
    wr_request_port  = new("wr_request_port", this);
    wr_response_fifo = new("wr_response_fifo", this);
    rd_request_port  = new("rd_request_port", this);
    rd_response_fifo = new("rd_response_fifo", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E) begin
      _mem = new();
    end

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
  function void start_of_simulation_phase(uvm_phase phase);

    super.start_of_simulation_phase(phase);

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E) begin
      if (cfg.mem_addr_width != 0) begin
        _memory_depth = 2**(cfg.mem_addr_width-$clog2(CFG_P.VIP_AXI4_STRB_WIDTH_P));
        if (_memory_depth == 0) begin
          `uvm_fatal("RANGE", $sformatf("FATAL [AXI4] The memory depth was calculated to (%0d)", _memory_depth))
        end
        _mem.set_depth(_memory_depth);
        _mem.set_wr_x_severity(cfg.mem_x_wr_severity);
        _mem.set_rd_x_responses(cfg.mem_rd_x_responses);
        _mem.set_rd_x_severity(cfg.mem_x_rd_severity);
      end
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
          driver_start();
        end
      join_none
      @(negedge vif.rst_n);
      reset_vif();
      disable fork;
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task driver_start();

    if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E) begin
      fork
        mst_get_and_drive();           // Get Write and Read requests
        drive_rready();                // Can be configured to be delayed
      join
    end
    else begin
      if (cfg.mem_slave == TRUE) begin
        fork
          get_memory_write_requests(); // Passed from the Monitor via events
          drive_awready();             // De-assert awready when we have recieved too much wdata
          drive_wready();              // Can be configured to be delayed
          get_memory_read_requests();  // Passed from the Monitor via events, stored in an OOO queue
          drive_arready();             // De-assert awready when we have recieved too many requests
          fill_read_request_queue();   // The OOO queue
        join
      end else begin
        fork
          slv_get_and_drive();         // Get Response requests
        join
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void handle_reset();
    _araddr_queue.delete();
    _wdata_queue.delete();
    _rdata_active = FALSE;
    rd_response_fifo.flush();
    _requested_wr_responses = 0;
    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
      _ev_monitor_wdata.reset();
      _ev_monitor_araddr.reset();
    end
    ooo_counter = 0;
  endfunction

  // ---------------------------------------------------------------------------
  // Reset VIF
  // ---------------------------------------------------------------------------
  protected task reset_vif();

    `uvm_info(get_name(), "INFO [AXI4] VIF Reset", UVM_HIGH)
    if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E) begin

      // Write Address Channel
      vif.awid     <= '0;
      vif.awaddr   <= '0;
      vif.awlen    <= '0;
      vif.awsize   <= '0;
      vif.awburst  <= '0;
      vif.awlock   <= '0;
      vif.awcache  <= '0;
      vif.awprot   <= '0;
      vif.awqos    <= '0;
      vif.awregion <= '0;
      vif.awuser   <= '0;
      vif.awvalid  <= '0;

      // Write Data Channel
      vif.wdata    <= '0;
      vif.wstrb    <= '0;
      vif.wlast    <= '0;
      vif.wuser    <= '0;
      vif.wvalid   <= '0;

      // Write Response Channel
      vif.bready   <= '0;

      // Read Address Channel
      vif.arid     <= '0;
      vif.araddr   <= '0;
      vif.arlen    <= '0;
      vif.arsize   <= '0;
      vif.arburst  <= '0;
      vif.arlock   <= '0;
      vif.arcache  <= '0;
      vif.arprot   <= '0;
      vif.arqos    <= '0;
      vif.arregion <= '0;
      vif.aruser   <= '0;
      vif.arvalid  <= '0;

      // Read Data Channel
      vif.rready  <= '0;

    end

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E) begin

      // Write Address Channel
      vif.awready <= '0;

      // Write Data Channel
      vif.wready  <= '0;

      // Write Response Channel
      vif.bid     <= '0;
      vif.bresp   <= '0;
      vif.buser   <= '0;
      vif.bvalid  <= '0;

      // Read Address Channel
      vif.arready <= '0;

      // Read Data Channel
      vif.rid     <= '0;
      vif.rdata   <= '0;
      vif.rresp   <= '0;
      vif.rlast   <= '0;
      vif.ruser   <= '0;
      vif.rvalid  <= '0;

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E
  // ---------------------------------------------------------------------------
  protected task mst_get_and_drive();

    forever begin

      seq_item_port.get_next_item(req);

      if (req == null) begin
        `uvm_fatal(get_name(), "FATAL [AXI4] get_next_item() returned NULL");
      end

      if (req.cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) begin
        drive_wr_request();
      end else if (req.cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) begin
        drive_araddr();
      end else begin
        `uvm_fatal(get_name(), "FATAL [AXI4] Invalid item type");
      end

      seq_item_port.item_done();
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & ACTIVE
  // ---------------------------------------------------------------------------
  protected task slv_get_and_drive();

    forever begin

      seq_item_port.get_next_item(req);

      if (req == null) begin
        `uvm_fatal(get_name(), "FATAL [AXI4] get_next_item() returned NULL");
      end

      if (req.cfg.axi4_access != VIP_AXI4_RD_RESPONSE_E) begin
        `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Invalid item type (%s)",
        req.cfg.axi4_access.name()))
      end

      drive_rdata();
      seq_item_port.item_done();
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Write Requests
  // ---------------------------------------------------------------------------
  protected task drive_wr_request();

    //`uvm_do_callbacks(vip_axi4_driver #(CFG_P), vip_axi4_driver_callback, pre_drive());
    fork
      drive_awaddr();
      drive_wdata();
    join

    //`uvm_do_callbacks(vip_axi4_driver #(CFG_P), vip_axi4_driver_callback, post_drive());
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Write Address Channel
  // ---------------------------------------------------------------------------
  protected task drive_awaddr();

    vip_axi4_item #(CFG_P) _req_queue [$];
    _req_queue = req.req_queue;
    _req_queue.push_front(req);

    if (cfg.awvalid_delay_enabled) begin
      fork
        drive_awvalid();
      join_none
    end else begin
      vif.awvalid <= '1;
    end

    for (int i = 0; i < _req_queue.size(); i++) begin

      if (_req_queue[i].cfg.get_wr_response == TRUE) begin
        wr_request_port.write(_req_queue[i]);
        _requested_wr_responses++;
      end

      vif.awid     <= _req_queue[i].awid;
      vif.awaddr   <= _req_queue[i].awaddr;
      vif.awlen    <= _req_queue[i].awlen;
      vif.awsize   <= _req_queue[i].awsize;
      vif.awburst  <= _req_queue[i].awburst;
      vif.awlock   <= _req_queue[i].awlock;
      vif.awcache  <= _req_queue[i].awcache;
      vif.awprot   <= _req_queue[i].awprot;
      vif.awqos    <= _req_queue[i].awqos;
      vif.awregion <= _req_queue[i].awregion;
      vif.awuser   <= _req_queue[i].awuser;

      @(posedge vif.clk);
      while (!(vif.awvalid === '1 && vif.awready === '1)) begin
        @(posedge vif.clk);
      end

      if (i == (_req_queue.size()-1)) begin
        if (cfg.awvalid_delay_enabled) begin
          disable fork;
        end
        vif.awvalid <= '0;
      end

    end

    _req_queue.delete();
    vif.awvalid <= '0;
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Write Data Channel
  // ---------------------------------------------------------------------------
  protected task drive_wdata();

    vip_axi4_item #(CFG_P) _req_queue [$];
    int beat_counter;
    int burst_length;
    vip_axi4_item #(CFG_P) _response;
    int requested_responses = 0;
    int received_responses  = 0;
    _req_queue = req.req_queue;
    _req_queue.push_front(req);

    vif.wlast  <= '0;

    for (int i = 0; i < _req_queue.size(); i++) begin

      beat_counter = 0;
      burst_length = _req_queue[i].awlen + 1;

      if (cfg.wvalid_delay_enabled) begin
        fork
          drive_wvalid();
        join_none
      end else begin
        vif.wvalid <= '1;
      end

      while (beat_counter != burst_length) begin

        vif.wdata <= _req_queue[i].wdata[beat_counter];
        vif.wstrb <= _req_queue[i].wstrb[beat_counter];
        vif.wuser <= _req_queue[i].wuser[beat_counter];

        beat_counter++;

        if (beat_counter == burst_length) begin
          vif.wlast  <= '1;
          vif.bready <= '1;
        end

        @(posedge vif.clk);
        while (!(vif.wvalid === '1 && vif.wready === '1)) begin
          @(posedge vif.clk);
        end

        if (beat_counter == burst_length) begin
          if (cfg.wvalid_delay_enabled) begin
            disable fork;
          end
          vif.wvalid <= '0;
        end

      end

      vif.wlast <= '0;

      if (cfg.bresp_enabled) begin
        vif.bready <= '1;
        while (vif.bvalid !== '1) begin
          @(posedge vif.clk);
        end
      end
      vif.bready <= '0;

      if (req.cfg.get_wr_response == TRUE) begin

        while (received_responses != _requested_wr_responses) begin

          while (wr_response_fifo.is_empty()) begin
            @(posedge vif.clk);
          end

          wr_response_fifo.get(_response);
          if (_response == null) begin `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] NULL response from the Monitor")) end

          if (received_responses == 0) begin
            rsp = _response;
            rsp.set_id_info(req);
          end
          else begin
            rsp.req_queue.push_back(_response);
          end
          received_responses++;
          `uvm_info(get_name(), $sformatf("INFO [AXI4] Write response"), UVM_LOW)
        end
      end
    end

    if (req.cfg.get_wr_response == TRUE) begin
      seq_item_port.put(rsp);
    end
    _req_queue.delete();
    vif.wvalid <= '0;

  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Write Address Channel
  // ---------------------------------------------------------------------------
  protected task drive_awvalid();

    int clock_counter        = 0;
    int awvalid_delay_time   = 0;
    int awvalid_delay_period = $urandom_range(cfg.max_awvalid_delay_period, cfg.min_awvalid_delay_period);

    vif.awvalid <= '1;

    while (1) begin

      @(posedge vif.clk);
      clock_counter++;

      if (clock_counter >= awvalid_delay_period &&
          vif.awvalid === '1 && vif.awready === '1) begin
        vif.awvalid         <= '0;
        clock_counter        = 0;
        awvalid_delay_time   = $urandom_range(cfg.max_awvalid_delay_time,   cfg.min_awvalid_delay_time);
        awvalid_delay_period = $urandom_range(cfg.max_awvalid_delay_period, cfg.min_awvalid_delay_period);
        `uvm_info(get_name(), $sformatf("INFO [AXI4] De-asserting 'awvalid' for (%0d) clock periods", awvalid_delay_time), UVM_HIGH)
        repeat (awvalid_delay_time) @(posedge vif.clk);
      end
      else begin
        vif.awvalid <= '1;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Write Data Channel
  // ---------------------------------------------------------------------------
  protected task drive_wvalid();

    int clock_counter       = 0;
    int wvalid_delay_time   = 0;
    int wvalid_delay_period = $urandom_range(cfg.max_wvalid_delay_period, cfg.min_wvalid_delay_period);

    vif.wvalid <= '1;

    while (1) begin

      @(posedge vif.clk);
      if (vif.wvalid === '1 && vif.wready === '1 && vif.wlast === '1) begin
        @(posedge vif.clk);
        vif.wvalid <= '0;
        break;
      end

      clock_counter++;

      if (clock_counter >= wvalid_delay_period &&
          vif.wvalid === '1 && vif.wready === '1) begin
        vif.wvalid         <= '0;
        clock_counter       = 0;
        wvalid_delay_time   = $urandom_range(cfg.max_wvalid_delay_time,   cfg.min_wvalid_delay_time);
        wvalid_delay_period = $urandom_range(cfg.max_wvalid_delay_period, cfg.min_wvalid_delay_period);
        `uvm_info(get_name(), $sformatf("INFO [AXI4] De-asserting 'wvalid' for (%0d) clock periods", wvalid_delay_time), UVM_HIGH)
        repeat (wvalid_delay_time) @(posedge vif.clk);
      end
      else begin
        vif.wvalid <= '1;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Write Address Channel - awready
  // ---------------------------------------------------------------------------
  protected task drive_awready();

    forever begin

      @(posedge vif.clk);
      vif.awready <= '1;
      while (vif.awvalid !== '1) begin
        @(posedge vif.clk);
      end

      if (cfg.mem_awaddr_fifo_size != 0) begin
        while (_wdata_queue.size() >= cfg.mem_awaddr_fifo_size) begin
          vif.awready <= '0;
          repeat (cfg.mem_awaddr_fifo_size*10) @(posedge vif.clk);
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Write Data Channel - wready
  // ---------------------------------------------------------------------------
  protected task drive_wready();

    if (cfg.wready_delay_enabled) begin
      drive_wready_with_delay();
    end

    @(posedge vif.clk);
    forever begin
      vif.wready <= '1;
      @(posedge vif.clk);

      while (!(vif.wvalid === '1 && vif.wlast === '1)) begin
        @(posedge vif.clk);
      end

      vif.wready <= '0;
      @(posedge vif.clk);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Slave: Write Data Channel - Backpressure of 'wready'
  // ---------------------------------------------------------------------------
  protected task drive_wready_with_delay();

    int clock_counter       = 0;
    int wready_delay_time   = 0;
    int wready_delay_period = $urandom_range(cfg.max_wready_delay_period, cfg.min_wready_delay_period);

    @(posedge vif.clk);
    forever begin

      vif.wready <= '1;
      @(posedge vif.clk);

      while (!(vif.wvalid === '1 && vif.wlast === '1)) begin

        clock_counter++;
        if ((clock_counter % wready_delay_period) == 0) begin

          clock_counter  = 0;
          vif.wready    <= '0;

          wready_delay_time   = $urandom_range(cfg.max_wready_delay_time,   cfg.min_wready_delay_time);
          wready_delay_period = $urandom_range(cfg.max_wready_delay_period, cfg.min_wready_delay_period);
          `uvm_info(get_name(), $sformatf("INFO [AXI4] De-asserting 'wready' for (%0d) clock periods", wready_delay_time), UVM_HIGH)
          repeat (wready_delay_time) @(posedge vif.clk);

          vif.wready <= '1;

        end
        @(posedge vif.clk);
      end
      vif.wready <= '0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Read Address Channel
  // ---------------------------------------------------------------------------
  protected task drive_araddr();

    int requested_responses = 0;
    int received_responses  = 0;
    vip_axi4_item #(CFG_P) _req_queue [$];
    vip_axi4_item #(CFG_P) _response;
    _req_queue = req.req_queue;
    _req_queue.push_front(req);

    vif.arvalid <= '1;
    for (int i = 0; i < _req_queue.size(); i++) begin

      if (_req_queue[i].cfg.get_rd_response == TRUE) begin // Notify the monitor
        rd_request_port.write(_req_queue[i]);
        requested_responses++;
      end

      vif.arid     <= _req_queue[i].arid;
      vif.araddr   <= _req_queue[i].araddr;
      vif.arlen    <= _req_queue[i].arlen;
      vif.arsize   <= _req_queue[i].arsize;
      vif.arburst  <= _req_queue[i].arburst;
      vif.arlock   <= _req_queue[i].arlock;
      vif.arcache  <= _req_queue[i].arcache;
      vif.arprot   <= _req_queue[i].arprot;
      vif.arqos    <= _req_queue[i].arqos;
      vif.arregion <= _req_queue[i].arregion;
      vif.aruser   <= _req_queue[i].aruser;
      @(posedge vif.clk);
      while (vif.arready !== '1) begin
        @(posedge vif.clk);
      end
    end
    _req_queue.delete();
    vif.arvalid <= '0;

    if (req.cfg.get_rd_response == TRUE) begin

      while (received_responses != requested_responses) begin

        while (!(vif.rvalid === '1 && vif.rready === '1 && vif.rlast === '1)) begin
          @(posedge vif.clk);
        end
        while (rd_response_fifo.is_empty()) begin
          @(posedge vif.clk);
        end

        rd_response_fifo.get(_response);
        if (_response == null) begin `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] NULL response from the Monitor")) end

        if (received_responses == 0) begin
          rsp = _response;
          rsp.set_id_info(req);
          // Any uvm_reg_adapter reads the req instead (smart implementation?). Assuming no combined requests.
          req.rdata = rsp.rdata;
        end
        else begin
          rsp.req_queue.push_back(_response);
        end
        received_responses++;
      end

      if (cfg.drv_put_rsp_in_port == TRUE) begin
        seq_item_port.put(rsp);
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Read Address Channel
  // ---------------------------------------------------------------------------
  protected task drive_arready();

    while (vif.rst_n === '1) begin

      @(posedge vif.clk);
      vif.arready <= '1;
      while (vif.arvalid !== '0) begin
        @(posedge vif.clk);
      end

      if (cfg.mem_araddr_fifo_size != 0) begin
        while (_araddr_queue.size() >= cfg.mem_araddr_fifo_size) begin
          vif.arready <= '0;
          repeat (cfg.mem_araddr_fifo_size*10) @(posedge vif.clk);
        end
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & ACTIVE: Read Data Channel
  // ---------------------------------------------------------------------------
  protected task drive_rdata();

    int beat_counter = 0;
    int burst_length = req.arlen + 1;

    vif.rid   <= req.rid;
    vif.rresp <= req.rresp;

    while (beat_counter != burst_length) begin

      vif.rdata <= req.rdata[beat_counter];
      vif.ruser <= req.ruser[beat_counter];

      beat_counter++;
      if (beat_counter == burst_length) begin
        vif.rlast <= '1;
      end

      vif.rvalid <= '1;
      @(posedge vif.clk);
      while (vif.rready !== '1) begin
        @(posedge vif.clk);
      end

    end

    vif.rlast  <= '0;
    vif.rvalid <= '0;
    @(posedge vif.clk);

  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Read Data Channel - rready
  // ---------------------------------------------------------------------------
  protected task drive_rready();
    while (vif.arvalid !== '1) begin; // Only start if the Agent requests a read
      @(posedge vif.clk);
    end
    if (cfg.rready_delay_enabled) begin
      drive_rready_with_delay();
    end
    vif.rready <= '1;
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E: Read Data Channel - rready
  // The 'rready' is randomly de-asserted
  // ---------------------------------------------------------------------------
  protected task drive_rready_with_delay();

    int clock_counter       = 0;
    int rready_delay_time   = 0;
    int rready_delay_period = $urandom_range(cfg.max_rready_delay_period, cfg.min_rready_delay_period);

    forever begin

      vif.rready <= '1;
      @(posedge vif.clk);

      while (!(vif.rvalid === '1 && vif.rlast === '1)) begin

        clock_counter++;
        if ((clock_counter % rready_delay_period) == 0) begin

          clock_counter  = 0;
          vif.rready    <= '0;

          rready_delay_time   = $urandom_range(cfg.max_rready_delay_time,   cfg.min_rready_delay_time);
          rready_delay_period = $urandom_range(cfg.max_rready_delay_period, cfg.min_rready_delay_period);
          `uvm_info(get_name(), $sformatf("INFO [AXI4] De-asserting 'rready' for (%0d) clock periods", rready_delay_time), UVM_HIGH)
          repeat (rready_delay_time) @(posedge vif.clk);

          vif.rready <= '1;

        end
        @(posedge vif.clk);
      end
      vif.rready <= '0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Write Data Channel
  // ---------------------------------------------------------------------------
  protected task get_memory_write_requests();

    vip_axi4_item #(CFG_P) wr_req;
    logic unsigned [1 : 0] bresp = VIP_AXI4_RESP_OK_C;

    longint memory_start_index = 0;
    int     write_range        = 0;
    longint memory_stop_index  = 0;
    int     write_counter      = 0;
    wr_req = new();

    if (_ev_monitor_wdata == null) begin
      // If not configured in build phase
      `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Event object is not created"))
    end

    forever begin

      _ev_monitor_wdata.wait_on();

      if (cfg.mem_enabled == TRUE) begin

        if (!$cast(wr_req, _ev_monitor_wdata.get_trigger_data())) begin
          `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Casting write trigger data failed"))
        end else if (wr_req == null) begin
          `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Casting resulted in a NULL object"))
        end

        _ev_monitor_wdata.reset();

        memory_start_index = unsigned'(wr_req.awaddr) / CFG_P.VIP_AXI4_STRB_WIDTH_P;
        write_range        = unsigned'(wr_req.awlen) + 1;
        memory_stop_index  = memory_start_index + write_range;

        // Collision detection
        bresp = VIP_AXI4_RESP_OK_C;
        if (_rdata_active == TRUE) begin
          if (wr_req.awaddr >= _current_araddr_start &&
              wr_req.awaddr + wr_req.awlen <= _current_araddr_stop) begin
            `uvm_warning(get_name(), $sformatf("WARNING [AXI4] Collision detected: awaddr(%h), araddr(%h)",
            wr_req.awaddr, _current_araddr_start))
            bresp = VIP_AXI4_RESP_SLVERR_C;
          end
        end

        if (memory_start_index > (_memory_depth-1) || memory_stop_index > _memory_depth) begin
          `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Memory range undefined (%0d - %0d) > (%0d)",
          memory_start_index, memory_stop_index, _memory_depth))
        end

        // If we are configured with write errors we might skip the write and return an error
        if (cfg.mem_wr_error_prob != 0) begin
          if (cfg.mem_wr_error_prob >= $urandom_range(100, 1)) begin
            `uvm_warning(get_name(), $sformatf("WARNING [AXI4] A random write error occured"))
            bresp = VIP_AXI4_RESP_SLVERR_C;
          end
        end

        // Writing the data to memory
        if (bresp == VIP_AXI4_RESP_OK_C) begin
          _mem.wr_axi4(wr_req.awaddr, wr_req.awlen, wr_req.wdata, wr_req.wstrb);
        end

      end

      if (cfg.bresp_enabled) begin
        vif.bresp  <= bresp;
        vif.bid    <= wr_req.awid;
        vif.bvalid <= '1;
        @(posedge vif.clk);
        while (vif.bready !== '1) begin
          @(posedge vif.clk);
        end
        vif.bvalid <= '0;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Read Data Channel
  // Fetch read requests provided from the Monitor
  // ---------------------------------------------------------------------------
  protected task get_memory_read_requests();

    vip_axi4_item #(CFG_P) read_item;
    logic unsigned [1 : 0] rresp = VIP_AXI4_RESP_OK_C;
    longint                read_start_index;
    longint                read_stop_index;
    int                    read_range;
    int                    mem_read_delay;

    _rdata_active         = FALSE;
    _current_araddr_start = 0;

    forever begin

      read_item = new();
      fetch_read_request(read_item);

      mem_read_delay = $urandom_range(cfg.mem_max_read_delay, cfg.mem_min_read_delay);
      repeat (mem_read_delay) @(posedge vif.clk);

      read_start_index = unsigned'(read_item.araddr) / CFG_P.VIP_AXI4_STRB_WIDTH_P;
      read_range       = unsigned'(read_item.arlen) + 1;
      read_stop_index  = read_start_index + read_range;

      if (read_start_index > (_memory_depth-1) || read_stop_index > _memory_depth) begin
        `uvm_fatal(get_name(), $sformatf("FATAL [AXI4] Memory range undefined (%0d - %0d)",
        read_start_index, read_stop_index))
      end

      // If we are configured with read errors we might skip the read and return an error
      rresp = VIP_AXI4_RESP_OK_C;
      if (cfg.mem_rd_error_prob != 0) begin
        if (cfg.mem_rd_error_prob >= $urandom_range(100, 1)) begin
          rresp = VIP_AXI4_RESP_SLVERR_C;
        end
      end

      vif.rid   <= read_item.arid;
      vif.rresp <= rresp;

      if (cfg.rvalid_delay_enabled) begin
        fork
          drive_rvalid();
        join_none
      end else begin
        vif.rvalid <= '1;
      end

      // Collision detection
      _rdata_active         = TRUE;
      _current_araddr_start = read_item.araddr;
      _current_araddr_stop  = read_item.araddr + read_item.arlen;

      if (rresp == VIP_AXI4_RESP_OK_C) begin

        for (longint i = read_start_index; i < read_stop_index; i++) begin

          vif.rdata <= _mem.rd_index(i);
          vif.rlast <= (i == read_stop_index-1);

          @(posedge vif.clk);
          while (!(vif.rvalid === '1 && vif.rready === '1)) begin
            @(posedge vif.clk);
          end

          _current_araddr_start += CFG_P.VIP_AXI4_STRB_WIDTH_P;
        end
      end
      else begin
        `uvm_warning(get_name(), $sformatf("WARNING [AXI4] A random read error occured"))
        vif.rdata <= ~vif.rdata;
        vif.rlast <= '1;
        @(posedge vif.clk);
        while (!(vif.rvalid === '1 && vif.rready === '1)) begin
          @(posedge vif.clk);
        end
      end

      if (cfg.rvalid_delay_enabled) begin
        disable fork;
      end

      _rdata_active = FALSE;

      vif.rlast  <= '0;
      vif.rvalid <= '0;

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E: Read Data Channel
  // ---------------------------------------------------------------------------
  protected task drive_rvalid();

    int clock_counter       = 0;
    int rvalid_delay_time   = 0;
    int rvalid_delay_period = $urandom_range(cfg.max_rvalid_delay_period, cfg.min_rvalid_delay_period);

    vif.rvalid <= '1;

    while (1) begin

      @(posedge vif.clk);

      if (vif.rvalid === '1 && vif.rready === '1 && vif.rlast === '1) begin
        vif.rvalid <= '0;
        break;
      end

      clock_counter++;

      if (clock_counter >= rvalid_delay_period &&
          vif.rvalid === '1 && vif.rready === '1) begin
        vif.rvalid         <= '0;
        clock_counter       = 0;
        rvalid_delay_time   = $urandom_range(cfg.max_rvalid_delay_time,   cfg.min_rvalid_delay_time);
        rvalid_delay_period = $urandom_range(cfg.max_rvalid_delay_period, cfg.min_rvalid_delay_period);
        `uvm_info(get_name(), $sformatf("INFO [AXI4] De-asserting 'rvalid' for (%0d) clock periods",
        rvalid_delay_time), UVM_HIGH)
        repeat (rvalid_delay_time) @(posedge vif.clk);
      end
      else begin
        vif.rvalid <= '1;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & UVM_PASSIVE: Read Data Channel
  // Fetches read request that are detected and forwarded by the Monitor
  // ---------------------------------------------------------------------------
  protected task fetch_read_request(output vip_axi4_item #(CFG_P) read_item);

    int random_read_index;
    int arid;

    // Waiting for the OOO queue to contain items
    while (_araddr_queue.size() == 0) begin
      @(posedge vif.clk);
    end

    // In-order bursts
    if (cfg.mem_ooo_queue_size == 0) begin
      read_item = _araddr_queue.pop_front();
    end
    // Out-of-order bursts
    else begin

      random_read_index = $urandom_range(cfg.mem_ooo_queue_size-1, 0);

      if (random_read_index == 0) begin
        read_item = _araddr_queue.pop_front();
        return;
      end

      // Check if the index is out of bound, i.e., is larger than the queue's size
      if (random_read_index >= _araddr_queue.size()) begin
        random_read_index = _araddr_queue.size() - 1;
      end

      // Other than first index (0) queue item: we must fetch the oldest ID
      arid = _araddr_queue[random_read_index].arid;

      // Check in the OOO queue if there are any items with the same ID but
      // with a lower position in the queue because they must be served first
      for (int i = random_read_index-1; i >= 0; i--) begin
        if (_araddr_queue[i].arid == arid) begin
          random_read_index = i;
        end
      end

      // Now we have located the oldest ID
      read_item = _araddr_queue[random_read_index];
      _araddr_queue.delete(random_read_index);

      if (random_read_index != 0) begin
        ooo_counter++;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & UVM_PASSIVE
  // ---------------------------------------------------------------------------
  task fill_read_request_queue();

    vip_axi4_item #(CFG_P) read_item;

    forever begin
      read_item = new();
      _ev_monitor_araddr.wait_on();
      $cast(read_item, _ev_monitor_araddr.get_trigger_data());
      _araddr_queue.push_back(read_item);
      _ev_monitor_araddr.reset();
    end
  endtask

  // ---------------------------------------------------------------------------
  // This function will set all data in the memory to zero
  // ---------------------------------------------------------------------------
  function void memory_reset();
    `uvm_info(get_name(), "INFO [AXI4] Resetting the memory", UVM_LOW)
    _mem.reset();
  endfunction

  // ---------------------------------------------------------------------------
  // This function will randomize all data in the memory
  // ---------------------------------------------------------------------------
  function void memory_randomize();
    _mem.randomize_memory();
  endfunction

  // ---------------------------------------------------------------------------
  // Write an array of data (data) to the memory starting at some address (addr)
  // ---------------------------------------------------------------------------
  function void memory_write(
      logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] addr,
      logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] data[$]
    );

    _mem.wr(addr, data);
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data for an index in the memory array
  // ---------------------------------------------------------------------------
  function logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] memory_read_index(longint index);
    memory_read_index = _mem.rd_index(index);
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data for the entire memory
  // ---------------------------------------------------------------------------
  function mem_get_type_t memory_get();
    return _mem.get();
  endfunction

endclass
