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

module vip_axi4_rd_sva #(
    parameter vip_axi4_cfg_t CFG_P = '{default: '0}
  )(
    // Clock and reset
    input wire                                     clk,
    input wire                                     rst_n,

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

  default clocking clock @(posedge clk);
  endclocking
  default disable iff !rst_n;

  // ---------------------------------------------------------------------------
  // Functional Rules - Read Address Channel
  // ---------------------------------------------------------------------------

  logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _araddr_end;
  always @(arsize or arlen or araddr) begin
    _araddr_end = araddr + (arlen << arsize);  // End address
  end


  property VIP_AXI4_ARADDR_BOUNDARY_PR;
    arvalid && (arburst == VIP_AXI4_BURST_INCR_C) && !($isunknown({arvalid, arburst, araddr}))
    |-> (_araddr_end[CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 12] == araddr[CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 12]);
  endproperty
  VIP_AXI4_ARADDR_BOUNDARY_PR: assert property (VIP_AXI4_ARADDR_BOUNDARY_PR) else
    $error("VIP_AXI4_ARADDR_BOUNDARY_PR: A burst must not cross a 4kbyte boundary. Spec: section A3.4.1.");

    logic [6 : 0] _rd_mask_aligned;
    always @(arsize or arvalid) begin
      if (arvalid) begin
        case (arsize)
          VIP_AXI4_SIZE_128B_C: _rd_mask_aligned = 7'b0000000;
          VIP_AXI4_SIZE_64B_C:  _rd_mask_aligned = 7'b1000000;
          VIP_AXI4_SIZE_32B_C:  _rd_mask_aligned = 7'b1100000;
          VIP_AXI4_SIZE_16B_C:  _rd_mask_aligned = 7'b1110000;
          VIP_AXI4_SIZE_8B_C:   _rd_mask_aligned = 7'b1111000;
          VIP_AXI4_SIZE_4B_C:   _rd_mask_aligned = 7'b1111100;
          VIP_AXI4_SIZE_2B_C:   _rd_mask_aligned = 7'b1111110;
          VIP_AXI4_SIZE_1B_C:   _rd_mask_aligned = 7'b1111111;
          default:              _rd_mask_aligned = 7'b1111111;
        endcase
      end else begin
        _rd_mask_aligned = 7'b1111111;
      end
    end

  property VIP_AXI4_ARADDR_WRAP_ALIGN_PR;
    arvalid && (arburst == VIP_AXI4_BURST_WRAP_C) && !($isunknown({arvalid, arburst, araddr}))
    |-> ((araddr[6 : 0] & _rd_mask_aligned) == araddr[6 : 0]);
  endproperty
  VIP_AXI4_ARADDR_WRAP_ALIGN_PR: assert property (VIP_AXI4_ARADDR_WRAP_ALIGN_PR) else
    $error("VIP_AXI4_ARADDR_WRAP_ALIGN_PR: For a wrapping burst, the start address must be aligned to the size of each transfer. Spec: section A3.4.1.");


  property VIP_AXI4_ARBURST_PR;
    arvalid && !($isunknown({arvalid, arburst}))
    |-> (arburst != 2'b11);
  endproperty
  VIP_AXI4_ARBURST_PR: assert property (VIP_AXI4_ARBURST_PR) else
    $error("VIP_AXI4_ARBURST_PR: When ARVALID is high, a value of 2'b11 on ARBURST is not permitted. Spec: table A3-3.");


  property VIP_AXI4_ARLEN_LOCK_PR;
    arvalid && (arlen > 8'b00001111) && !($isunknown({arvalid, arlen, arlock}))
    |-> (arlock != 1'b1);
  endproperty
  VIP_AXI4_ARLEN_LOCK_PR: assert property (VIP_AXI4_ARLEN_LOCK_PR) else
    $error("VIP_AXI4_ARLEN_LOCK_PR: Exclusive access transactions cannot have a length greater than 16 beats. Spec: section A7.2.4.");


  property VIP_AXI4_ARLEN_FIXED_PR;
    arvalid && (arlen > 8'b00001111) && !($isunknown({arvalid, arlen, arburst}))
    |-> (arburst != VIP_AXI4_BURST_FIXED_C);
  endproperty
  VIP_AXI4_ARLEN_FIXED_PR: assert property (VIP_AXI4_ARLEN_FIXED_PR) else
    $error("VIP_AXI4_ARLEN_FIXED_PR: Transactions of burst type FIXED cannot have a length greater than 16 beats. Spec: section A3.4.1.");


  property VIP_AXI4_ARLEN_WRAP_PR;
    arvalid && (arburst == VIP_AXI4_BURST_WRAP_C) && !($isunknown({arvalid, arburst, arlen}))
    |-> (arlen == 8'b00000001 ||
        arlen == 8'b00000011 ||
        arlen == 8'b00000111 ||
        arlen == 8'b00001111);
  endproperty
  VIP_AXI4_ARLEN_WRAP_PR: assert property (VIP_AXI4_ARLEN_WRAP_PR) else
    $error("VIP_AXI4_ARLEN_WRAP_PR: For a wrapping burst, the length of the burst must be 2, 4, 8 or 16 transfers. Spec: section A3.4.1.");


  logic [10 : 0] _arsize;
  always @(arsize) begin
    _arsize = (11'b000_0000_1000 << arsize); // 8 x arsize bytes
  end


  property VIP_AXI4_ARSIZE_PR;
    arvalid && !($isunknown({arvalid, arsize}))
    |-> (_arsize <= CFG_P.VIP_AXI4_DATA_WIDTH_P);
  endproperty
  VIP_AXI4_ARSIZE_PR: assert property (VIP_AXI4_ARSIZE_PR) else
    $error("VIP_AXI4_ARSIZE_PR: The size of any transfer must not exceed the data bus width of either agent in the transaction. Spec: section A3.4.1.");


  property VIP_AXI4_ARVALID_RESET_PR;
    !(rst_n) && !($isunknown(rst_n))
    ##1 rst_n
    |-> !arvalid;
  endproperty
  VIP_AXI4_ARVALID_RESET_PR: assert property (VIP_AXI4_ARVALID_RESET_PR) else
    $error("VIP_AXI4_ARVALID_RESET_PR: The earliest point after reset that a master is permitted to begin driving ARVALID, AWVALID, or WVALID HIGH is at a rising ACLK edge after ARESETn is HIGH. Spec: Figure A3-1.");

  // ---------------------------------------------------------------------------
  // Handshake Rules - Read Address Channel
  // ---------------------------------------------------------------------------

  property VIP_AXI4_ARADDR_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, araddr}))
    ##1 rst_n
    |-> $stable(araddr);
  endproperty
  VIP_AXI4_ARADDR_STABLE_PR: assert property (VIP_AXI4_ARADDR_STABLE_PR) else
    $error("VIP_AXI4_ARADDR_STABLE_PR: ARADDR must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARBURST_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid,arready,arburst}))
    ##1 rst_n
    |-> $stable(arburst);
  endproperty
  VIP_AXI4_ARBURST_STABLE_PR: assert property (VIP_AXI4_ARBURST_STABLE_PR) else
    $error("VIP_AXI4_ARBURST_STABLE_PR: ARBURST must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARID_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, arid}))
    ##1 rst_n
    |-> $stable(arid);
  endproperty
  axi4_arid_stable: assert property (VIP_AXI4_ARID_STABLE_PR) else
    $error("VIP_AXI4_ARID_STABLE_PR: ARID must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARLEN_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, arlen}))
    ##1 rst_n
    |-> $stable(arlen);
  endproperty
  VIP_AXI4_ARLEN_STABLE_PR: assert property (VIP_AXI4_ARLEN_STABLE_PR) else
    $error("AXI4_ARLEN_STABLE: ARLEN must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARLOCK_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, arlock}))
    ##1 rst_n
    |-> $stable(arlock);
  endproperty
  VIP_AXI4_ARLOCK_STABLE_PR: assert property (VIP_AXI4_ARLOCK_STABLE_PR) else
    $error("AXI4_ARLOCK_STABLE: ARLOCK must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARSIZE_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, arsize}))
    ##1 rst_n
    |-> $stable(arsize);
  endproperty
  VIP_AXI4_ARSIZE_STABLE_PR: assert property (VIP_AXI4_ARSIZE_STABLE_PR) else
    $error("VIP_AXI4_ARSIZE_STABLE_PR: ARSIZE must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARQOS_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready, arqos}))
    ##1 rst_n
    |-> $stable(arqos);
  endproperty
  VIP_AXI4_ARQOS_STABLE_PR: assert property (VIP_AXI4_ARQOS_STABLE_PR) else
    $error("VIP_AXI4_ARQOS_STABLE_PR: ARQOS must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARREGION_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid,arready,arregion}))
    ##1 rst_n
    |-> $stable(arregion);
  endproperty
  VIP_AXI4_ARREGION_STABLE_PR: assert property (VIP_AXI4_ARREGION_STABLE_PR) else
    $error("VIP_AXI4_ARREGION_STABLE_PR: ARREGION must remain stable when ARVALID is asserted and ARREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_ARVALID_STABLE_PR;
    arvalid && !arready && !($isunknown({arvalid, arready}))
    ##1 rst_n
    |-> arvalid;
  endproperty
  VIP_AXI4_ARVALID_STABLE_PR: assert property (VIP_AXI4_ARVALID_STABLE_PR) else
    $error("VIP_AXI4_ARVALID_STABLE_PR: Once ARVALID is asserted, it must remain asserted until ARREADY is high. Spec: section A3.2.1.");


  // ---------------------------------------------------------------------------
  // X-Propagation Rules - Read Address Channel
  // ---------------------------------------------------------------------------

  `ifdef VIP_AXI4_X_PROPAGATION
  `endif

  // ---------------------------------------------------------------------------
  // Functional Rules - Read Data Channel
  // ---------------------------------------------------------------------------



  // ---------------------------------------------------------------------------
  // Handshake Rules - Read Data Channel
  // ---------------------------------------------------------------------------

  // property VIP_AXI4_RDATA_STABLE;
  // endproperty


  property VIP_AXI4_RID_STABLE_PR;
    rvalid && !rready && !($isunknown({rvalid, rready, rid}))
    ##1 rst_n
    |-> $stable(rid);
  endproperty
  VIP_AXI4_RID_STABLE_PR: assert property (VIP_AXI4_RID_STABLE_PR) else
    $error("VIP_AXI4_RID_STABLE_PR: RID must remain stable when RVALID is asserted and RREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_RLAST_STABLE_PR;
    rvalid && !rready && !($isunknown({rvalid, rready, rlast}))
    ##1 rst_n
    |-> $stable(rlast);
  endproperty
  VIP_AXI4_RLAST_STABLE_PR: assert property (VIP_AXI4_RLAST_STABLE_PR) else
    $error("VIP_AXI4_RLAST_STABLE_PR: RLAST must remain stable when RVALID is asserted and RREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_RRESP_STABLE_PR;
    rvalid && !rready && !($isunknown({rvalid, rready, rresp}))
    ##1 rst_n
    |-> $stable(rresp);
  endproperty
  VIP_AXI4_RRESP_STABLE_PR: assert property (VIP_AXI4_RRESP_STABLE_PR) else
    $error("VIP_AXI4_RRESP_STABLE_PR: RRESP must remain stable when RVALID is asserted and RREADY low. Spec: section A3.2.1.");


  property VIP_AXI4_RVALID_STABLE_PR;
    rvalid && !rready && !($isunknown({rvalid, rready}))
    ##1 rst_n
    |-> rvalid;
  endproperty
  VIP_AXI4_RVALID_STABLE_PR: assert property (VIP_AXI4_RVALID_STABLE_PR) else
    $error("VIP_AXI4_RVALID_STABLE_PR: Once RVALID is asserted, it must remain asserted until RREADY is high. Spec: section A3.2.1.");


  // ---------------------------------------------------------------------------
  // X-Propagation Rules - Read Data Channel
  // ---------------------------------------------------------------------------

  `ifdef VIP_AXI4_X_PROPAGATION
  `endif

endmodule
