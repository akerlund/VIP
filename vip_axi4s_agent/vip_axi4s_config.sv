////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
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

class vip_axi4s_config extends uvm_object;

  uvm_active_passive_enum is_active            = UVM_ACTIVE;
  vip_axi4s_agent_type_t  vip_axi4s_agent_type = VIP_AXI4S_MASTER_AGENT_E;

  bool_t tvalid_delay_enabled    = TRUE;
  int    min_tvalid_delay_time   = 1;
  int    max_tvalid_delay_time   = 10;
  int    min_tvalid_delay_period = 10;
  int    max_tvalid_delay_period = 256;
  bool_t tready_delay_enabled    = TRUE;
  int    min_tready_delay_time   = 1;
  int    max_tready_delay_time   = 10;
  int    min_tready_delay_period = 10;
  int    max_tready_delay_period = 256;

  `uvm_object_utils_begin(vip_axi4s_config);
    `uvm_field_enum(uvm_active_passive_enum, is_active,            UVM_ALL_ON)
    `uvm_field_enum(vip_axi4s_agent_type_t,  vip_axi4s_agent_type, UVM_ALL_ON)
    `uvm_field_enum(bool_t,                  tvalid_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_tvalid_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tvalid_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_tvalid_delay_period,                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tvalid_delay_period,                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum(bool_t,                  tready_delay_enabled, UVM_ALL_ON)
    `uvm_field_int(min_tready_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tready_delay_time,                          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(min_tready_delay_period,                        UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(max_tready_delay_period,                        UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end;

  function new(string name = "vip_axi4s_config");
    super.new(name);
  endfunction

endclass
