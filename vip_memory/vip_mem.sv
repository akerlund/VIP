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
// TODO: Memory: unaligned memory addresses, wrap, size
//
////////////////////////////////////////////////////////////////////////////////

class vip_mem #(
  vip_mem_cfg_t MEM_P = '{default: '0}
 ) extends uvm_object;

  typedef logic [MEM_P.ADDR_WIDTH_P-1 : 0]   mem_addr_type_t;
  typedef logic [MEM_P.DATA_BYTES_P*8-1 : 0] mem_get_type_t [mem_addr_type_t];

  // Memory
  protected logic [MEM_P.DATA_BYTES_P*8-1 : 0] _memory [mem_addr_type_t];
  protected longint                            _memory_depth;
  protected vip_mem_x_severity_t               _wr_x_severity = VIP_MEM_X_IGNORE_E;
  protected vip_mem_x_severity_t               _rd_x_severity = VIP_MEM_X_IGNORE_E;

  // Settings
  protected bool_t _rd_x_responses = FALSE;

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new (string name = "vip_mem");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // This function will set all data in the memory to zero
  // ---------------------------------------------------------------------------
  function void reset();
    _memory.delete();
  endfunction

  // ---------------------------------------------------------------------------
  // This function will set all data
  // ---------------------------------------------------------------------------
  function void set(
      input logic [MEM_P.DATA_BYTES_P*8-1 : 0] memory [mem_addr_type_t]
    );
    _memory.delete();
    _memory = memory;
  endfunction

  // ---------------------------------------------------------------------------
  // Set the depth of the memory
  // ---------------------------------------------------------------------------
  function void set_depth(input longint memory_depth);
    _memory_depth = memory_depth;
  endfunction

  // ---------------------------------------------------------------------------
  // Set the depth of the memory as a function of an highest address
  // ---------------------------------------------------------------------------
  function void set_addr_width(input longint addr_width);
    _memory_depth = 2**(addr_width - $clog2(MEM_P.DATA_BYTES_P));
    if (_memory_depth == 0 || addr_width == 0) begin
      `uvm_fatal(get_name(), $sformatf("[MEM] The memory depth was calculated to (%0d)", _memory_depth))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the severity level of writing X
  // ---------------------------------------------------------------------------
  function void set_wr_x_severity(input vip_mem_x_severity_t wr_x_severity);
    _wr_x_severity = wr_x_severity;
  endfunction

  // ---------------------------------------------------------------------------
  // Controls if the memory will responds with X if the address is previously
  // not written to.
  // ---------------------------------------------------------------------------
  function void set_rd_x_responses(input bool_t rd_x_responses);
    _rd_x_responses = rd_x_responses;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the severity level of reading X
  // ---------------------------------------------------------------------------
  function void set_rd_x_severity(input vip_mem_x_severity_t rd_x_severity);
    _rd_x_severity = rd_x_severity;
  endfunction

  // ---------------------------------------------------------------------------
  // This function will get all data
  // ---------------------------------------------------------------------------
  function mem_get_type_t get();
    return _memory;
  endfunction

  // ---------------------------------------------------------------------------
  // This function will randomize all data in the memory
  // ---------------------------------------------------------------------------
  function void randomize_memory();
    logic [MEM_P.DATA_BYTES_P*8-1 : 0] _r;
    `uvm_info(get_name(), $sformatf("INFO [MEM] Randomizing (%0d) memory entries", _memory_depth), UVM_LOW)
    for (longint i = 0; i < _memory_depth; i++) begin
      void'(std::randomize(_r));
      _memory[i] = _r;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Write an array of data (data) to the memory starting at some address (addr)
  // ---------------------------------------------------------------------------
  function void wr(
      input logic   [MEM_P.ADDR_WIDTH_P-1 : 0] addr,
      input logic [MEM_P.DATA_BYTES_P*8-1 : 0] data [$]
    );

    longint memory_start_index = unsigned'(addr) / MEM_P.DATA_BYTES_P;
    longint memory_stop_index  = memory_start_index + data.size() - 1;

    if (memory_start_index > (_memory_depth-1) || memory_stop_index > _memory_depth) begin
      `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Memory range undefined (%0d - %0d) > (%0d)",
        memory_start_index, memory_stop_index, _memory_depth))
    end

    foreach (data[i]) begin
      _memory[memory_start_index + i] = data[i];
    end

  endfunction

  // ---------------------------------------------------------------------------
  // Write a VIP AXI4 item
  // ---------------------------------------------------------------------------
  function void wr_axi4(
      input logic   [MEM_P.ADDR_WIDTH_P-1 : 0] awaddr,
      input logic                      [7 : 0] awlen,
      input logic [MEM_P.DATA_BYTES_P*8-1 : 0] wdata [],
      input logic   [MEM_P.DATA_BYTES_P-1 : 0] wstrb []
    );

    logic [MEM_P.DATA_BYTES_P*8-1 : 0] write_row;

    longint memory_start_index = 0;
    longint write_range        = 0;
    longint memory_stop_index  = 0;
    longint write_counter      = 0;

    memory_start_index = unsigned'(awaddr) / MEM_P.DATA_BYTES_P;
    write_range        = unsigned'(awlen) + 1;
    memory_stop_index  = memory_start_index + write_range;

    if (memory_start_index > (_memory_depth-1) || memory_stop_index > _memory_depth) begin
      `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Memory range undefined (%0d - %0d) > (%0d)", memory_start_index, memory_stop_index, _memory_depth))
    end

    // Writing the data to memory
    write_counter = 0;
    for (longint i = memory_start_index; i < memory_stop_index; i++) begin

      if (wstrb[write_counter] === '1) begin

        if (_wr_x_severity != VIP_MEM_X_IGNORE_E) begin
          if (^wdata[write_counter] === 1'bX) begin
            if (_wr_x_severity == VIP_MEM_X_WARNING_E) begin
              `uvm_warning(get_name(), $sformatf("WARNING [MEM] Writing X to index (%0d), address = (%h)", memory_start_index, awaddr))
            end else begin
              `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Writing X to index (%0d), address = (%h)", memory_start_index, awaddr))
            end
          end
        end

        _memory[i] = wdata[write_counter];

      end
      else begin

        // Only writing bytes that have 'wstrb' high
        write_row = '0;

        for (longint s = 0; s < MEM_P.DATA_BYTES_P; s++) begin

          if (wstrb[write_counter][s]) begin

            if (_wr_x_severity != VIP_MEM_X_IGNORE_E) begin
              if (^wdata[write_counter][8*s +: 8] === 1'bX) begin
                if (_wr_x_severity == VIP_MEM_X_WARNING_E) begin
                  `uvm_warning(get_name(), $sformatf("WARNING [MEM] Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, awaddr, s))
                end else begin
                  `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, awaddr, s))
                end
              end
            end

            write_row[8*s +: 8] = wdata[write_counter][8*s +: 8];

          end
          else begin

            if (!_memory.exists(i)) begin
              write_row[8*s +: 8] = '0;
            end
            else if (^_memory[i][8*s +: 8] === 1'bX) begin
              write_row[8*s +: 8] = '0;
            end
            else begin
              write_row[8*s +: 8] = _memory[i][8*s +: 8];
            end
          end
        end

        _memory[i] = write_row;
      end
      write_counter++;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data from an index in the memory array
  // ---------------------------------------------------------------------------
  function logic [MEM_P.DATA_BYTES_P*8-1 : 0] rd_index(input longint index);
    if (!_memory.exists(index)) begin
      if (_rd_x_responses == TRUE) begin
        rd_index = 'x;
        print_x_read(index);
      end
      else begin
        rd_index = '0;
      end
    end else begin
      rd_index = _memory[index];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data from an address in the memory array
  // ---------------------------------------------------------------------------
  function logic [MEM_P.DATA_BYTES_P*8-1 : 0] rd_addr(input longint addr);

    longint read_index = unsigned'(addr) / MEM_P.DATA_BYTES_P;

    if (read_index > (_memory_depth-1)) begin
      `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Memory range undefined (%0d)", read_index))
    end

    if (!_memory.exists(read_index)) begin
      if (_rd_x_responses == TRUE) begin
        rd_addr = 'x;
        print_x_read(read_index);
      end
      else begin
        rd_addr = '0;
      end
    end else begin
      rd_addr = _memory[read_index];
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected function void print_x_read(input longint index);

    longint addr;

    if (_rd_x_severity == VIP_MEM_X_WARNING_E) begin
      addr = MEM_P.DATA_BYTES_P * index;
      `uvm_warning(get_name(), $sformatf("WARNING [MEM] Reading X from index (%0d), address = (%h)", index, addr))
    end
    else if (_rd_x_severity == VIP_MEM_X_FATAL_E) begin
      addr = MEM_P.DATA_BYTES_P * index;
      `uvm_fatal(get_name(), $sformatf("FATAL [MEM] Reading X from index (%0d), address = (%h)", index, addr))
    end
  endfunction

endclass
