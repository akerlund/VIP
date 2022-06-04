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

  typedef vip_axi4_item #(CFG_P) wr_responses_t [$];
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
  protected bool_t                                    _request_delay_enabled = FALSE;
  protected int                                       _request_delay_min     = 0;
  protected int                                       _request_delay_max     = 0;
  protected realtime                                  _clock_period          = 0.0;

  protected logic [CFG_P.VIP_AXI4_DATA_WIDTH_P-1 : 0] _custom_data  [$];
  protected bool_t                                    _custom_len_max        = TRUE;
  protected bool_t                                    _custom_len_zero       = FALSE;
  protected vip_axi4_item #(CFG_P)                    _wr_responses [$];
  protected vip_axi4_item #(CFG_P)                    _rd_responses [$];

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name = "vip_axi4_base_seq");
    super.new(name);
    _cfg = new();
    reset();
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void reset();
    vip_axi4_access_t axi4_access = _cfg.axi4_access;
    _cfg.reset();
    _cfg.axi4_access       = axi4_access;
    _cfg.max_id            = 2**CFG_P.VIP_AXI4_ID_WIDTH_P-1;
    _cfg.min_size          = size_as_enum(CFG_P.VIP_AXI4_STRB_WIDTH_P);
    _cfg.max_size          = size_as_enum(CFG_P.VIP_AXI4_STRB_WIDTH_P);
    _verbose               = TRUE;
    _log_denominator       = 100;
    _addr                  = '0;
    _enable_addr_increment = TRUE;
    _addr_increment        = '0;
    _counter               = '0;
    _nr_of_requests        = 0;
    _combine_requests      = FALSE;
    _request_delay_enabled = FALSE;
    _request_delay_min     = 0;
    _request_delay_max     = 0;
    _custom_data.delete();
    _custom_len_max        = TRUE;
    _custom_len_zero       = FALSE;
    _wr_responses.delete();
    _rd_responses.delete();
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the item configuration object.
  // ---------------------------------------------------------------------------
  function void set_config(vip_axi4_item_config cfg);
    _cfg = cfg;
    set_data_type(_cfg.axi4_data_type);
  endfunction

  // ---------------------------------------------------------------------------
  // Verbose; enables or disables status prints.
  // ---------------------------------------------------------------------------
  function void set_verbose(bool_t verbose);
    _verbose = verbose;
  endfunction

  // ---------------------------------------------------------------------------
  // Decides how often status' are printed, i.e., every "_log_denominator"
  // time when iterating "_nr_of_requests" requests.
  // ---------------------------------------------------------------------------
  function void set_log_denominator(input int log_denominator);
    _log_denominator = log_denominator;
  endfunction

  // ---------------------------------------------------------------------------
  // Returns all the collected write responses.
  // ---------------------------------------------------------------------------
  function wr_responses_t get_wr_responses();
    get_wr_responses = _wr_responses;
    _wr_responses.delete();
  endfunction

  // ---------------------------------------------------------------------------
  // Returns all the collected read responses.
  // ---------------------------------------------------------------------------
  function rd_responses_t get_rd_responses();
    get_rd_responses = _rd_responses;
    _rd_responses.delete();
  endfunction

  // ---------------------------------------------------------------------------
  // Sets if the AXI4 ID field is either a counter or randomized.
  // ---------------------------------------------------------------------------
  function void set_id_type(input vip_axi4_id_type_t axi4_id_type);
    _cfg.axi4_id_type = axi4_id_type;
  endfunction

  // ---------------------------------------------------------------------------
  // Selects data type; counter, random or custom (a list).
  // ---------------------------------------------------------------------------
  function void set_data_type(input vip_axi4_data_type_t axi4_data_type);
    _cfg.axi4_data_type = axi4_data_type;
    if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
      _nr_of_requests = 2**32-1;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the custom data to be used in the transaction requests.
  // ---------------------------------------------------------------------------
  function void set_custom_data(input custom_data_t custom_data);
    _custom_data = custom_data;
  endfunction

  // ---------------------------------------------------------------------------
  // If "_custom_len_max" is set to true then all data in "_custom_data" are
  // packed into transaction with the highest axlen set, e.g., 255. If there are
  // a remainder left from the list the last transaction will not have a
  // maximum axlen.
  // ---------------------------------------------------------------------------
  function void set_custom_len_max(input bool_t custom_len_max);
    _custom_len_max  = custom_len_max;
    _custom_len_zero = custom_len_max ? FALSE : _custom_len_zero;
  endfunction

  // ---------------------------------------------------------------------------
  // If "_custom_len_zero" is set to true then all data in "_custom_data" are
  // packed into transaction with the lowest axlen set, i.e., 0.
  // ---------------------------------------------------------------------------
  function void set_custom_len_zero(input bool_t custom_len_zero);
    _custom_len_zero = custom_len_zero;
    _custom_len_max  = custom_len_zero ? FALSE : _custom_len_max;
  endfunction

  // ---------------------------------------------------------------------------
  // Enables fetching of the write response from the sequencer.
  // ---------------------------------------------------------------------------
  function void set_get_wr_response(input bool_t get_wr_response);
    _cfg.get_wr_response = get_wr_response;
  endfunction

  // ---------------------------------------------------------------------------
  // Enables fetching of the read response from the sequencer.
  // ---------------------------------------------------------------------------
  function void set_get_rd_response(input bool_t get_rd_response);
    _cfg.get_rd_response = get_rd_response;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets how many requests that will be created. This is set to a maximum
  // value if custom data was chosen to be sent which.
  // ---------------------------------------------------------------------------
  function void set_nr_of_requests(input int nr_of_requests);
    _nr_of_requests = nr_of_requests;
    if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
      `uvm_warning(get_name(), $sformatf({"WARNING [AXI4] A call to ",
      "set_nr_of_requests(%0d) was made but the sequence is configured ",
      "with VIP_AXI4_DATA_CUSTOM_E"}, nr_of_requests))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // If "_combine_requests" are set to true then all (_nr_of_requests) will
  // be included into one vip_axi4_item item. The driver is driving each AXI4
  // channel independently, i.e., the requests of the address channels might be
  // finished before the data channels if several transactions are provided.
  // In other words, using this option will ensure the DUT can handle several
  // requests on the address bus before the write data arrives.
  // ---------------------------------------------------------------------------
  function void set_combine_requests(input bool_t combine_requests);
    _combine_requests = combine_requests;
  endfunction

  // ---------------------------------------------------------------------------
  // TODO: Rename to set_counter_data
  // This sets the start value of all data "xdata" when the sequence's
  // "axi4_data_type" is set to VIP_AXI4_DATA_COUNTER_E.
  // ---------------------------------------------------------------------------
  function void set_counter(input int counter);
    _counter = counter;
  endfunction

  // ---------------------------------------------------------------------------
  // Returns the current value of the data counter.
  // ---------------------------------------------------------------------------
  function longint get_counter();
    get_counter = _counter;
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void set_counter_id(input int counter_id);
    _cfg.counter_id = counter_id;
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function int get_counter_id();
    get_counter_id = _cfg.counter_id;
  endfunction

  // ---------------------------------------------------------------------------
  // Enables an address boundary used with randomization of the address.
  // If set to true the address boundary must be a power of two.
  // The constraint is: (axaddr % addr_boundary == 0).
  // ---------------------------------------------------------------------------
  function void set_enable_addr_boundary(input bool_t enable_boundary);
    _cfg.enable_boundary = enable_boundary;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the address boundary used with randomization (if enabled).
  // Allowed values are 0 and and value which is a power of two.
  // ---------------------------------------------------------------------------
  function void set_addr_boundary(input longint addr_boundary);
    _cfg.addr_boundary = addr_boundary;
  endfunction

  // ---------------------------------------------------------------------------
  // Enables custom address increment between each transaction. This is default
  // set to TRUE, i.e., the address will increase by as many bytes which was
  // either written or read.
  // ---------------------------------------------------------------------------
  function void set_enable_addr_increment(input bool_t enable_addr_increment);
    _enable_addr_increment = enable_addr_increment;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the custom address increment between each transaction (if enabled).
  // ---------------------------------------------------------------------------
  function void set_addr_increment(input longint addr_increment);
    _addr_increment = addr_increment;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets a definitive address which will be used as the configuration's
  // maximum and minimum values are set to equal, too.
  // ---------------------------------------------------------------------------
  function void set_addr(input logic [CFG_P.VIP_AXI4_ADDR_WIDTH_P-1 : 0] addr);
    _addr         = addr;
    _cfg.min_addr = addr;
    _cfg.max_addr = addr;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets a definitive length which will be used as the configuration's
  // maximum and minimum values are set to equal, too.
  // ---------------------------------------------------------------------------
  function void set_len(input logic unsigned [7 : 0] len);
    _cfg.min_len = len;
    _cfg.max_len = len;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the randomization of the wstrb signal to either only ones or random.
  // ---------------------------------------------------------------------------
  function void set_strb(input vip_axi4_strb_t axi4_strb);
    _cfg.axi4_strb = axi4_strb;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets a definitive ID which will be used as the configuration's
  // maximum and minimum values are set to equal, too.
  // ---------------------------------------------------------------------------
  function void set_cfg_id(input int max_id, input int min_id);
    _cfg.max_id = max_id;
    _cfg.min_id = min_id;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the configuration's maximum and minimum axaddr
  // values, i.e., randomization constraints.
  // ---------------------------------------------------------------------------
  function void set_cfg_addr(input longint max_addr, input longint min_addr);
    _cfg.max_addr = max_addr;
    _cfg.min_addr = min_addr;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the configuration's maximum and minimum axlen
  // values, i.e., randomization constraints.
  // ---------------------------------------------------------------------------
  function void set_cfg_len(
    input logic unsigned [7 : 0] max_len,
    input logic unsigned [7 : 0] min_len
  );
    _cfg.max_len = max_len;
    _cfg.min_len = min_len;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the configuration's maximum and minimum axsize
  // values, i.e., randomization constraints.
  // ---------------------------------------------------------------------------
  function void set_cfg_size(
    input logic unsigned [2 : 0] max_size,
    input logic unsigned [2 : 0] min_size
  );
    _cfg.max_size = max_size;
    _cfg.min_size = min_size;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the configuration's maximum and minimum axburst
  // values, i.e., randomization constraints.
  // ---------------------------------------------------------------------------
  function void set_cfg_burst(
    input logic unsigned [1 : 0] max_burst,
    input logic unsigned [1 : 0] min_burst
  );
    _cfg.max_burst = max_burst;
    _cfg.min_burst = min_burst;
  endfunction

  // ---------------------------------------------------------------------------
  // Enables a configurable delay between the request transactions.
  // If enabled the clock period must be provided with a call to
  // set_clock_period().
  // ---------------------------------------------------------------------------
  function void set_request_delay_enabled(input bool_t request_delay_enabled);
    _request_delay_enabled = request_delay_enabled;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the minimum request delay.
  // ---------------------------------------------------------------------------
  function void set_request_delay_min(input int min);
    _request_delay_min = min;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the maximum request delay.
  // ---------------------------------------------------------------------------
  function void set_request_delay_max(input int max);
    _request_delay_max = max;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the clock period which is used when delaying request transactions.
  // ---------------------------------------------------------------------------
  function void set_clock_period(input realtime clock_period);
    _clock_period = clock_period;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the string used or printing status', i.e., "Write" or "Read".
  // ---------------------------------------------------------------------------
  protected function void set_axi4_access(input vip_axi4_access_t axi4_access);
    _cfg.axi4_access = axi4_access;
    if (axi4_access == VIP_AXI4_WR_REQUEST_E) begin
      _log_access_type = "Write";
    end else if (axi4_access == VIP_AXI4_RD_REQUEST_E) begin
      _log_access_type = "Read";
    end else begin
      _log_access_type = "Response";
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Wait for some amount (int delay) clock periods.
  // ---------------------------------------------------------------------------
  protected task clk_delay(input int delay);
    if (_clock_period == 0.0) begin
      `uvm_fatal(get_name(), "FATAL [AXI4] Clock period is undefined")
    end
    #(delay*_clock_period);
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
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
        `uvm_error(get_name(), $sformatf("ERROR [AXI4] randomize() failed"))
        req.print_config();
      end
      _combined_request.push_back(req);
      delete_custom_data(req.awlen + 1);
      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E && !_custom_data.size()) begin
        _nr_of_requests = 0;
      end
      increase_counters();
      increase_address();
      _i0 = 1;
    end

    for (int i = _i0; i < _nr_of_requests; i++) begin

      if (_verbose == TRUE && _combine_requests == FALSE &&
          (i % _log_denominator == 0 || i == _nr_of_requests-1)) begin
        if (_cfg.axi4_data_type != VIP_AXI4_DATA_CUSTOM_E) begin
          `uvm_info(get_name(), $sformatf("INFO [AXI4] %s (%0d/%0d)", _log_access_type, i+1, _nr_of_requests), UVM_LOW)
        end else begin
          `uvm_info(get_name(), $sformatf("INFO [AXI4] %s (%0d)", _log_access_type, i+1), UVM_LOW)
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
        `uvm_error(get_name(), $sformatf("ERROR [AXI4] randomize() failed"))
        req.print_config();
      end

      if (_combine_requests == FALSE) begin
        start_item(req);
        finish_item(req);
      end else begin
        _combined_request.push_back(req);
      end

      delete_custom_data(req.awlen + 1);
      increase_counters();
      increase_address();

      if (_combine_requests == FALSE) begin

        if (_cfg.get_wr_response == TRUE) begin
          get_response(rsp);
          _wr_responses.push_back(rsp);
        end

        if (_cfg.get_rd_response == TRUE) begin
          get_response(rsp);
          _rd_responses.push_back(rsp);
        end
      end

      if (_cfg.axi4_data_type == VIP_AXI4_DATA_CUSTOM_E) begin
        if (!_custom_data.size()) begin
          break;
        end
      end

      if (_request_delay_enabled == TRUE) begin
        clk_delay($urandom_range(_request_delay_max, _request_delay_min));
      end
    end

    if (_combine_requests == TRUE) begin

      if (_verbose == TRUE) begin
        `uvm_info(get_name(), $sformatf("INFO [AXI4] Starting (%0d) combined (%s) requests", _combined_request.size(), _log_access_type), UVM_LOW)
      end

      req = new();
      req = _combined_request.pop_front();
      req.req_queue = _combined_request;
      start_item(req);
      finish_item(req);

      if (_cfg.get_wr_response == TRUE) begin
        get_response(rsp);
        _wr_responses = rsp.req_queue;
        rsp.req_queue.delete();
        _wr_responses.push_front(rsp);
      end

      if (_cfg.get_rd_response == TRUE) begin
        get_response(rsp);
        _rd_responses = rsp.req_queue;
        rsp.req_queue.delete();
        _rd_responses.push_front(rsp);
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Increases the data and ID counters.
  // ---------------------------------------------------------------------------
  protected function void increase_counters();
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

  // ---------------------------------------------------------------------------
  // Increases the current address.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Sets the new address constraints used when writing custom data.
  // ---------------------------------------------------------------------------
  protected function void set_awlen_for_custom_data();
    if (_custom_len_zero == TRUE) begin
      set_cfg_len(0, 0);
    end
    else if (_custom_data.size() >= 255) begin
      if (_custom_len_max == TRUE) begin
        set_cfg_len(255, 255);
      end else begin
        set_cfg_len(255, 0);
      end
    end else begin
      if (_custom_len_max == TRUE) begin
        set_cfg_len(_custom_data.size()-1, _custom_data.size()-1);
      end else begin
        set_cfg_len(_custom_data.size()-1, 0);
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Deletes some amount (int n) of the custom data.
  // ---------------------------------------------------------------------------
  protected function void delete_custom_data(input int n);
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
