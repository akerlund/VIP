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

`ifndef VIP_AXI4S_IF
`define VIP_AXI4S_IF

interface vip_axi4s_if #(
  parameter vip_axi4s_CFG_P_t CFG_P = '{default: '0}
  )(
    input clk,
    input rst_n
  );

  logic                                tvalid;
  logic                                tready;
  logic [CFG_P.AXI_DATA_WIDTH_P-1 : 0] tdata;
  logic [CFG_P.AXI_STRB_WIDTH_P-1 : 0] tstrb;
  logic [CFG_P.AXI_KEEP_WIDTH_P-1 : 0] tkeep;
  logic                                tlast;
  logic   [CFG_P.AXI_ID_WIDTH_P-1 : 0] tid;
  logic [CFG_P.AXI_DEST_WIDTH_P-1 : 0] tdest;
  logic [CFG_P.AXI_USER_WIDTH_P-1 : 0] tuser;

endinterface

`endif
