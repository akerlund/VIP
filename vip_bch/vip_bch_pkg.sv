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

  import vip_bch_types_pkg::*;
  //import vip_bch_types_pkg::*;

  localparam int unsigned MIN_M_C = 5;
  localparam int unsigned MAX_M_C = 15;
  localparam int unsigned PRIMITIVE_POLYNOMIALS_C [] = {
    'h0025, // m = 5
    'h0043, // m = 6
    'h0083, // m = 7
    'h011d, // m = 8
    'h0211, // m = 9
    'h0409, // m = 10
    'h0805, // m = 11
    'h1053, // m = 12
    'h201b, // m = 13
    'h402b, // m = 14
    'h8003  // m = 15
  };

  `include "vip_bch_config.sv"

endpackage

import vip_bch_pkg::*;

`endif
