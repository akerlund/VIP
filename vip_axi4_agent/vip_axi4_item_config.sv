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

class vip_axi4_item_config extends uvm_object;

  vip_axi4_access_t      axi4_access     = VIP_AXI4_WR_REQUEST_E;
  vip_axi4_id_type_t     axi4_id_type    = VIP_AXI4_ID_COUNTER_E;
  vip_axi4_data_type_t   axi4_data_type  = VIP_AXI4_DATA_COUNTER_E;
  vip_axi4_strb_t        axi4_strb       = VIP_AXI4_STRB_ALL_E;
  bool_t                 get_wr_response = FALSE;
  bool_t                 get_rd_response = FALSE;
  bool_t                 enable_boundary = FALSE;
  longint                counter_data    = 0;
  longint                counter_id      = 0;

  int                    min_id          = 0;
  int                    max_id          = 0;
  longint                min_addr        = 0;
  longint                max_addr        = VIP_AXI4_4K_ADDRESS_BOUNDARY_C-1;
  longint                addr_boundary   = VIP_AXI4_4K_ADDRESS_BOUNDARY_C;
  logic unsigned [7 : 0] min_len         = 0;
  logic unsigned [7 : 0] max_len         = 255;
  logic unsigned [2 : 0] min_size        = VIP_AXI4_SIZE_16B_C;
  logic unsigned [2 : 0] max_size        = VIP_AXI4_SIZE_16B_C;
  logic unsigned [1 : 0] max_burst       = VIP_AXI4_BURST_INCR_C;
  logic unsigned [1 : 0] min_burst       = VIP_AXI4_BURST_INCR_C;

  `uvm_object_utils_begin(vip_axi4_item_config);
  `uvm_field_enum(vip_axi4_access_t,    axi4_access,     UVM_ALL_ON)
  `uvm_field_enum(vip_axi4_id_type_t,   axi4_id_type,    UVM_ALL_ON)
  `uvm_field_enum(vip_axi4_data_type_t, axi4_data_type,  UVM_ALL_ON)
  `uvm_field_enum(vip_axi4_strb_t,      axi4_strb,       UVM_ALL_ON)
  `uvm_field_enum(bool_t,               get_wr_response, UVM_ALL_ON)
  `uvm_field_enum(bool_t,               get_rd_response, UVM_ALL_ON)
  `uvm_field_enum(bool_t,               enable_boundary, UVM_ALL_ON)
  `uvm_field_int(counter_data,                           UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(counter_id,                             UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(min_id,                                 UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(max_id,                                 UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(min_addr,                               UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(max_addr,                               UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(addr_boundary,                          UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(min_len,                                UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(max_len,                                UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(min_size,                               UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(max_size,                               UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(max_burst,                              UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(min_burst,                              UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end;

  function new(string name = "vip_axi4_item_config");
    super.new(name);
  endfunction

  function void reset();
    axi4_access     = VIP_AXI4_WR_REQUEST_E;
    axi4_id_type    = VIP_AXI4_ID_COUNTER_E;
    axi4_data_type  = VIP_AXI4_DATA_COUNTER_E;
    axi4_strb       = VIP_AXI4_STRB_ALL_E;
    get_rd_response = FALSE;
    enable_boundary = FALSE;
    counter_data    = 0;
    counter_id      = 0;
    min_id          = 0;
    max_id          = 0;
    min_addr        = 0;
    max_addr        = VIP_AXI4_4K_ADDRESS_BOUNDARY_C-1;
    addr_boundary   = 0;
    min_len         = 0;
    max_len         = 255;
    min_size        = VIP_AXI4_SIZE_16B_C;
    max_size        = VIP_AXI4_SIZE_16B_C;
    max_burst       = VIP_AXI4_BURST_INCR_C;
    min_burst       = VIP_AXI4_BURST_INCR_C;
  endfunction

endclass
