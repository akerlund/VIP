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

`ifndef VIP_AXI4_AGENT_PKG
`define VIP_AXI4_AGENT_PKG

package vip_axi4_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import bool_pkg::*;
  import vip_mem_types_pkg::*;
  import vip_memory_pkg::*;
  import vip_axi4_types_pkg::*;

  `include "vip_axi4_item_config.sv"
  `include "vip_axi4_item.sv"
  `include "vip_axi4_config.sv"
  `include "vip_axi4_monitor_callback.sv"
  `include "vip_axi4_monitor.sv"
  `include "vip_axi4_driver_callback.sv"
  `include "vip_axi4_driver.sv"
  `include "vip_axi4_sequencer.sv"
  `include "vip_axi4_agent.sv"

endpackage

`endif

