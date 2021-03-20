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

`ifndef VIP_AXI4S_AGENT_PKG
`define VIP_AXI4S_AGENT_PKG

package vip_axi4s_agent_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import bool_pkg::*;
  import vip_axi4s_types_pkg::*;

  `include "vip_axi4s_item_config.sv"
  `include "vip_axi4s_item.sv"
  `include "vip_axi4s_config.sv"
  `include "vip_axi4s_monitor.sv"
  `include "vip_axi4s_sequencer.sv"
  `include "vip_axi4s_driver.sv"
  `include "vip_axi4s_agent.sv"

endpackage

`endif
