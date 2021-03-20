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

class vip_axi4s_item #(
  vip_axi4s_cfg_t CFG_P = '{default: '0}
  ) extends uvm_sequence_item;

  // ---------------------------------------------------------------------------
  // AXI4-S signals
  // ---------------------------------------------------------------------------

  rand logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] tdata [];
  rand logic [CFG_P.VIP_AXI4S_TSTRB_WIDTH_P-1 : 0] tstrb [];
       logic [CFG_P.VIP_AXI4S_TKEEP_WIDTH_P-1 : 0] tkeep [];
  rand logic   [CFG_P.VIP_AXI4S_TID_WIDTH_P-1 : 0] tid       = '0;
  rand logic [CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1 : 0] tdest     = '0;
       logic [CFG_P.VIP_AXI4S_TUSER_WIDTH_P-1 : 0] tuser [];
  rand int                                         burst_length;


  `uvm_object_param_utils_begin(vip_axi4s_item #(CFG_P))
    `uvm_field_int(tid,          UVM_DEFAULT)
    `uvm_field_int(tdest,        UVM_DEFAULT)
    `uvm_field_sarray_int(tdata, UVM_DEFAULT)
    `uvm_field_sarray_int(tstrb, UVM_DEFAULT)
    `uvm_field_sarray_int(tkeep, UVM_DEFAULT)
    `uvm_field_sarray_int(tuser, UVM_DEFAULT)
    `uvm_field_int(burst_length, UVM_DEFAULT)
  `uvm_object_utils_end

  vip_axi4s_item_config cfg;
  logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] custom_data [$];

  function new(string name = "vip_axi4s_item");
    super.new(name);
  endfunction

  function void print_config();
    `uvm_info(get_name(), {"VIP AXI4 item config:\n", cfg.sprint()}, UVM_LOW)
  endfunction

  function void set_config(vip_axi4s_item_config _icfg);
    cfg = _icfg;
  endfunction

  function void set_counter_start(logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] start);
    cfg.counter_start = start;
  endfunction

  function void set_custom_data(logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] data [$]);
    custom_data = data;
  endfunction



  constraint con_burst_length {
    burst_length >= cfg.min_burst_length;
    burst_length <= cfg.max_burst_length;
  }

  constraint con_array_sizes {
    tdata.size == burst_length;
    tstrb.size == burst_length;
  }

  constraint con_tdata_val {
    if (cfg.axi4s_tdata_type == VIP_AXI4S_TDATA_COUNTER_E) {
      foreach (tdata[i]) {
        tdata[i] == cfg.counter_start + i;
      }
    } else if (cfg.axi4s_tdata_type == VIP_AXI4S_TDATA_CUSTOM_E) {
      foreach (tdata[i]) {
        tdata[i] == custom_data[i];
      }
    }
  }

  constraint con_tstrb_val {
    if (cfg.axi4s_tstrb == VIP_AXI4S_TSTRB_ALL_E) {
      foreach (tstrb[i]) {
        tstrb[i] == {CFG_P.VIP_AXI4S_TSTRB_WIDTH_P{1'b1}};
      }
    } else {
      foreach (tstrb[i]) {
        tstrb[i] != 0;
      }
    }
  }

  constraint con_tid {
    tid >= cfg.min_tid;
    tid <= cfg.max_tid;
  }

  constraint con_tdest {
    tdest >= cfg.min_tdest;
    tdest <= cfg.max_tdest;
  }


endclass
