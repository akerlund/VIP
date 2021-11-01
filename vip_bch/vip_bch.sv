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

  protected vip_bch_coef_t _bch_cfg;
  protected int            _genpoly [];

  function new(string name = "vip_bch");
    super.new(name);
  endfunction

  function void init();
    `uvm_info(get_name(), "INIT", UVM_LOW)
  endfunction

endclass
