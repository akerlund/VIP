////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
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

`ifndef VIP_MATH_PKG
`define VIP_MATH_PKG

package vip_math_pkg;

  localparam real PI_C = 3.141592653589793;


  function int abs_int(int _int);
    if (_int < 0) begin
      abs_int = -_int;
    end else begin
      abs_int = _int;
    end
  endfunction


  function real abs_real(real _real);
    if (_real < 0) begin
      abs_real = -_real;
    end else begin
      abs_real = _real;
    end
  endfunction

endpackage

`endif
