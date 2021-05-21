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

// -----------------------------------------------------------------------------
// Base Sequence
// -----------------------------------------------------------------------------
class vip_axi4s_base_seq #(vip_axi4s_cfg_t CFG_P = '{default: '0})
  extends uvm_sequence #(vip_axi4s_item #(CFG_P));

  `uvm_object_param_utils(vip_axi4s_base_seq #(CFG_P))

  typedef logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] custom_data_t [$];

  protected bool_t                                        _verbose                = TRUE;
  protected int                                           _log_denominator        = 100;
  protected vip_axi4s_item_config                         _cfg;
  protected logic   [CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1 : 0] _tdest                  = '0;
  protected bool_t                                        _enable_tdest_increment = TRUE;
  protected logic   [CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1 : 0] _tdest_increment        = '0;
  protected logic   [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] _counter                = '0;
  protected int                                           _nr_of_bursts           = 1;
  protected logic   [CFG_P.VIP_AXI4S_TDATA_WIDTH_P-1 : 0] _custom_data  [$];

  function new(string name = "vip_axi4s_base_seq");
    super.new(name);
    _cfg = new();
    _cfg.max_tid          = 2**CFG_P.VIP_AXI4S_TID_WIDTH_P-1;
    _cfg.max_tdest        = 2**CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1;
    _cfg.max_burst_length = 256;
  endfunction


  function void set_verbose(bool_t verbose);
    _verbose = verbose;
  endfunction


  function void set_log_denominator(int log_denominator);
    _log_denominator = log_denominator;
  endfunction


  function void set_id_type(vip_axi4s_tid_type_t axi4s_tid_type);
    _cfg.axi4s_tid_type = axi4s_tid_type;
  endfunction


  function void set_data_type(vip_axi4s_tdata_type_t axi4s_tdata_type);
    _cfg.axi4s_tdata_type = axi4s_tdata_type;
    if (_cfg.axi4s_tdata_type == VIP_AXI4S_TDATA_CUSTOM_E) begin
      _nr_of_bursts = 1;
    end
  endfunction


  function void set_custom_data(custom_data_t custom_data);
    _custom_data = custom_data;
  endfunction


  function void set_nr_of_bursts(int nr_of_bursts);
    _nr_of_bursts = nr_of_bursts;
  endfunction


  function void set_counter(int counter);
    _counter = counter;
  endfunction


  function int get_counter();
    get_counter = _counter;
  endfunction


  function void set_enable_tdest_increment(bool_t enable_tdest_increment);
    _enable_tdest_increment = enable_tdest_increment;
  endfunction


  function void set_tid(logic [CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1 : 0] tid);
    _cfg.min_tid = tid;
    _cfg.max_tid = tid;
  endfunction


  function void set_tdest(logic [CFG_P.VIP_AXI4S_TDEST_WIDTH_P-1 : 0] tdest);
    _tdest         = tdest;
    _cfg.min_tdest = tdest;
    _cfg.max_tdest = tdest;
  endfunction


  function void set_burst_length(int burst_length);
    _cfg.min_burst_length = burst_length;
    _cfg.max_burst_length = burst_length;
  endfunction


  function void set_tstrb(vip_axi4s_tstrb_t axi4s_tstrb);
    _cfg.axi4s_tstrb = axi4s_tstrb;
  endfunction


  function void set_cfg_tid(int max_tid, int min_tid);
    _cfg.min_tid = min_tid;
    _cfg.max_tid = max_tid;
  endfunction


  function void set_cfg_tdest(int max_tdest, int min_tdest);
    _cfg.min_tdest = min_tdest;
    _cfg.max_tdest = max_tdest;
  endfunction


  function void set_cfg_burst_length(int max_burst_length, int min_burst_length);
    _cfg.min_burst_length = min_burst_length;
    _cfg.max_burst_length = max_burst_length;
  endfunction


  task body();

    for (int i = 0; i < _nr_of_bursts; i++) begin

      if (_verbose == TRUE && (i % _log_denominator == 0 || i == _nr_of_bursts-1)) begin
        `uvm_info(get_name(), $sformatf("%s (%0d/%0d)", "Burst", i+1, _nr_of_bursts), UVM_LOW)
      end

      req = new();
      if (_cfg.axi4s_tdata_type == VIP_AXI4S_TDATA_CUSTOM_E) begin
        req.set_custom_data(_custom_data);
        set_burst_length(_custom_data.size());
      end
      req.set_config(_cfg);
      req.set_counter_start(_counter);

      if (!req.randomize()) begin
        `uvm_error(get_name(), $sformatf("randomize() failed"))
      end

      start_item(req);
      finish_item(req);

      _counter += req.burst_length;

      if (_cfg.axi4s_tid_type == VIP_AXI4S_TID_COUNTER_E) begin
        _cfg.counter_id++;
        if (_cfg.counter_id == 2**CFG_P.VIP_AXI4S_TID_WIDTH_P) begin
          _cfg.counter_id = 0;
        end
      end

      if (_enable_tdest_increment) begin
        if (_tdest_increment == '0) begin
          set_tdest(_tdest + req.burst_length*CFG_P.VIP_AXI4S_TSTRB_WIDTH_P);
        end else begin
          set_tdest(_tdest + _tdest_increment);
        end
      end

    end
  endtask
endclass

// -----------------------------------------------------------------------------
// Blank sequence
// -----------------------------------------------------------------------------
class vip_axi4s_seq #(vip_axi4s_cfg_t CFG_P = '{default: '0})
  extends vip_axi4s_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4s_seq #(CFG_P))

  function new(string name = "vip_axi4s_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
  endtask

endclass
