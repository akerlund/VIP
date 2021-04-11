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

class vip_axi4s_item_config extends uvm_object;

  vip_axi4s_tdata_type_t axi4s_tdata_type = VIP_AXI4S_TDATA_COUNTER_E;
  vip_axi4s_tstrb_t      axi4s_tstrb      = VIP_AXI4S_TSTRB_ALL_E;
  longint                counter_start    = 0;

  int min_tid          = 0;
  int max_tid          = 0;
  int min_tdest        = 0;
  int max_tdest        = 0;
  int min_burst_length = 1;
  int max_burst_length = 1;

  `uvm_object_utils_begin(vip_axi4s_item_config);
    `uvm_field_enum(vip_axi4s_tdata_type_t, axi4s_tdata_type, UVM_ALL_ON)
    `uvm_field_enum(vip_axi4s_tstrb_t,      axi4s_tstrb,      UVM_ALL_ON)
    `uvm_field_int(counter_start,                             UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_tid,                                   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tid,                                   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_tdest,                                 UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tdest,                                 UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_burst_length,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_burst_length,                          UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end;

  function new(string name = "vip_axi4s_item_config");
    super.new(name);
  endfunction

endclass
