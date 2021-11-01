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
// Description: An object for printing out calculated parameters (configuration)
//
////////////////////////////////////////////////////////////////////////////////

class vip_bch_config extends uvm_object;

  int unsigned m;
  int unsigned n;
  int unsigned t;
  int unsigned k;
  int unsigned data_width;
  int unsigned ecc_bits;
  int unsigned syndromes;

  `uvm_object_utils_begin(vip_bch_config);
    `uvm_field_int(m,          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(n,          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(t,          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(k,          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(data_width, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(ecc_bits,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(syndromes,  UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end;


  function void set_bch_coefficients(vip_bch_coef_t bch_cfg);
    m          = bch_cfg.m;
    n          = bch_cfg.n;
    t          = bch_cfg.t;
    k          = bch_cfg.k;
    data_width = bch_cfg.d;
    ecc_bits   = bch_cfg.e;
    syndromes  = bch_cfg.s;
  endfunction

  function new(string name = "vip_bch_config");
    super.new(name);
  endfunction

endclass
