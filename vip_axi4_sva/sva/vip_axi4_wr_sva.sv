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

module vip_axi4_wr_sva #(
    parameter vip_axi4_cfg_t CFG_P = '{default: '0}
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
    input wire                                     bready
  );

  default clocking clock @(posedge clk);
  endclocking
  default disable iff !rst_n;


  // ---------------------------------------------------------------------------
  // Functional Rules - Write Address Channel
  // ---------------------------------------------------------------------------

  logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _awaddr_end;
  always @(awsize or awlen or awaddr) begin
    _awaddr_end = awaddr + (awlen << awsize); // End address
  end

  property VIP_AXI4_AWADDR_BOUNDARY_PR;
    awvalid && (awburst == VIP_AXI4_BURST_INCR_C) && !($isunknown({awvalid, awburst, awaddr}))
    |-> (_awaddr_end[CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 12] == awaddr[CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 12]);
  endproperty
  VIP_AXI4_AWADDR_BOUNDARY_ERROR: assert property (VIP_AXI4_AWADDR_BOUNDARY_PR) else
    $error("VIP_AXI4_AWADDR_BOUNDARY_PR: A burst must not cross a 4kB boundary. Spec: section A3.4.1.");


  logic [6 : 0] _wr_mask_aligned;
  always @(awsize or awvalid) begin
    if (awvalid) begin
      case (awsize)
        VIP_AXI4_SIZE_128B_C: _wr_mask_aligned = 7'b0000000;
        VIP_AXI4_SIZE_64B_C:  _wr_mask_aligned = 7'b1000000;
        VIP_AXI4_SIZE_32B_C:  _wr_mask_aligned = 7'b1100000;
        VIP_AXI4_SIZE_16B_C:  _wr_mask_aligned = 7'b1110000;
        VIP_AXI4_SIZE_8B_C:   _wr_mask_aligned = 7'b1111000;
        VIP_AXI4_SIZE_4B_C:   _wr_mask_aligned = 7'b1111100;
        VIP_AXI4_SIZE_2B_C:   _wr_mask_aligned = 7'b1111110;
        VIP_AXI4_SIZE_1B_C:   _wr_mask_aligned = 7'b1111111;
        default:              _wr_mask_aligned = 7'b1111111;
      endcase
    end else begin
      _wr_mask_aligned = 7'b1111111;
    end
  end


  property VIP_AXI4_AWADDR_WRAP_ALIGN_PR;
    awvalid && (awburst == VIP_AXI4_BURST_WRAP_C) && !($isunknown({awvalid, awburst, awaddr}))
    |-> ((awaddr[6 : 0] & _wr_mask_aligned) == awaddr[6 : 0]);
  endproperty
  VIP_AXI4_AWADDR_WRAP_ALIGN_ERROR: assert property (VIP_AXI4_AWADDR_WRAP_ALIGN_PR) else
    $error("VIP_AXI4_AWADDR_WRAP_ALIGN_PR: For a wrapping burst, the start address must be aligned to the size of each transfer. Spec: section A3.4.1.");


  property VIP_AXI4_AWBURST_PR;
    awvalid && !($isunknown({awvalid, awburst}))
    |-> (awburst != 2'b11);
  endproperty
  VIP_AXI4_AWBURST_ERROR: assert property (VIP_AXI4_AWBURST_PR) else
    $error("VIP_AXI4_AWBURST_PR: When AWVALID is high, a value of 2'b11 on AWBURST is reserved. Spec: table A3-3.");


  property VIP_AXI4_AWLEN_LOCK_PR;
    awvalid && (awlen > 8'b00001111) && !($isunknown({awvalid, awlen, awlock}))
    |-> (awlock != 1'b1);
  endproperty
  VIP_AXI4_AWLEN_LOCK_ERROR: assert property (VIP_AXI4_AWLEN_LOCK_PR) else
    $error("VIP_AXI4_AWLEN_LOCK_PR: Exclusive access transactions cannot have a length greater than 16 beats. Spec: section A7.2.4.");


  property VIP_AXI4_AWLEN_FIXED_PR;
    awvalid && (awlen > 8'b00001111) && !($isunknown({awvalid, awlen, awburst}))
    |-> (awburst != VIP_AXI4_BURST_FIXED_C);
  endproperty
  VIP_AXI4_AWLEN_FIXED_ERROR: assert property (VIP_AXI4_AWLEN_FIXED_PR) else
    $error("VIP_AXI4_AWLEN_FIXED_PR: Transactions of burst type FIXED cannot have a length greater than 16 beats. Spec: section A3.4.1.");


  property VIP_AXI4_AWLEN_WRAP_PR;
    awvalid && (awburst == VIP_AXI4_BURST_WRAP_C) && !($isunknown({awvalid, awburst, awlen}))
    |-> (awlen == 8'b00000001 ||
        awlen == 8'b00000011 ||
        awlen == 8'b00000111 ||
        awlen == 8'b00001111);
  endproperty
  VIP_AXI4_AWLEN_WRAP_ERROR: assert property (VIP_AXI4_AWLEN_WRAP_PR) else
    $error("VIP_AXI4_AWLEN_WRAP_PR: For a wrapping burst, the length of the burst must be 2, 4, 8 or 16 transfers. Spec: section A3.4.1.");


  logic [10 : 0] _awsize;
  always @(awsize) begin
    _awsize = (11'b000_0000_1000 << awsize); // 8 x awsize bytes
  end

  property VIP_AXI4_AWSIZE_PR;
    awvalid && !($isunknown({awvalid, awsize}))
    |-> (_awsize <= CFG_P.VIP_AXI4_DATA_WIDTH_P);
  endproperty
  VIP_AXI4_AWSIZE_ERROR: assert property (VIP_AXI4_AWSIZE_PR) else
    $error("VIP_AXI4_AWSIZE_PR: The size of any transfer must not exceed the data bus width of either agent in the transaction. Spec: section A3.4.1.");


  property VIP_AXI4_AWVALID_RESET_PR;
    !(rst_n) && !($isunknown(rst_n))
    ##1 rst_n
    |-> !awvalid;
  endproperty
  VIP_AXI4_AWVALID_RESET_ERROR: assert property (VIP_AXI4_AWVALID_RESET_PR) else
    $error("VIP_AXI4_AWVALID_RESET_PR: The earliest point after reset that a master is permitted to begin driving ARVALID, AWVALID, or WVALID HIGH is at a rising ACLK edge after ARESETn is HIGH. Spec: Figure A3-1.");

  // ---------------------------------------------------------------------------
  // Handshake Rules - Write Address Channel
  // ---------------------------------------------------------------------------

  property VIP_AXI4_AWADDR_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awaddr}))
    ##1 rst_n
    |-> $stable(awaddr);
  endproperty
  VIP_AXI4_AWADDR_STABLE_ERROR: assert property (VIP_AXI4_AWADDR_STABLE_PR) else
    $error("VIP_AXI4_AWADDR_STABLE_PR: AWADDR must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWBURST_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awburst}))
    ##1 rst_n
    |-> $stable(awburst);
  endproperty
  VIP_AXI4_AWBURST_STABLE_ERROR: assert property (VIP_AXI4_AWBURST_STABLE_PR) else
    $error("VIP_AXI4_AWBURST_STABLE_PR: AWBURST must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWID_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awid}))
    ##1 rst_n
    |-> $stable(awid);
  endproperty
  VIP_AXI4_AWID_STABLE_ERROR: assert property (VIP_AXI4_AWID_STABLE_PR) else
    $error("VIP_AXI4_AWID_STABLE_PR: AWID must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWLEN_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awlen}))
    ##1 rst_n
    |-> $stable(awlen);
  endproperty
  VIP_AXI4_AWLEN_STABLE_ERROR: assert property (VIP_AXI4_AWLEN_STABLE_PR) else
    $error("VIP_AXI4_AWLEN_STABLE_PR: AWLEN must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWLOCK_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awlock}))
    ##1 rst_n
    |-> $stable(awlock);
  endproperty
  VIP_AXI4_AWLOCK_STABLE_ERROR: assert property (VIP_AXI4_AWLOCK_STABLE_PR) else
    $error("VIP_AXI4_AWLOCK_STABLE_PR: AWLOCK must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWSIZE_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awsize}))
    ##1 rst_n
    |-> $stable(awsize);
  endproperty
  VIP_AXI4_AWSIZE_STABLE_ERROR: assert property (VIP_AXI4_AWSIZE_STABLE_PR) else
    $error("VIP_AXI4_AWSIZE_STABLE_PR: AWSIZE must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWQOS_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready, awqos}))
    ##1 rst_n
    |-> $stable(awqos);
  endproperty
  VIP_AXI4_AWQOS_STABLE_ERROR: assert property (VIP_AXI4_AWQOS_STABLE_PR) else
    $error("VIP_AXI4_AWQOS_STABLE_PR: AWQOS must remain stable when AWVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWREGION_STABLE_PR;
  awvalid && !awready && !($isunknown({awvalid, awready, awregion}))
    ##1 rst_n
    |-> $stable(awregion);
  endproperty
  VIP_AXI4_AWREGION_STABLE_ERROR: assert property (VIP_AXI4_AWREGION_STABLE_PR) else
    $error("VIP_AXI4_AWREGION_STABLE_PR: AWREGION must remain stable when ARVALID is asserted and AWREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_AWVALID_STABLE_PR;
    awvalid && !awready && !($isunknown({awvalid, awready}))
    ##1 rst_n
    |-> awvalid;
  endproperty
  VIP_AXI4_AWVALID_STABLE_ERROR: assert property (VIP_AXI4_AWVALID_STABLE_PR) else
    $error("VIP_AXI4_AWVALID_STABLE_PR: Once AWVALID is asserted, it must remain asserted until AWREADY is high. Spec: section A3.2.2.");

  // ---------------------------------------------------------------------------
  // X-Propagation Rules - Write Address Channel
  // ---------------------------------------------------------------------------

  `ifdef VIP_AXI4_X_PROPAGATION
  `endif

  // ---------------------------------------------------------------------------
  // Functional Rules - Write Data Channel
  // ---------------------------------------------------------------------------

  // TODO
  // Page 129
  // valid && ready && !last |-> (valid && ready) [=awlen] [1:$] (valid && ready && last)
  // $error("The number of write data items must match AWLEN for the corresponding address. Spec: section A3.4.1.");

  // ---------------------------------------------------------------------------
  // Handshake Rules - Write Data Channel
  // ---------------------------------------------------------------------------

  //property VIP_AXI4_WDATA_STABLE_PR;
  //endproperty
  //VIP_AXI4_WDATA_STABLE_ERROR: assert property (VIP_AXI4_WDATA_STABLE_PR) else
  //  $error("VIP_AXI4_WDATA_STABLE_PR: WDATA must remain stable when WVALID is asserted and WREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_WLAST_STABLE_PR;
    wvalid && !wready && !($isunknown({wvalid, wready, wlast}))
    ##1 rst_n
    |-> $stable(wlast);
  endproperty
  VIP_AXI4_WLAST_STABLE_ERROR: assert property (VIP_AXI4_WLAST_STABLE_PR) else
    $error("VIP_AXI4_WLAST_STABLE_PR: WLAST must remain stable when WVALID is asserted and WREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_WSTRB_STABLE_PR;
    wvalid && !wready && !($isunknown({wvalid, wready, wstrb}))
    ##1 rst_n
    |-> $stable(wstrb);
  endproperty
  VIP_AXI4_WSTRB_STABLE_ERROR: assert property (VIP_AXI4_WSTRB_STABLE_PR) else
    $error("VIP_AXI4_WSTRB_STABLE_PR: WSTRB must remain stable when WVALID is asserted and WREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_WVALID_STABLE_PR;
    wvalid && !wready && !($isunknown({wvalid,wready}))
    ##1 rst_n
    |-> wvalid;
  endproperty
  VIP_AXI4_WVALID_STABLE_ERROR: assert property (VIP_AXI4_WVALID_STABLE_PR) else
    $error("VIP_AXI4_WVALID_STABLE_PR: Once WVALID is asserted, it must remain asserted until WREADY is high. Spec: section A3.2.2.");

  // ---------------------------------------------------------------------------
  // X-Propagation Rules - Write Data Channel
  // ---------------------------------------------------------------------------

  `ifdef VIP_AXI4_X_PROPAGATION
  `endif

  // ---------------------------------------------------------------------------
  // Functional Rules - Write Response Channel
  // ---------------------------------------------------------------------------

  property VIP_AXI4_BVALID_RESET_PR;
    !(rst_n) && !($isunknown(rst_n))
    ##1 rst_n
    |-> !bvalid;
  endproperty
  VIP_AXI4_BVALID_RESET_ERROR: assert property (VIP_AXI4_BVALID_RESET_PR) else
    $error("VIP_AXI4_BVALID_RESET_PR: The earliest point after reset that a master is permitted to begin driving ARVALID, AWVALID, or WVALID HIGH is at a rising ACLK edge after ARESETn is HIGH. Spec: Figure A3-1.");

  // ---------------------------------------------------------------------------
  // Handshake Rules - Write Response Channel
  // ---------------------------------------------------------------------------

  property VIP_AXI4_BID_STABLE_PR;
    bvalid && !bready && !($isunknown({bvalid, bready, bid}))
    ##1 rst_n
    |-> $stable(bid);
  endproperty
  VIP_AXI4_BID_STABLE_ERROR: assert property (VIP_AXI4_BID_STABLE_PR) else
    $error("VIP_AXI4_BID_STABLE_PR: BID must remain stable when BVALID is asserted and BREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_BRESP_STABLE_PR;
    bvalid && !bready && !($isunknown({bvalid, bready, bresp}))
    ##1 rst_n
    |-> $stable(bresp);
  endproperty
  VIP_AXI4_BRESP_STABLE_ERROR: assert property (VIP_AXI4_BRESP_STABLE_PR) else
    $error("VIP_AXI4_BRESP_STABLE_PR: BRESP must remain stable when BVALID is asserted and BREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_BVALID_STABLE_PR;
    bvalid && !bready && !($isunknown({bvalid, bready}))
    ##1 rst_n
    |-> bvalid;
  endproperty
  VIP_AXI4_BVALID_STABLE_ERROR: assert property (VIP_AXI4_BVALID_STABLE_PR) else
    $error("VIP_AXI4_BVALID_STABLE_PR: Once BVALID is asserted, it must remain asserted until BREADY is high. Spec: section A3.2.2.");

  // ---------------------------------------------------------------------------
  // X-Propagation Rules - Write Response Channel
  // ---------------------------------------------------------------------------

  `ifdef VIP_AXI4_X_PROPAGATION
  `endif

endmodule
