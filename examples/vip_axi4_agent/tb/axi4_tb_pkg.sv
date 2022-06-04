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

package axi4_tb_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import bool_pkg::*;
  import clk_rst_types_pkg::*;
  import clk_rst_pkg::*;
  import vip_axi4_types_pkg::*;
  import vip_axi4_agent_pkg::*;

  localparam int AXI4_ID_WIDTH_C   = 11;
  localparam int AXI4_ADDR_WIDTH_C = 16;
  localparam int AXI4_DATA_WIDTH_C = 64;
  localparam int AXI4_STRB_WIDTH_C = AXI4_DATA_WIDTH_C/8;

  // Configuration of the VIP (Data)
  localparam vip_axi4_cfg_t VIP_AXI4_CFG_C = '{
    VIP_AXI4_ID_WIDTH_P   : AXI4_ID_WIDTH_C,
    VIP_AXI4_ADDR_WIDTH_P : AXI4_ADDR_WIDTH_C,
    VIP_AXI4_DATA_WIDTH_P : AXI4_DATA_WIDTH_C,
    VIP_AXI4_STRB_WIDTH_P : AXI4_STRB_WIDTH_C,
    VIP_AXI4_USER_WIDTH_P : 0
  };

  // Configuration of the VIP (Registers)
  localparam vip_axi4_cfg_t VIP_REG_CFG_C = '{
    VIP_AXI4_ID_WIDTH_P   : 2,
    VIP_AXI4_ADDR_WIDTH_P : 16,
    VIP_AXI4_DATA_WIDTH_P : 64,
    VIP_AXI4_STRB_WIDTH_P : 8,
    VIP_AXI4_USER_WIDTH_P : 0
  };

  // Register model
  `include "axi4_reg.sv"
  `include "axi4_block.sv"
  `include "register_model.sv"
  `include "vip_axi4_adapter.sv"

  // Testbench
  `include "axi4_scoreboard.sv"
  `include "axi4_virtual_sequencer.sv"
  `include "axi4_env.sv"

  `include "vip_axi4_seq_lib.sv"

endpackage
