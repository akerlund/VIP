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

`ifndef VIP_BCH_FUNCTIONS_PKG
`define VIP_BCH_FUNCTIONS_PKG

`include "vip_bch_types_pkg.sv"

package vip_bch_functions_pkg;

  import vip_bch_types_pkg::*;
  import vip_bch_constants_pkg::*;

  // ---------------------------------------------------------------------------
  // Initial test function
  // ---------------------------------------------------------------------------
  function vip_bch_coef_t get_bch_coefficients(int m, int t);

    vip_bch_coef_t bch_coef;

    if ((m < MIN_M_C) || (m > MAX_M_C)) begin
      $fatal("FATAL [get_bch_cfg] Bad m value");
    end

    if ((t < 1) || (m*t >= ((1 << m)-1))) begin
      $fatal("FATAL [get_bch_cfg] Bad t value");
    end

    bch_coef.m = m;
    bch_coef.n = 1;
    bch_coef.t = t;
    bch_coef.k = 1;
    bch_coef.d = 1;
    bch_coef.e = 1;
    bch_coef.s = 1;

    get_bch_coefficients = bch_coef;

  endfunction

endpackage

`endif
