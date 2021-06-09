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

module vip_axi4_sva #(
    parameter vip_axi4_cfg_t CFG_P    = '{default: '0},
    parameter int            WR_SVA_P = 0,
    parameter int            RD_SVA_P = 0
  )(
    // Clock and reset
    input wire                                     clk,
    input wire                                     rst_n,

    // Write Address Channel
    input wire   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] awid,
    input wire [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] awaddr,
    input wire                             [7 : 0] awlen,
    input wire                             [2 : 0] awsize,
    input wire                             [1 : 0] awburst,
    input wire                                     awlock,
    input wire                             [3 : 0] awcache,
    input wire                             [2 : 0] awprot,
    input wire                             [3 : 0] awqos,
    input wire                             [3 : 0] awregion,
    input wire [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] awuser,
    input wire                                     awvalid,
    input wire                                     awready,

    // Write Data Channel
    input wire [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] wdata,
    input wire [CFG_P.VIP_AXI4_STRB_WIDTH_P-1 : 0] wstrb,
    input wire                                     wlast,
    input wire [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] wuser,
    input wire                                     wvalid,
    input wire                                     wready,

    // Write Response Channel
    input wire   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] bid,
    input wire                             [1 : 0] bresp,
    input wire [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] buser,
    input wire                                     bvalid,
    input wire                                     bready,

    // Read Address Channel
    input wire   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] arid,
    input wire [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] araddr,
    input wire                             [7 : 0] arlen,
    input wire                             [2 : 0] arsize,
    input wire                             [1 : 0] arburst,
    input wire                                     arlock,
    input wire                             [3 : 0] arcache,
    input wire                             [2 : 0] arprot,
    input wire                             [3 : 0] arqos,
    input wire                             [3 : 0] arregion,
    input wire [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] aruser,
    input wire                                     arvalid,
    input wire                                     arready,

    // Read Data Channel
    input wire   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] rid,
    input wire [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] rdata,
    input wire                             [1 : 0] rresp,
    input wire                                     rlast,
    input wire [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] ruser,
    input wire                                     rvalid,
    input wire                                     rready
  );

  generate

    if (WR_SVA_P) begin

      vip_axi4_wr_sva #(
        .CFG_P    ( CFG_P    )
      ) vip_axi4_wr_sva_i0 (
        // Clock and reset
        .clk      ( clk      ),
        .rst_n    ( rst_n    ),

        // Write Address Channel
        .awid     ( awid     ),
        .awaddr   ( awaddr   ),
        .awlen    ( awlen    ),
        .awsize   ( awsize   ),
        .awburst  ( awburst  ),
        .awlock   ( awlock   ),
        .awcache  ( awcache  ),
        .awprot   ( awprot   ),
        .awqos    ( awqos    ),
        .awregion ( awregion ),
        .awuser   ( awuser   ),
        .awvalid  ( awvalid  ),
        .awready  ( awready  ),

        // Write Data Channel
        .wdata    ( wdata    ),
        .wstrb    ( wstrb    ),
        .wlast    ( wlast    ),
        .wuser    ( wuser    ),
        .wvalid   ( wvalid   ),
        .wready   ( wready   ),

        // Write Response Channel
        .bid      ( bid      ),
        .bresp    ( bresp    ),
        .buser    ( buser    ),
        .bvalid   ( bvalid   ),
        .bready   ( bready   ),
      );
    end

    if (RD_SVA_P) begin

      module vip_axi4_rd_sva #(
        .CFG_P    ( CFG_P    )
      ) vip_axi4_rd_sva_i0 (
        // Clock and reset
        .clk      ( clk      ),
        .rst_n    ( rst_n    ),

        // Read Address Channel
        .arid     ( arid     ),
        .araddr   ( araddr   ),
        .arlen    ( arlen    ),
        .arsize   ( arsize   ),
        .arburst  ( arburst  ),
        .arlock   ( arlock   ),
        .arcache  ( arcache  ),
        .arprot   ( arprot   ),
        .arqos    ( arqos    ),
        .arregion ( arregion ),
        .aruser   ( aruser   ),
        .arvalid  ( arvalid  ),
        .arready  ( arready  ),

        // Read Data Channel
        .rid      ( rid      ),
        .rdata    ( rdata    ),
        .rresp    ( rresp    ),
        .rlast    ( rlast    ),
        .ruser    ( ruser    ),
        .rvalid   ( rvalid   ),
        .rready   ( rready   ),
      );
    end
  endgenerate

endmodule