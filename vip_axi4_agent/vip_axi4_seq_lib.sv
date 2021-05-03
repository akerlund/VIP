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
// Base Sequence for VIP AXI4
// -----------------------------------------------------------------------------
class vip_axi4_base_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends uvm_sequence #(vip_axi4_item #(CFG_P));

  `uvm_object_param_utils(vip_axi4_base_seq #(CFG_P))

  typedef vip_axi4_item #(CFG_P) rd_responses_t [$];
  typedef logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] custom_data_t  [$];

  protected bool_t                                    _verbose               = TRUE;
  protected int                                       _log_denominator       = 100;
  protected string                                    _log_access_type       = "Write";
  protected vip_axi4_item_config                      _cfg;
  protected logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _addr                  = '0;
  protected bool_t                                    _enable_addr_increment = TRUE;
  protected logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] _addr_increment        = '0;
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _counter               = '0;
  protected int unsigned                              _nr_of_requests        = 0;
  protected bool_t                                    _combine_requests      = FALSE;
  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _custom_data  [$];
  protected vip_axi4_item #(CFG_P)                    _rd_responses [$];
  protected vip_axi4_item #(CFG_P)                    _rd_response;

  function new(string name = "vip_axi4_base_seq");
    super.new(name);
    _cfg = new();
    _cfg.max_id   = 2**CFG_P.VIP_AXI4_ID_WIDTH_P-1;
    _cfg.min_size = size_as_enum(CFG_P.VIP_AXI4_STRB_WIDTH_P);
    _cfg.max_size = size_as_enum(CFG_P.VIP_AXI4_STRB_WIDTH_P);
  endfunction


  function void set_config(vip_axi4_item_config cfg);
    _cfg = cfg;
    set_data_type(_cfg.axi4_data_type);
  endfunction


  function void set_log_access_type(string log_access_type);
    _log_access_type = log_access_type;
  endfunction


  function void set_verbose(bool_t verbose);
    _verbose = verbose;
  endfunction


  function void set_log_denominator(int log_denominator);
    _log_denominator = log_denominator;
  endfunction


  function rd_responses_t get_rd_responses();
    get_rd_responses = _rd_responses;
    _rd_responses.delete();
  endfunction


  protected function void set_axi4_access(vip_axi4_access_t axi4_access);
    _cfg.axi4_access = axi4_access;
    if (axi4_access == VIP_AXI4_WR_REQUEST_E) begin
      set_log_access_type("Write");
    end else if (axi4_access == VIP_AXI4_RD_REQUEST_E) begin
      set_log_access_type("Read");
    end else begin
      set_log_access_type("Response");
    end
  endfunction


  function void set_id_type(vip_axi4_id_type_t axi4_id_type);
    _cfg.axi4_id_type = axi4_id_type;
  endfunction


  function void set_data_type(vip_axi4_data_type_t axi4_data_type);
    _cfg.axi4_data_type = axi4_data_type;
    if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
      _nr_of_requests = 2**32-1;
    end
  endfunction


  function void set_custom_data(custom_data_t custom_data);
    _custom_data = custom_data;
  endfunction


  function void set_get_rd_response(bool_t get_rd_response);
    _cfg.get_rd_response = get_rd_response;
  endfunction


  function void set_nr_of_requests(int nr_of_requests);
    _nr_of_requests = nr_of_requests;
  endfunction


  function void set_combine_requests(bool_t combine_requests);
    _combine_requests = combine_requests;
  endfunction


  function void set_counter(int counter);
    _counter = counter;
  endfunction


  function longint get_counter();
    get_counter = _counter;
  endfunction


  function void set_enable_addr_boundary(bool_t enable_boundary);
    _cfg.enable_boundary = enable_boundary;
  endfunction


  function void set_counter_id(int counter_id);
    _cfg.counter_id = counter_id;
  endfunction


  function int get_counter_id();
    get_counter_id = _cfg.counter_id;
  endfunction


  function void set_addr_boundary(longint addr_boundary);
    _cfg.addr_boundary = addr_boundary;
  endfunction


  function void set_enable_addr_increment(bool_t enable_addr_increment);
    _enable_addr_increment = enable_addr_increment;
  endfunction


  function void set_addr_increment(longint addr_increment);
    _addr_increment = addr_increment;
  endfunction


  function void set_addr(logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] addr);
    _addr         = addr;
    _cfg.min_addr = addr;
    _cfg.max_addr = addr;
  endfunction


  function void set_len(logic unsigned [7 : 0] len);
    _cfg.min_len = len;
    _cfg.max_len = len;
  endfunction


  function void set_strb(vip_axi4_strb_t axi4_strb);
    _cfg.axi4_strb = axi4_strb;
  endfunction


  function void set_cfg_id(int max_id, int min_id);
    _cfg.max_id = max_id;
    _cfg.min_id = min_id;
  endfunction


  function void set_cfg_addr(longint max_addr, longint min_addr);
    _cfg.max_addr = max_addr;
    _cfg.min_addr = min_addr;
  endfunction


  function void set_cfg_len(logic unsigned [7 : 0] max_len, logic unsigned [7 : 0] min_len);
    _cfg.max_len = max_len;
    _cfg.min_len = min_len;
  endfunction


  function void set_cfg_size(logic unsigned [2 : 0] max_size, logic unsigned [2 : 0] min_size);
    _cfg.max_size = max_size;
    _cfg.min_size = min_size;
  endfunction


  function void set_cfg_burst(logic unsigned [1 : 0] max_burst, logic unsigned [1 : 0] min_burst);
    _cfg.max_burst = max_burst;
    _cfg.min_burst = min_burst;
  endfunction


  task body();

    vip_axi4_item #(CFG_P) _combined_request [$];
    int _i0 = 0;

    if (_combine_requests == TRUE) begin

      req = new();
      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
        req.set_custom_data(_custom_data);
        set_awlen_for_custom_data();
      end
      req.set_config(_cfg);
      req.set_counter_start(_counter);
      if (!req.randomize()) begin
        `uvm_error(get_name(), $sformatf("randomize() failed"))
        req.print_config();
      end
      _combined_request.push_back(req);
      delete_custom_data(req.awlen + 1);
      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E && !_custom_data.size()) begin
        _nr_of_requests = 0;
      end
      increase_counter();
      increase_address();
      _i0 = 1;
    end

    for (int i = _i0; i < _nr_of_requests; i++) begin

      if (_verbose == TRUE && _combine_requests == FALSE &&
          (i % _log_denominator == 0 || i == _nr_of_requests-1)) begin
        if (_cfg.axi4_data_type != VIP_AXI4_DATA_CUSTOM_E) begin
          `uvm_info(get_name(), $sformatf("%s (%0d/%0d)", _log_access_type, i+1, _nr_of_requests), UVM_LOW)
        end else begin
          `uvm_info(get_name(), $sformatf("%s (%0d)", _log_access_type, i+1), UVM_LOW)
        end
      end

      req = new();
      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
        req.set_custom_data(_custom_data);
        set_awlen_for_custom_data();
      end
      req.set_config(_cfg);
      req.set_counter_start(_counter);

      if (!req.randomize()) begin
        `uvm_error(get_name(), $sformatf("randomize() failed"))
        req.print_config();
      end

      if (_combine_requests == FALSE) begin
        start_item(req);
        finish_item(req);
      end else begin
        _combined_request.push_back(req);
      end

      delete_custom_data(req.awlen + 1);
      increase_counter();
      increase_address();

      if (_combine_requests == FALSE) begin
        if (_cfg.get_rd_response) begin
          get_response(rsp);
          _rd_responses.push_back(rsp);
        end
      end

      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
        if (!_custom_data.size()) begin
          break;
        end
      end
    end

    if (_combine_requests == TRUE) begin
      if (_verbose == TRUE) begin
        `uvm_info(get_name(), $sformatf("Starting (%0d) combined (%s) requests", _combined_request.size(), _log_access_type), UVM_LOW)
      end
      req = new();
      req = _combined_request.pop_front();
      req.req_queue = _combined_request;
      start_item(req);
      finish_item(req);
      if (_cfg.get_rd_response) begin
        get_response(rsp);
        _rd_responses = rsp.req_queue;
        rsp.req_queue.delete();
        _rd_responses.push_front(rsp);
      end
    end

  endtask


  protected function void increase_counter();
    if (_cfg.axi4_data_type == VIP_AXI4_DATA_COUNTER_E) begin
      _counter = _cfg.axi4_access == VIP_AXI4_WR_REQUEST_E ? _counter + req.awlen + 1 :
                                                             _counter + req.arlen + 1;
    end
    if (_cfg.axi4_id_type == VIP_AXI4_ID_COUNTER_E) begin
      _cfg.counter_id++;
      if (_cfg.counter_id == 2**CFG_P.VIP_AXI4_ID_WIDTH_P) begin
        _cfg.counter_id = 0;
      end
    end
  endfunction


  protected function void increase_address();
    longint _new_addr;
    if (_enable_addr_increment == TRUE) begin
      if (_addr_increment == '0) begin
        if (_cfg.axi4_access == VIP_AXI4_WR_REQUEST_E) begin
          _new_addr = _addr + (req.awlen + 1)*CFG_P.VIP_AXI4_STRB_WIDTH_P;
        end else begin
          _new_addr = _addr + (req.arlen + 1)*CFG_P.VIP_AXI4_STRB_WIDTH_P;
        end
      end else begin
        _new_addr = _addr + _addr_increment;
      end
      set_addr(_new_addr);
    end
  endfunction


  protected function void set_awlen_for_custom_data();
    if (_custom_data.size() >= 255) begin
      set_cfg_len(255, 0);
    end else begin
      set_cfg_len(_custom_data.size()-1, 0);
    end
  endfunction


  protected function void delete_custom_data(int n);
    if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
      for (int i = 0; i < n; i++) begin _custom_data.delete(0); end
    end
  endfunction

endclass

// -----------------------------------------------------------------------------
// Base sequence for writes
// -----------------------------------------------------------------------------
class vip_axi4_write_base_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_write_base_seq #(CFG_P))

  function new(string name = "vip_axi4_write_base_seq");
    super.new(name);
  endfunction

  task body();
    set_axi4_access(VIP_AXI4_WR_REQUEST_E);
    super.body();
  endtask

endclass

// -----------------------------------------------------------------------------
// Base sequence for reads
// -----------------------------------------------------------------------------
class vip_axi4_read_base_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_read_base_seq #(CFG_P))

  function new(string name = "vip_axi4_read_base_seq");
    super.new(name);
  endfunction

  task body();
    set_axi4_access(VIP_AXI4_RD_REQUEST_E);
    super.body();
  endtask

endclass

// -----------------------------------------------------------------------------
// Base sequence for responses
// -----------------------------------------------------------------------------
class vip_axi4_response_base_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_response_base_seq #(CFG_P))

  function new(string name = "vip_axi4_response_base_seq");
    super.new(name);
  endfunction

  task body();
    set_axi4_access(VIP_AXI4_RD_RESPONSE_E);
    super.body();
  endtask

endclass

// -----------------------------------------------------------------------------
// WRITE: Blank sequence
// -----------------------------------------------------------------------------
class vip_axi4_write_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_write_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_write_seq #(CFG_P))

  function new(string name = "vip_axi4_write_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
  endtask

endclass

// -----------------------------------------------------------------------------
// READ: Blank sequence
// -----------------------------------------------------------------------------
class vip_axi4_read_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_read_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_read_seq #(CFG_P))

  function new(string name = "vip_axi4_read_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
  endtask

endclass

// -----------------------------------------------------------------------------
// RESPONSE: Blank sequence
// -----------------------------------------------------------------------------
class vip_axi4_response_seq #(vip_axi4_cfg_t CFG_P = '{default: '0})
  extends vip_axi4_response_base_seq #(CFG_P);

  `uvm_object_param_utils(vip_axi4_response_seq #(CFG_P))

  function new(string name = "vip_axi4_response_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
  endtask

endclass
