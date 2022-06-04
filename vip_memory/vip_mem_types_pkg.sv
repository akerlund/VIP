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

`ifndef VIP_MEM_TYPES_PKG
`define VIP_MEM_TYPES_PKG

package vip_mem_types_pkg;

  typedef struct packed {
    int ADDR_WIDTH_P;
    int DATA_BYTES_P;
  } vip_mem_cfg_t;

  typedef enum {
    VIP_MEM_X_IGNORE_E,
    VIP_MEM_X_WARNING_E,
    VIP_MEM_X_FATAL_E
  } vip_mem_x_severity_t;

endpackage

`endif
