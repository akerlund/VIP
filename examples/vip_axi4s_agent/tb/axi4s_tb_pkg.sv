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

package axi4s_tb_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import clk_rst_types_pkg::*;
  import clk_rst_pkg::*;
  import vip_axi4s_types_pkg::*;
  import vip_axi4s_agent_pkg::*;

  localparam int VIP_AXI4S_TDATA_WIDTH_C = 128;
  localparam int VIP_AXI4S_TSTRB_WIDTH_C = VIP_AXI4S_TDATA_WIDTH_C/8;
  localparam int VIP_AXI4S_TKEEP_WIDTH_C = 0;
  localparam int VIP_AXI4S_TID_WIDTH_C   = 11;
  localparam int VIP_AXI4S_TDEST_WIDTH_C = 0;
  localparam int VIP_AXI4S_TUSER_WIDTH_C = 0;

  // Configuration of the VIP (Data)
  localparam vip_axi4s_cfg_t VIP_AXI4S_CFG_C = '{
    VIP_AXI4S_TDATA_WIDTH_P : VIP_AXI4S_TDATA_WIDTH_C,
    VIP_AXI4S_TSTRB_WIDTH_P : VIP_AXI4S_TSTRB_WIDTH_C,
    VIP_AXI4S_TKEEP_WIDTH_P : VIP_AXI4S_TKEEP_WIDTH_C,
    VIP_AXI4S_TID_WIDTH_P   : VIP_AXI4S_TID_WIDTH_C,
    VIP_AXI4S_TDEST_WIDTH_P : VIP_AXI4S_TDEST_WIDTH_C,
    VIP_AXI4S_TUSER_WIDTH_P : VIP_AXI4S_TUSER_WIDTH_C
  };

  // Testbench
  `include "axi4s_scoreboard.sv"
  `include "axi4s_virtual_sequencer.sv"
  `include "axi4s_env.sv"
  `include "vip_axi4s_seq_lib.sv"

endpackage
