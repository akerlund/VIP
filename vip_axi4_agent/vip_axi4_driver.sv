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
// TODO: Unaligned memory addresses
//
////////////////////////////////////////////////////////////////////////////////

class vip_axi4_driver #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_driver #(vip_axi4_item #(CFG_P));

  typedef logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] mem_addr_type_t;

  // Analysis FIFOs connected to the monitor's analysis ports
  uvm_analysis_port     #(vip_axi4_item #(CFG_P)) rd_request_port;
  uvm_tlm_analysis_fifo #(vip_axi4_item #(CFG_P)) rd_response_fifo;

  // Callback
  `uvm_register_cb(vip_axi4_driver #(CFG_P), vip_axi4_driver_callback)

  // Class variables
  protected virtual vip_axi4_if #(CFG_P) vif;
  protected process driver_process;
  protected int id;
  vip_axi4_config cfg;

  // Events from the Monitor and storage queues
  protected string    _ev_id;
  protected uvm_event _ev_monitor_wdata;  // Write request
  protected uvm_event _ev_monitor_araddr; // Read request
  protected vip_axi4_item #(CFG_P) araddr_queue [$];
  protected vip_axi4_item #(CFG_P) wdata_queue  [$];

  // Memory
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _memory [mem_addr_type_t];
  protected int                                       _memory_size;
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _write_row;
            int                                       ooo_counter;

  // Read and Write collision detection
  logic  [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] current_araddr_start;
  logic  [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] current_araddr_stop;
  bool_t                                     rdata_active;


  `uvm_component_param_utils_begin(vip_axi4_driver #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
  `uvm_component_utils_end

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
    rd_request_port  = new("rd_request_port", this);
    rd_response_fifo = new("rd_response_fifo", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);

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
  function void start_of_simulation_phase(uvm_phase phase);

    super.start_of_simulation_phase(phase);

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E) begin
      if (cfg.mem_addr_width != 0) begin
        _memory_size = (2**cfg.mem_addr_width)/CFG_P.VIP_AXI4_STRB_WIDTH_P;
      end
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
      fork
        begin
          @(posedge vif.rst_n);
          driver_start();
          disable fork;
        end
      join
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual protected task driver_start();

    if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E) begin
      fork
        driver_process = process::self();
        mst_get_and_drive();           // Get Write and Read requests
        drive_rready();                // Can be configured to be delayed
      join
    end
    else begin
      if (cfg.mem_slave == TRUE) begin
        fork
          driver_process = process::self();
          get_memory_write_requests(); // Passed from the Monitor via events
          drive_awready();             // De-assert awready when we have recieved too much wdata
          drive_wready();              // Can be configured to be delayed
          get_memory_read_requests();  // Passed from the Monitor via events, stored in an OOO queue
          drive_arready();             // De-assert awready when we have recieved too many requests
          fill_read_request_queue();   // The OOO queue
        join
      end else begin
        fork
          driver_process = process::self();
          slv_get_and_drive();         // Get Response requests
        join
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void handle_reset();
    if (driver_process != null) begin
      driver_process.kill();
    end
    araddr_queue.delete();
    wdata_queue.delete();
    rdata_active = FALSE;
    rd_response_fifo.flush();
    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E && cfg.mem_slave == TRUE) begin
      _ev_monitor_wdata.reset();
      _ev_monitor_araddr.reset();
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Reset VIF
  // ---------------------------------------------------------------------------
  virtual protected task reset_vif();

    if (cfg.vip_axi4_agent_type == VIP_AXI4_MASTER_AGENT_E) begin

      forever begin

        @(negedge vif.rst_n);

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
    end

    if (cfg.vip_axi4_agent_type == VIP_AXI4_SLAVE_AGENT_E) begin

      forever begin

        @(negedge vif.rst_n);

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
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_MASTER_AGENT_E
  // ---------------------------------------------------------------------------
  protected task mst_get_and_drive();

    forever begin

      @(posedge vif.clk);
      seq_item_port.try_next_item(req);

      if (req != null) begin

        if (req.cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) begin
          drive_wr_request();
        end else if (req.cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) begin
          drive_araddr();
        end else begin
          `uvm_fatal(get_name(), "Invalid item type");
        end

        seq_item_port.item_done();
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & ACTIVE
  // ---------------------------------------------------------------------------
  protected task slv_get_and_drive();

    forever begin

      @(posedge vif.clk);
      seq_item_port.try_next_item(req);

      if (req != null) begin

        if (req.cfg.axi4_access != VIP_AXI4_RD_RESPONSE_E) begin
          `uvm_fatal(get_name(), $sformatf("Invalid item type (%s)", req.cfg.axi4_access.name()))
        end

        drive_rdata();
        seq_item_port.item_done();
      end
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

    vif.awvalid  <= '1;
    for (int i = 0; i < _req_queue.size(); i++) begin
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
      while (vif.awready !== '1) begin
        @(posedge vif.clk);
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
            vif.wvalid <= '0;
          end
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

    end

    _req_queue.delete();

    vif.wvalid <= '0;

    if (cfg.wvalid_delay_enabled) begin
      disable fork;
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
      clock_counter++;

      if (clock_counter >= wvalid_delay_period &&
          vif.wvalid === '1 && vif.wready === '1) begin
        vif.wvalid         <= '0;
        clock_counter       = 0;
        wvalid_delay_time   = $urandom_range(cfg.max_wvalid_delay_time,   cfg.min_wvalid_delay_time);
        wvalid_delay_period = $urandom_range(cfg.max_wvalid_delay_period, cfg.min_wvalid_delay_period);
        `uvm_info(get_name(), $sformatf("De-asserting 'wvalid' for (%0d) clock periods", wvalid_delay_time), UVM_HIGH)
        repeat (wvalid_delay_time) @(posedge vif.clk);
      end
      else begin
        vif.wvalid <= '1;
      end

    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & PASSIVE: Write Address Channel - awready
  // ---------------------------------------------------------------------------
  protected task drive_awready();

    forever begin
      @(posedge vif.clk);
      vif.awready <= '1;
      wait (vif.awvalid === '1);
      @(posedge vif.clk);

      if (cfg.mem_awaddr_fifo_size != 0) begin
        while (wdata_queue.size() >= cfg.mem_awaddr_fifo_size) begin
          vif.awready <= '0;
          repeat (cfg.mem_awaddr_fifo_size*10) @(posedge vif.clk);
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & PASSIVE: Write Data Channel - wready
  // ---------------------------------------------------------------------------
  protected task drive_wready();

    if (cfg.wready_delay_enabled) begin
      drive_wready_with_delay();
    end

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
          `uvm_info(get_name(), $sformatf("De-asserting 'wready' for (%0d) clock periods", wready_delay_time), UVM_HIGH)
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

        wait (vif.rvalid === '1 && vif.rready === '1 && vif.rlast === '1);
        while (rd_response_fifo.is_empty()) begin
          @(posedge vif.clk);
        end

        rd_response_fifo.get(_response);
        if (_response == null) begin `uvm_fatal(get_name(), $sformatf("NULL response from the Monitor")) end

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

      seq_item_port.put(rsp);
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & PASSIVE: Read Address Channel
  // ---------------------------------------------------------------------------
  protected task drive_arready();

    forever begin

      @(posedge vif.clk);
      vif.arready <= '1;
      wait (vif.arvalid);
      @(posedge vif.clk);

      if (cfg.mem_araddr_fifo_size != 0) begin
        while (araddr_queue.size() >= cfg.mem_araddr_fifo_size) begin
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
    wait (vif.arvalid === '1); // Only start if the Agent requests a read
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
          `uvm_info(get_name(), $sformatf("De-asserting 'rready' for (%0d) clock periods", rready_delay_time), UVM_HIGH)
          repeat (rready_delay_time) @(posedge vif.clk);

          vif.rready <= '1;

        end
        @(posedge vif.clk);
      end
      vif.rready <= '0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // VIP_AXI4_SLAVE_AGENT_E & PASSIVE: Write Data Channel
  // ---------------------------------------------------------------------------
  protected task get_memory_write_requests();

    vip_axi4_item #(CFG_P) wr_req;

    int memory_start_index = 0;
    int write_range        = 0;
    int memory_stop_index  = 0;
    int write_counter      = 0;
    wr_req = new();

    forever begin

      _ev_monitor_wdata.wait_on();

      if (cfg.mem_enabled == TRUE) begin

        if (!$cast(wr_req, _ev_monitor_wdata.get_trigger_data())) begin
          `uvm_fatal(get_name(), $sformatf("Casting write trigger data failed"))
        end else if (wr_req == null) begin
          `uvm_fatal(get_name(), $sformatf("Casting resulted in a NULL object"))
        end

        _ev_monitor_wdata.reset();

        memory_start_index = unsigned'(wr_req.awaddr) / CFG_P.VIP_AXI4_STRB_WIDTH_P;
        write_range        = unsigned'(wr_req.awlen) + 1;
        memory_stop_index  = memory_start_index + write_range;

        // Collision detection
        vif.bresp <= VIP_AXI4_RESP_OK_C;
        if (rdata_active == TRUE) begin
          if (wr_req.awaddr >= current_araddr_start &&
              wr_req.awaddr + wr_req.awlen <= current_araddr_stop) begin
            `uvm_warning(get_name(), $sformatf("Collision detected: awaddr(%h), araddr(%h)", wr_req.awaddr, current_araddr_start))
            vif.bresp <= VIP_AXI4_RESP_SLVERR_C;
          end
        end

        if (memory_start_index > (_memory_size-1) || memory_stop_index > _memory_size) begin
          `uvm_fatal(get_name(), $sformatf("MEM: Memory range undefined (%0d - %0d)", memory_start_index, memory_stop_index))
        end

        // Writing the data to memory
        write_counter = 0;
        for (int i = memory_start_index; i < memory_stop_index; i++) begin

          if (wr_req.wstrb[write_counter] == '1) begin

            if (cfg.mem_x_wr_severity != VIP_AXI4_X_WR_IGNORE_E) begin
              if (^wr_req.wdata[write_counter] === 1'bX) begin
                if (cfg.mem_x_wr_severity == VIP_AXI4_X_WR_WARNING_E) begin
                  `uvm_warning(get_name(), $sformatf("MEM: Writing X to index (%0d), address = (%h)", memory_start_index, wr_req.awaddr))
                end else begin
                  `uvm_fatal(get_name(), $sformatf("MEM: Writing X to index (%0d), address = (%h)", memory_start_index, wr_req.awaddr))
                end
              end
            end

            _memory[i] = wr_req.wdata[write_counter];

          end
          else begin

            // Only writing bytes that have 'wstrb' high
            _write_row = '0;

            for (int s = 0; s < CFG_P.VIP_AXI4_STRB_WIDTH_P; s++) begin

              if (wr_req.wstrb[write_counter][s]) begin

                if (cfg.mem_x_wr_severity != VIP_AXI4_X_WR_IGNORE_E) begin
                  if (^wr_req.wdata[write_counter][8*s +: 8] === 1'bX) begin
                    if (cfg.mem_x_wr_severity == VIP_AXI4_X_WR_WARNING_E) begin
                      `uvm_warning(get_name(), $sformatf("MEM: Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, wr_req.awaddr, s))
                    end else begin
                      `uvm_fatal(get_name(), $sformatf("MEM: Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, wr_req.awaddr, s))
                    end
                  end
                end

                _write_row[8*s +: 8] = wr_req.wdata[write_counter][8*s +: 8];

              end
              else begin

                if (!_memory.exists(i)) begin
                  _write_row[8*s +: 8] = '0;
                end
                else if (^_memory[i][8*s +: 8] === 1'bX) begin
                  _write_row[8*s +: 8] = '0;
                end
                else begin
                  _write_row[8*s +: 8] = _memory[i][8*s +: 8];
                end
              end
            end

            _memory[i] = _write_row;
          end
          write_counter++;
        end
      end

      if (cfg.bresp_enabled) begin
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
  // VIP_AXI4_SLAVE_AGENT_E & PASSIVE: Read Data Channel
  // Fetch read requests provided from the Monitor
  // ---------------------------------------------------------------------------
  protected task get_memory_read_requests();

    vip_axi4_item #(CFG_P) read_item;
    int read_start_index;
    int read_stop_index;
    int read_range;
    int mem_read_delay;

    rdata_active         = FALSE;
    current_araddr_start = 0;

    forever begin

      read_item = new();
      fetch_read_request(read_item);

      mem_read_delay = $urandom_range(cfg.mem_max_read_delay, cfg.mem_min_read_delay);
      repeat (mem_read_delay) @(posedge vif.clk);

      read_start_index = unsigned'(read_item.araddr) / CFG_P.VIP_AXI4_STRB_WIDTH_P;
      read_range       = unsigned'(read_item.arlen) + 1;
      read_stop_index  = read_start_index + read_range;

      if (read_start_index > (_memory_size-1) || read_stop_index > _memory_size) begin
        `uvm_fatal(get_name(), $sformatf("MEM: Memory range undefined (%0d - %0d)", read_start_index, read_stop_index))
      end

      vif.rid   <= read_item.arid;
      vif.rresp <= VIP_AXI4_RESP_OK_C;

      if (cfg.rvalid_delay_enabled) begin
        fork
          drive_rvalid();
        join_none
      end else begin
        vif.rvalid <= '1;
      end

      // Collision detection
      rdata_active         = TRUE;
      current_araddr_start = read_item.araddr;
      current_araddr_stop  = read_item.araddr + read_item.arlen;

      for (int i = read_start_index; i < read_stop_index; i++) begin

        if (!_memory.exists(i)) begin
          vif.rdata <= '0;
        end else begin
          vif.rdata <= _memory[i];
        end

        vif.rlast <= (i == read_stop_index-1);

        @(posedge vif.clk);
        while (!(vif.rvalid === '1 && vif.rready === '1)) begin
          @(posedge vif.clk);
        end

        current_araddr_start += CFG_P.VIP_AXI4_STRB_WIDTH_P;
      end

      rdata_active = FALSE;

      vif.rlast  <= '0;
      vif.rvalid <= '0;

      if (cfg.rvalid_delay_enabled) begin
        disable fork;
      end
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
        @(posedge vif.clk);
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
        `uvm_info(get_name(), $sformatf("De-asserting 'rvalid' for (%0d) clock periods", rvalid_delay_time), UVM_HIGH)
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
    while (araddr_queue.size() == 0) begin
      repeat (10) @(posedge vif.clk);
    end

    // In-order bursts
    if (cfg.mem_ooo_queue_size == 0) begin
      read_item = araddr_queue.pop_front();
    end
    // Out-of-order bursts
    else begin

      random_read_index = $urandom_range(cfg.mem_ooo_queue_size-1, 0);

      if (random_read_index == 0) begin
        read_item = araddr_queue.pop_front();
        return;
      end

      // Check if the index is out of bound, i.e., is larger than the queue's size
      if (random_read_index >= araddr_queue.size()) begin
        random_read_index = araddr_queue.size() - 1;
      end

      // Other than first index (0) queue item: we must fetch the oldest ID
      arid = araddr_queue[random_read_index].arid;

      // Check in the OOO queue if there are any items with the same ID but
      // with a lower position in the queue because they must be served first
      for (int i = random_read_index-1; i >= 0; i--) begin
        if (araddr_queue[i].arid == arid) begin
          random_read_index = i;
        end
      end

      // Now we have located the oldest ID
      read_item = araddr_queue[random_read_index];
      araddr_queue.delete(random_read_index);

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
      araddr_queue.push_back(read_item);
      _ev_monitor_araddr.reset();
    end
  endtask

  // ---------------------------------------------------------------------------
  // This function will set all data in the memory to zero
  // ---------------------------------------------------------------------------
  function void memory_reset();
    `uvm_info(get_name(), "Resetting the memory", UVM_LOW)
    _memory.delete();
  endfunction

  // ---------------------------------------------------------------------------
  // This function will randomize all data in the memory
  // ---------------------------------------------------------------------------
  function void memory_randomize();
    logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _r;
    for (int i = 0; i < (2**cfg.mem_addr_width)/CFG_P.VIP_AXI4_STRB_WIDTH_P; i++) begin
      void'(std::randomize(_r));
      _memory[i] = _r;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Write an array of data (data) to the memory starting at some address (addr)
  // ---------------------------------------------------------------------------
  function void memory_write(logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] addr,
                             logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] data[$]);

    int memory_start_index = unsigned'(addr) / CFG_P.VIP_AXI4_STRB_WIDTH_P;
    int memory_stop_index  = memory_start_index + data.size() - 1;

    foreach (data[i]) begin
      _memory[memory_start_index + i] = data[i];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data for an index in the memory array
  // ---------------------------------------------------------------------------
  function logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] memory_read_index(int index);
    if (!_memory.exists(index)) begin
      memory_read_index = '0;
    end else begin
      memory_read_index = _memory[index];
    end
  endfunction

endclass
