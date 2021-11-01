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

`ifndef VIP_BCH_TYPES_PKG
`define VIP_BCH_TYPES_PKG

package vip_bch_types_pkg;

  typedef struct packed {
    int unsigned m; // The Galois field order
    int unsigned n; // The maximum codeword size in bits
    int unsigned t; // The number bit errors that can be corrected
    int unsigned k; // Number of ECC bits (TODO: codeword length)
    int unsigned d; // Number of data bits
    int unsigned e; // Number of ECC bits
    int unsigned s; // Number of syndromes
  } vip_bch_coef_t;

  /*
  typedef packed struct {
    unsigned int deg; // Polynomial degree
    unsigned int c[]; // Polynomial terms
  } vip_gf_poly_t;
  */

endpackage

`endif
