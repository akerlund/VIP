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

// -----------------------------------------------------------------------------
// Base Sequence
// -----------------------------------------------------------------------------
class vip_axi4s_base_seq extends uvm_sequence #(vip_axi4s_item #(VIP_AXI4S_CFG_C));

  `uvm_object_utils(vip_axi4s_base_seq)

  `ifndef VIP_AXI4S_BASE_SEQ_MACRO
  `define VIP_AXI4S_BASE_SEQ_MACRO
  `define __DATA_RANGE VIP_AXI4S_CFG_C.VIP_AXI4S_TDATA_WIDTH_P-1 : 0
  `define __STRB_RANGE VIP_AXI4S_CFG_C.VIP_AXI4S_TSTRB_WIDTH_P-1 : 0
  `define __DEST_RANGE VIP_AXI4S_CFG_C.VIP_AXI4S_TDEST_WIDTH_P-1 : 0
  `define __ITEM       vip_axi4s_item #(VIP_AXI4S_CFG_C)
  `define __CFG        vip_axi4s_item_config
  `endif

  typedef logic [`__DATA_RANGE] custom_data_t [$];

  protected bool_t                  _verbose            = TRUE;
  protected `__CFG                  _cfg;
  protected logic   [`__DEST_RANGE] _dest               = '0;
  protected logic   [`__DEST_RANGE] _dest_increment     = '0;
  protected logic   [`__DATA_RANGE] _counter            = '0;
  protected logic   [`__DATA_RANGE] _custom_data  [$];

  function new(string name = "vip_axi4s_base_seq");
    super.new(name);
    _cfg = new();
    _cfg.max_tid = 2**VIP_AXI4S_CFG_C.VIP_AXI4S_TID_WIDTH_P-1;
  endfunction


  function void set_verbose(bool_t verbose);
    _verbose = verbose;
  endfunction


  function void set_data_type(vip_axi4s_tdata_type_t axi4s_tdata_type);
    _cfg.axi4s_tdata_type = axi4s_tdata_type;
  endfunction


  function void set_custom_data(custom_data_t custom_data);
    _custom_data = custom_data;
  endfunction


  function void set_counter(int counter);
    _counter = counter;
  endfunction


  function int get_counter();
    get_counter = _counter;
  endfunction


  function void set_dest_increment(int dest_increment);
    _dest_increment = dest_increment;
  endfunction


  function void set_dest(logic [`__DEST_RANGE] dest);
    _dest         = dest;
    _cfg.min_tdest = dest;
    _cfg.max_tdest = dest;
  endfunction


  function void set_burst_length(int burst_length);
    _cfg.min_burst_length = burst_length;
    _cfg.max_burst_length = burst_length;
  endfunction


  function void set_tstrb(vip_axi4s_tstrb_t axi4s_tstrb);
    _cfg.axi4s_tstrb = axi4s_tstrb;
  endfunction


  function void set_cfg_tid(int max_tid, int min_tid);
    _cfg.max_tid = max_tid;
    _cfg.min_tid = min_tid;
  endfunction


  function void set_cfg_tdest(int max_tdest, int min_tdest);
    _cfg.max_tdest = max_tdest;
    _cfg.min_tdest = min_tdest;
  endfunction


  task body();

    req = new();
    req.set_config(_cfg);
    req.set_counter_start(_counter);
    req.print_config();
    if (_cfg.axi4s_tdata_type == VIP_AXI4S_TDATA_CUSTOM_E) begin
      req.set_custom_data(_custom_data);
    end

    if (!req.randomize()) begin
      `uvm_error(get_name(), $sformatf("randomize() failed"))
    end
    start_item(req);
    finish_item(req);

    _counter += req.burst_length;
    set_dest(_dest + req.burst_length*VIP_AXI4S_CFG_C.VIP_AXI4S_TSTRB_WIDTH_P);

  endtask

endclass

// -----------------------------------------------------------------------------
// Blank sequence
// -----------------------------------------------------------------------------
class vip_axi4s_seq extends vip_axi4s_base_seq;

  `uvm_object_utils(vip_axi4s_seq)

  function new(string name = "vip_axi4s_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
  endtask

endclass
