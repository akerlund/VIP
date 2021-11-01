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

package bch_tc_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import bool_pkg::*;
  import report_server_pkg::*;
  import vip_bch_types_pkg::*;
  import vip_bch_functions_pkg::*;
  import vip_bch_pkg::*;

  `include "bch_base_test.sv"
  `include "tc_bch.sv"

endpackage
