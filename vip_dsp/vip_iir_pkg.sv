////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
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


`ifndef VIP_IIR_PKG
`define VIP_IIR_PKG

package vip_iir_pkg;

  import vip_math_pkg::*;
  import iir_biquad_types_pkg::*;

  typedef struct {
    real w0;
    real alfa;
    real b0;
    real b1;
    real b2;
    real a0;
    real a1;
    real a2;
  } biquad_coefficients_t;


  function biquad_coefficients_t biquad_coefficients(real f0, real fs, real q, iir_biquad_types_pkg::iir_biquad_type_t bq_type);

    biquad_coefficients_t coef;

    coef.w0   = 2 * PI_C * f0 / fs;
    coef.alfa = $sin(coef.w0) / (2 * q);

    case (bq_type)

      iir_biquad_types_pkg::IIR_LOW_PASS_E: begin
        coef.b0 =  (1 - $cos(coef.w0)) / 2;
        coef.b1 =   1 - $cos(coef.w0);
        coef.b2 =  (1 - $cos(coef.w0)) / 2;
        coef.a0 =   1 + coef.alfa;
        coef.a1 = -(2 * $cos(coef.w0));
        coef.a2 =   1 - coef.alfa;
      end

      iir_biquad_types_pkg::IIR_HIGH_PASS_E: begin
        coef.b0 =  (1 + $cos(coef.w0)) / 2;
        coef.b1 = -(1 + $cos(coef.w0));
        coef.b2 =  (1 + $cos(coef.w0)) / 2;
        coef.a0 =   1 + coef.alfa;
        coef.a1 = -(2 * $cos(coef.w0));
        coef.a2 =   1 - coef.alfa;
      end

      iir_biquad_types_pkg::IIR_BAND_PASS_E: begin
        coef.b0 =   $sin(coef.w0) / 2;
        coef.b1 =   0;
        coef.b2 = -($sin(coef.w0) / 2);
        coef.a0 =   1 + coef.alfa;
        coef.a1 = -(2 * $cos(coef.w0));
        coef.a2 =   1 - coef.alfa;
      end
    endcase

    biquad_coefficients = coef;

  endfunction

endpackage

`endif
