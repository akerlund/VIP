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

class tc_bch extends uvm_test;

  `uvm_component_utils(tc_bch)

  protected vip_bch_config _bch_config;
  protected vip_bch_coef_t _bch_coef;

  function new(string name = "tc_bch", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    _bch_config = vip_bch_config::type_id::create("_bch_config", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);

    _bch_coef.m = 1;
    _bch_coef.n = 1;
    _bch_coef.t = 1;
    _bch_coef.k = 1;
    _bch_coef.d = 1;
    _bch_coef.e = 1;
    _bch_coef.s = 1;
    _bch_config = new();
    _bch_config.set_bch_coefficients(_bch_coef);

    $display("--------------------------------------------------------------------------------");
    $display("BCH TEST");
    $display("--------------------------------------------------------------------------------");

    `uvm_info(get_name(), {"BCH coefficients:\n", _bch_config.sprint()}, UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass
