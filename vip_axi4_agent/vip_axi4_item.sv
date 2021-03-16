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

class vip_axi4_item #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_sequence_item;

  // ---------------------------------------------------------------------------
  // Write Address Channel
  // ---------------------------------------------------------------------------
  rand logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] awid    = '0;
  rand logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] awaddr  = '0;
  rand logic                             [7 : 0] awlen   = '0;
  rand logic                             [2 : 0] awsize  = VIP_AXI4_SIZE_16B_C;
  rand logic                             [1 : 0] awburst = VIP_AXI4_BURST_INCR_C;

       logic                                     awlock   = '0;
       logic                             [3 : 0] awcache  = '0;
       logic                             [2 : 0] awprot   = '0;
       logic                             [3 : 0] awqos    = '0;
       logic                             [3 : 0] awregion = '0;
       logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] awuser   = '0;

  // ---------------------------------------------------------------------------
  // Write Data Channel
  // ---------------------------------------------------------------------------
  rand logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] wdata [];
  rand logic [CFG_P.VIP_AXI4_STRB_WIDTH_P-1 : 0] wstrb [];
  rand logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] wuser [];

  // ---------------------------------------------------------------------------
  // Write Response Channel
  // ---------------------------------------------------------------------------
       logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] bid   = '0;
       logic                             [1 : 0] bresp = VIP_AXI4_RESP_OK_C;
       logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] buser = '0;

  // ---------------------------------------------------------------------------
  // Read Address Channel
  // ---------------------------------------------------------------------------
  rand logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] arid    = '0;
  rand logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] araddr  = '0;
  rand logic                             [7 : 0] arlen   = '0;
  rand logic                             [2 : 0] arsize  = VIP_AXI4_SIZE_16B_C;
  rand logic                             [1 : 0] arburst = VIP_AXI4_BURST_INCR_C;

       logic                                     arlock   = '0;
       logic                             [3 : 0] arcache  = '0;
       logic                             [2 : 0] arprot   = '0;
       logic                             [3 : 0] arqos    = '0;
       logic                             [3 : 0] arregion = '0;
       logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] aruser   = '0;

  // ---------------------------------------------------------------------------
  // Read Data Channel
  // ---------------------------------------------------------------------------
  rand logic   [CFG_P.VIP_AXI4_ID_WIDTH_P-1 : 0] rid   = '0;
       logic                             [1 : 0] rresp = VIP_AXI4_RESP_OK_C;
  rand logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] rdata [];
  rand logic [CFG_P.VIP_AXI4_USER_WIDTH_P-1 : 0] ruser [];

  `uvm_object_param_utils_begin(vip_axi4_item #(CFG_P))
    `uvm_field_int(awid,         UVM_DEFAULT)
    `uvm_field_int(awaddr,       UVM_DEFAULT)
    `uvm_field_int(awlen,        UVM_DEFAULT)
    `uvm_field_int(awsize,       UVM_DEFAULT)
    `uvm_field_int(awburst,      UVM_DEFAULT)
    `uvm_field_int(awlock,       UVM_DEFAULT)
    `uvm_field_int(awcache,      UVM_DEFAULT)
    `uvm_field_int(awprot,       UVM_DEFAULT)
    `uvm_field_int(awqos,        UVM_DEFAULT)
    `uvm_field_int(awregion,     UVM_DEFAULT)
    `uvm_field_int(awuser,       UVM_DEFAULT)
    `uvm_field_sarray_int(wdata, UVM_DEFAULT)
    `uvm_field_sarray_int(wstrb, UVM_DEFAULT)
    `uvm_field_sarray_int(wuser, UVM_DEFAULT)
    `uvm_field_int(bid,          UVM_DEFAULT)
    `uvm_field_int(bresp,        UVM_DEFAULT)
    `uvm_field_int(buser,        UVM_DEFAULT)
    `uvm_field_int(arid,         UVM_DEFAULT)
    `uvm_field_int(araddr,       UVM_DEFAULT)
    `uvm_field_int(arlen,        UVM_DEFAULT)
    `uvm_field_int(arsize,       UVM_DEFAULT)
    `uvm_field_int(arburst,      UVM_DEFAULT)
    `uvm_field_int(arlock,       UVM_DEFAULT)
    `uvm_field_int(arcache,      UVM_DEFAULT)
    `uvm_field_int(arprot,       UVM_DEFAULT)
    `uvm_field_int(arqos,        UVM_DEFAULT)
    `uvm_field_int(arregion,     UVM_DEFAULT)
    `uvm_field_int(aruser,       UVM_DEFAULT)
    `uvm_field_int(rid,          UVM_DEFAULT)
    `uvm_field_sarray_int(rresp, UVM_DEFAULT)
    `uvm_field_sarray_int(rdata, UVM_DEFAULT)
    `uvm_field_sarray_int(ruser, UVM_DEFAULT)
  `uvm_object_utils_end

  vip_axi4_item_config                      cfg;
  vip_axi4_item                    #(CFG_P) req_queue [$];
  logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] custom_data [$];

  function new(string name = "vip_axi4_item");
    super.new(name);
  endfunction

  function void print_config();
    `uvm_info(get_name(), {"VIP AXI4 item config:\n", cfg.sprint()}, UVM_LOW)
  endfunction

  function void set_config(vip_axi4_item_config _icfg);
    cfg = _icfg;
  endfunction

  function void set_counter_start(logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] start);
    cfg.counter_start = start;
  endfunction

  function void set_custom_data(logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] data [$]);
    custom_data = data;
  endfunction

  // ---------------------------------------------------------------------------
  // Constraints
  // ---------------------------------------------------------------------------

  function void pre_randomize();

    if (cfg == null && (!uvm_config_db #(vip_axi4_item_config)::get(null, "*", "default_axi4_item_config", cfg))) begin
      `uvm_fatal("NOCFG", "AXI4 Item has no config")
    end

    if (cfg.axi4_data_type   == VIP_AXI4_DATA_CUSTOM_E &&
        custom_data.size()-1 != cfg.min_len            &&
        cfg.min_len          != cfg.max_len) begin
          `uvm_fatal(get_name(), "Data size and len are mismatching")
    end

  endfunction

  constraint con_awid {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      awid >= cfg.min_id;
      awid <= cfg.max_id;
    } else {
      awid == 0;
    }
  }

  constraint con_awaddr_4k_boundary {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      awaddr         >= cfg.min_addr;
      awaddr         <= cfg.max_addr;
      // For example with (awlen = 0) and (strb=16):
      //   araddr < 4096 -  1 * 16 = 4080
      //   araddr < 4096 - 16 * 16 = 3840
      awaddr[11 : 0] <= VIP_AXI4_4K_ADDRESS_BOUNDARY_C - ((unsigned'(awlen) + 1) * CFG_P.VIP_AXI4_STRB_WIDTH_P);
    } else {
      awaddr == 0;
    }
  }

  constraint con_awburst {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      awburst >= cfg.min_burst;
      awburst <= cfg.max_burst;
    } else {
      awburst == 0;
    }
  }

  constraint con_awlen {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      if (awburst == VIP_AXI4_BURST_WRAP_C) {
        awlen inside {1, 3, 7, 15};
      } else {
        awlen >= cfg.min_len;
        awlen <= cfg.max_len;
      }
    } else {
      awlen == 0;
    }
  }

  constraint con_awsize {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      awsize >= cfg.min_size;
      awsize <= cfg.max_size;
    } else {
      awsize == 0;
    }
  }

  constraint con_wdata_size {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      wdata.size == awlen + 1;
    } else {
      wdata.size == 0;
    }
  }

  constraint con_wdata_val {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      if (cfg.axi4_data_type == VIP_AXI4_DATA_COUNTER_E) {
        foreach (wdata[i]) {
          wdata[i] == cfg.counter_start + i;
        }
      } else if (cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) {
        foreach (wdata[i]) {
          wdata[i] == custom_data[i];
        }
      }
    }
  }

  constraint con_wstrb_size {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      wstrb.size == awlen + 1;
    } else {
      wstrb.size == 0;
    }
  }

  constraint con_wstrb_val {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      if (cfg.axi4_strb == VIP_AXI4_STRB_ALL_E) {
        foreach (wstrb[i]) {
          if (i == 0) {
            wstrb[i] == 2**16 - 2**awaddr[3 : 0];
          } else if (i == awlen && awaddr[3 : 0] != 0) {
            wstrb[i] == 2**awaddr[3 : 0] - 1;
          } else {
            wstrb[i] == {CFG_P.VIP_AXI4_STRB_WIDTH_P{1'b1}};
          }
        }
      } else {
        foreach (wstrb[i]) {
          wstrb[i] != 0;
        }
      }
    }
  }

  constraint con_wuser_size {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      wuser.size == awlen + 1;
    } else {
      wuser.size == 0;
    }
  }

  constraint con_wuser_val {
    if (cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) {
      foreach (wuser[i]) {
        wuser[i] == 0;
      }
    }
  }

  constraint con_arid {
    if (cfg.axi4_access == VIP_AXI4_RD_REQUEST_E ||
        cfg.axi4_access == VIP_AXI4_RD_RESPONSE_E) {
      arid <= cfg.max_id;
      arid >= cfg.min_id;
    }
  }

  constraint con_araddr_4k_boundary {
    if (cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) {
      araddr >= cfg.min_addr;
      araddr <= cfg.max_addr;
      araddr[11 : 0] <= VIP_AXI4_4K_ADDRESS_BOUNDARY_C - ((unsigned'(arlen) + 1) * CFG_P.VIP_AXI4_STRB_WIDTH_P);
    } else {
      araddr == 0;
    }
  }

  constraint con_arburst {
    if (cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) {
      arburst >= cfg.min_burst;
      arburst <= cfg.max_burst;
    } else {
      arburst == 0;
    }
  }

  constraint con_arlen {
    if (cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) {
      if (arburst == VIP_AXI4_BURST_WRAP_C) {
        arlen inside {1, 3, 7, 15};
      } else {
        arlen >= cfg.min_len;
        arlen <= cfg.max_len;
      }
    } else {
      arlen == 0;
    }
  }

  constraint con_arsize {
    if (cfg.axi4_access == VIP_AXI4_RD_REQUEST_E) {
      arsize >= cfg.min_size;
      arsize <= cfg.max_size;
    } else {
      arsize == 0;
    }
  }

  constraint con_rdata_size {
    if (cfg.axi4_access == VIP_AXI4_RD_RESPONSE_E) {
      rdata.size == arlen + 1;
    } else {
      rdata.size == 0;
    }
  }

  constraint con_rdata_val {
    if (cfg.axi4_access == VIP_AXI4_RD_RESPONSE_E) {
      if (cfg.axi4_data_type == VIP_AXI4_DATA_COUNTER_E) {
        foreach (rdata[i]) {
          rdata[i] == cfg.counter_start + i;
        }
      } else if (cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) {
        foreach (rdata[i]) {
          rdata[i] == custom_data[i];
        }
      }
    }
  }

  constraint con_ruser_size {
    if (cfg.axi4_access == VIP_AXI4_RD_RESPONSE_E) {
      ruser.size == arlen + 1;
    } else {
      ruser.size == 0;
    }
  }

  constraint con_ruser_val {
    if (cfg.axi4_access == VIP_AXI4_RD_RESPONSE_E) {
      foreach (ruser[i]) {
        ruser[i] == 0;
      }
    }
  }

endclass
