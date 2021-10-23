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

class vip_axi4_config extends uvm_object;

  // ---------------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------------

  uvm_active_passive_enum is_active           = UVM_ACTIVE;
  vip_axi4_agent_type_t   vip_axi4_agent_type = VIP_AXI4_MASTER_AGENT_E;
  bool_t                  monitor_disabled    = FALSE;
  // Merge Read Data bus with Read Address bus using arid and rid to locate
  // respective transaction in a saved array. Disable this the Agent is used
  /// as a Slave to stimulate Read Data Channel only.
  bool_t                  monitor_merge_reads = TRUE;
  bool_t                  bresp_enabled       = TRUE;

  // Set this false if the Agent is used with UVM register models.
  // The built in register tests does not pop the response queue, so they yield
  // errors, i.e., "Response queue overflow".
  bool_t                  drv_put_rsp_in_port = TRUE;

  // ---------------------------------------------------------------------------
  // Memory Config
  // ---------------------------------------------------------------------------

  vip_axi4_x_severity_t mem_x_wr_severity = VIP_AXI4_X_WR_IGNORE_E; // Allow writing X or not

  bool_t mem_enabled          = TRUE;
  bool_t mem_slave            = FALSE;
  int    mem_addr_width       = 0;
  int    mem_awaddr_fifo_size = 0;   // Will cause backpressure
  int    mem_araddr_fifo_size = 0;   // Will cause backpressure
  int    mem_ooo_queue_size   = 0;   // Out-of-order queue
  int    mem_min_read_delay   = 0.0; // Delay before a read response start
  int    mem_max_read_delay   = 0.0; //

  // ---------------------------------------------------------------------------
  // Delays on "xvalid" and "xready" signals.
  // Time:   How long a signal is low (clock periods).
  // Period: How long until a signal is set low (clock periods).
  // ---------------------------------------------------------------------------
  bool_t awvalid_delay_enabled    = FALSE; // Master write
  int    min_awvalid_delay_time   = 1;
  int    max_awvalid_delay_time   = 10;
  int    min_awvalid_delay_period = 10;
  int    max_awvalid_delay_period = 256;
  bool_t wvalid_delay_enabled     = TRUE; // Master write
  int    min_wvalid_delay_time    = 1;
  int    max_wvalid_delay_time    = 10;
  int    min_wvalid_delay_period  = 10;
  int    max_wvalid_delay_period  = 256;
  bool_t wready_delay_enabled     = TRUE; // Slave write
  int    min_wready_delay_time    = 1;
  int    max_wready_delay_time    = 10;
  int    min_wready_delay_period  = 10;
  int    max_wready_delay_period  = 256;
  bool_t rready_delay_enabled     = TRUE; // Master read
  int    min_rready_delay_time    = 1;
  int    max_rready_delay_time    = 10;
  int    min_rready_delay_period  = 10;
  int    max_rready_delay_period  = 256;
  bool_t rvalid_delay_enabled     = TRUE; // Slave read
  int    min_rvalid_delay_time    = 1;
  int    max_rvalid_delay_time    = 10;
  int    min_rvalid_delay_period  = 10;
  int    max_rvalid_delay_period  = 256;

  `uvm_object_utils_begin(vip_axi4_config);
    `uvm_field_enum(uvm_active_passive_enum,  is_active,            UVM_ALL_ON)
    `uvm_field_enum(vip_axi4_agent_type_t,    vip_axi4_agent_type,  UVM_ALL_ON)
    `uvm_field_enum(bool_t,                   monitor_disabled,     UVM_ALL_ON)
    `uvm_field_enum(bool_t,                   monitor_merge_reads,  UVM_ALL_ON)
    `uvm_field_enum(bool_t,                   bresp_enabled,        UVM_ALL_ON)
    `uvm_field_enum(vip_axi4_x_severity_t,    mem_x_wr_severity,    UVM_ALL_ON)
    `uvm_field_enum(bool_t,                   mem_enabled,          UVM_ALL_ON)
    `uvm_field_enum(bool_t,                   mem_slave,            UVM_ALL_ON)
    `uvm_field_int(mem_addr_width,                                  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(mem_awaddr_fifo_size,                            UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(mem_araddr_fifo_size,                            UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(mem_ooo_queue_size,                              UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(mem_min_read_delay,                              UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(mem_max_read_delay,                              UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                  awvalid_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_awvalid_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_awvalid_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_awvalid_delay_period,                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_awvalid_delay_period,                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                   wvalid_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_wvalid_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_wvalid_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_wvalid_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_wvalid_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                   wready_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_wready_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_wready_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_wready_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_wready_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                   rready_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_rready_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_rready_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_rready_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_rready_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                   rvalid_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_rvalid_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_rvalid_delay_time,                           UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_rvalid_delay_period,                         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_rvalid_delay_period,                         UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end;

  function new(string name = "vip_axi4_config");
    super.new(name);
  endfunction

endclass
