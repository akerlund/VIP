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

`ifndef VIP_AXI4S_TYPES_PKG
`define VIP_AXI4S_TYPES_PKG

package vip_axi4s_types_pkg;

  `ifndef BOOL_T
  `define BOOL_T
  typedef enum bit {
    FALSE,
    TRUE
  } bool_t;
  `endif

  typedef enum {
    VIP_AXI4S_MASTER_AGENT_E,
    VIP_AXI4S_SLAVE_AGENT_E
  } vip_axi4s_agent_type_t;

  typedef struct packed {
    int VIP_AXI4S_TDATA_WIDTH_P;
    int VIP_AXI4S_TSTRB_WIDTH_P;
    int VIP_AXI4S_TKEEP_WIDTH_P;
    int VIP_AXI4S_TID_WIDTH_P;
    int VIP_AXI4S_TDEST_WIDTH_P;
    int VIP_AXI4S_TUSER_WIDTH_P;
  } vip_axi4s_cfg_t;

  typedef enum {
    VIP_AXI4S_TDATA_COUNTER_E,
    VIP_AXI4S_TDATA_RANDOM_E,
    VIP_AXI4S_TDATA_CUSTOM_E
  } vip_axi4s_tdata_type_t;

  typedef enum {
    VIP_AXI4S_TSTRB_ALL_E,
    VIP_AXI4S_TSTRB_RANDOM_E
  } vip_axi4s_tstrb_t;

endpackage

`endif
