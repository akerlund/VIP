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

`ifndef VIP_AXI4_IF
`define VIP_AXI4_IF

import vip_axi4_types_pkg::*;

interface vip_axi4_if #(
  parameter vip_axi4_cfg_t CFG_P = '{default: '0}
  )(
    input clk,
    input rst_n
  );

  // Write Address Channel
  logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] awid;
  logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] awaddr;
  logic                             [7 : 0] awlen;
  logic                             [2 : 0] awsize;
  logic                             [1 : 0] awburst;
  logic                                     awlock;
  logic                             [3 : 0] awcache;
  logic                             [2 : 0] awprot;
  logic                             [3 : 0] awqos;
  logic                             [3 : 0] awregion;
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] awuser;
  logic                                     awvalid;
  logic                                     awready;

  // Write Data Channel
  logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] wdata;
  logic [CFG_P.VIP_AXI4_STRB_WIDTH_P-1 : 0] wstrb;
  logic                                     wlast;
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] wuser;
  logic                                     wvalid;
  logic                                     wready;

  // Write Response Channel
  logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] bid;
  logic                             [1 : 0] bresp;
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] buser;
  logic                                     bvalid;
  logic                                     bready;

  // Read Address Channel
  logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] arid;
  logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] araddr;
  logic                             [7 : 0] arlen;
  logic                             [2 : 0] arsize;
  logic                             [1 : 0] arburst;
  logic                                     arlock;
  logic                             [3 : 0] arcache;
  logic                             [2 : 0] arprot;
  logic                             [3 : 0] arqos;
  logic                             [3 : 0] arregion;
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] aruser;
  logic                                     arvalid;
  logic                                     arready;

  // Read Data Channel
  logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] rid;
  logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] rdata;
  logic                             [1 : 0] rresp;
  logic                                     rlast;
  logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] ruser;
  logic                                     rvalid;
  logic                                     rready;

  task sink_write_channel();
    assign awid     = '0;
    assign awaddr   = '0;
    assign awlen    = '0;
    assign awsize   = '0;
    assign awburst  = '0;
    assign awlock   = '0;
    assign awcache  = '0;
    assign awprot   = '0;
    assign awqos    = '0;
    assign awregion = '0;
    assign awuser   = '0;
    assign awvalid  = '0;
    assign awready  = '0;
    assign wdata    = '0;
    assign wstrb    = '0;
    assign wlast    = '0;
    assign wuser    = '0;
    assign wvalid   = '0;
    assign wready   = '0;
    assign bid      = '0;
    assign bresp    = '0;
    assign buser    = '0;
    assign bvalid   = '0;
    assign bready   = '0;
  endtask

  task sink_read_channel();
    assign arid     = '0;
    assign araddr   = '0;
    assign arlen    = '0;
    assign arsize   = '0;
    assign arburst  = '0;
    assign arlock   = '0;
    assign arcache  = '0;
    assign arprot   = '0;
    assign arqos    = '0;
    assign arregion = '0;
    assign aruser   = '0;
    assign arvalid  = '0;
    assign arready  = '0;
    assign rid      = '0;
    assign rdata    = '0;
    assign rresp    = '0;
    assign rlast    = '0;
    assign ruser    = '0;
    assign rvalid   = '0;
    assign rready   = '0;
  endtask

  task sink_read_address_channel();
    assign arid     = '0;
    assign araddr   = '0;
    assign arlen    = '0;
    assign arsize   = '0;
    assign arburst  = '0;
    assign arlock   = '0;
    assign arcache  = '0;
    assign arprot   = '0;
    assign arqos    = '0;
    assign arregion = '0;
    assign aruser   = '0;
    assign arvalid  = '0;
    assign arready  = '0;
  endtask

endinterface

`endif
