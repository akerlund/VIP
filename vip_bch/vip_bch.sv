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
// Description: This file contains the top VIP object
//
////////////////////////////////////////////////////////////////////////////////

class vip_bch extends uvm_object;

  `uvm_object_utils(vip_bch);

  extern function void py_config(
    int unsigned m,
    int unsigned t,
    int unsigned polynomial = 0
  );
  extern function int py_build_gf_tables(
    ref vip_bch_coef_t bch_coef,
    int unsigned       prim_poly
  );
  extern function int py_get_poly_degree(
    int unsigned poly
  );

  protected vip_bch_coef_t          _bch_coef;
  protected logic unsigned [15 : 0] _a_pow_tab [];
  protected logic unsigned [15 : 0] _a_log_tab [];
  protected int                     _genpoly   [];

  function new(string name = "vip_bch");
    super.new(name);
  endfunction

  function void init();
    `uvm_info(get_name(), "INIT", UVM_LOW)
    py_config(5, 1);
  endfunction

endclass

// ---------------------------------------------------------------------------
//
// ---------------------------------------------------------------------------
function void vip_bch::py_config(
    int unsigned m,
    int unsigned t,
    int unsigned polynomial = 0
  );

  int unsigned primitive_polynomial;

  if (m < MIN_M_C) begin
    `uvm_fatal(get_name(), $sformatf("FATAL [config] m < MIN_M_C: %0d > %0d", m, MAX_M_C))
  end

  if (m > MAX_M_C) begin
    `uvm_fatal(get_name(), $sformatf("FATAL [config] m > MAX_M_C: %0d > %0d", m, MAX_M_C))
  end

  if (t < 1) begin
    `uvm_fatal(get_name(), $sformatf("FATAL [config] t < 1"))
  end

  if (m*t >= ((1 << m)-1)) begin
    `uvm_fatal(get_name(), $sformatf("FATAL [config] m*t >= ((1 << m)-1), m = %0d, t = %0d", m , t))
  end

  // Select a primitive polynomial for generating GF(2^m)
  if (polynomial == 0) begin
    primitive_polynomial = PRIMITIVE_POLYNOMIALS_C[MIN_M_C-m];
  end

  _bch_coef.m = m;
  _bch_coef.n = 2**m - 1;
  _bch_coef.t = t;

  // Generate Galois field lookup tables
  if (!vip_bch::py_build_gf_tables(_bch_coef, primitive_polynomial)) begin
    `uvm_fatal(get_name(), $sformatf("FATAL [config] Call to py_build_gf_tables failed"))
  end
/*
  _genpoly = py_compute_generator_polynomial(_bch_coef);
  build_mod8_tables(_bch_coef, _genpoly);
  _genpoly.delete();
*/
  //build_deg2_base(_bch);

endfunction

// ---------------------------------------------------------------------------
// Generate Galois field lookup tables
// ---------------------------------------------------------------------------
function int vip_bch::py_build_gf_tables(
    ref vip_bch_coef_t bch_coef,
    int unsigned       prim_poly
  );

  int unsigned x;
  int unsigned poly_degree;

  _a_pow_tab.delete();
  _a_log_tab.delete();
  _a_pow_tab = new[_bch_coef.n+1];
  _a_log_tab = new[_bch_coef.n+1];

  // Primitive polynomial must be of degree m
  poly_degree = 1 << vip_bch::py_get_poly_degree(prim_poly);
  if (poly_degree != (1 << bch_coef.m)) begin
    return -1;
  end

  x = 1;
  for (int i = 0; i < bch_coef.n; i++) begin
    _a_pow_tab[i] = x;
    _a_log_tab[x] = i;
    if (i && (x == 1)) begin
      `uvm_fatal(get_name(), $sformatf({"ERROR [build_gf_tables]",
      " The polynomial is not primitive (a^i = 1 with 0 < i < 2^m-1)"}))
      return -1;
    end
    x <<= 1;
    if (x & poly_degree) begin
      x ^= prim_poly;
    end
  end

  _a_pow_tab[bch_coef.n] = 1;
  _a_log_tab[0]          = 0;

  return 0;
endfunction

// ---------------------------------------------------------------------------
// Get degree of polynomial
// ---------------------------------------------------------------------------
function int vip_bch::py_get_poly_degree(
    int unsigned poly
  );

  int degree  = 0;
  int poly_r0 = poly;
  while (poly_r0) begin
    degree++;
    poly_r0 = poly_r0 >> 1;
  end
  py_get_poly_degree = degree + 1;
endfunction
