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
// Description: The VIP's top package
//
////////////////////////////////////////////////////////////////////////////////

`ifndef VIP_BCH_PKG
`define VIP_BCH_PKG

package vip_bch_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import vip_bch_constants_pkg::*;
  import vip_bch_types_pkg::*;

  `include "vip_bch_config.sv"
  `include "vip_bch.sv"

endpackage

`endif
