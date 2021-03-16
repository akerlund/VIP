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

interface axi_cfg_if #(
    parameter int AXI4_ID_WIDTH_P   = -1,
    parameter int AXI4_ADDR_WIDTH_P = -1,
    parameter int AXI4_DATA_WIDTH_P = -1,
    parameter int AXI4_STRB_WIDTH_P = -1
  )(input logic clk, input logic rst_n);

  // Write Address Channel
  logic [AXI4_ADDR_WIDTH_P-1 : 0] awaddr;
  logic                           awvalid;
  logic                           awready;

  // Write Data Channel
  logic [AXI4_DATA_WIDTH_P-1 : 0] wdata;
  logic [AXI4_STRB_WIDTH_P-1 : 0] wstrb;
  logic                           wlast;
  logic                           wvalid;
  logic                           wready;

  // Write Response Channel
  logic                   [1 : 0] bresp;
  logic                           bvalid;
  logic                           bready;

  // Read Address Channel
  logic [AXI4_ADDR_WIDTH_P-1 : 0] araddr;
  logic                   [7 : 0] arlen;
  logic                           arvalid;
  logic                           arready;

  // Read Data Channel
  logic   [AXI4_ID_WIDTH_P-1 : 0] rid;
  logic [AXI4_DATA_WIDTH_P-1 : 0] rdata;
  logic                   [1 : 0] rresp;
  logic                           rlast;
  logic                           rvalid;
  logic                           rready;

  modport master(

    // Clock and reset
    input  clk,
    input  rst_n,

    // Write Address Channel
    output awaddr,
    output awvalid,
    input  awready,

    // Write Data Channel
    output wdata,
    output wstrb,
    output wlast,
    output wvalid,
    input  wready,

    // Write Response Channel
    input  bresp,
    input  bvalid,
    output bready,

    // Read Address Channel
    output araddr,
    output arlen,
    output arvalid,
    input  arready,

    // Read Data Channel
    input  rid,
    input  rdata,
    input  rresp,
    input  rlast,
    input  rvalid,
    output rready
  );

  modport slave(

    // Clock and reset
    input  clk,
    input  rst_n,

    // Write Address Channel
    input  awaddr,
    input  awvalid,
    output awready,

    // Write Data Channel
    input  wdata,
    input  wstrb,
    input  wlast,
    input  wvalid,
    output wready,

    // Write Response Channel
    output bresp,
    output bvalid,
    input  bready,

    // Read Address Channel
    input  araddr,
    input  arlen,
    input  arvalid,
    output arready,

    // Read Data Channel
    output rid,
    output rdata,
    output rresp,
    output rlast,
    output rvalid,
    input  rready
  );

endinterface
