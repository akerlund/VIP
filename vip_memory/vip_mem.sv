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

  typedef logic [MEM_P.ADDR_WIDTH_P-1 : 0] mem_addr_type_t;

  // Memory
  protected logic [MEM_P.DATA_BYTES_P*8-1 : 0] _memory [mem_addr_type_t];
  protected longint                            _memory_depth;
  protected vip_mem_x_severity_t               _mem_x_severity = VIP_MEM_X_WR_IGNORE_E;

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
  // Set the depth of the memory
  // ---------------------------------------------------------------------------
  function void set_depth(int memory_depth);
    _memory_depth = memory_depth;
  endfunction

  // ---------------------------------------------------------------------------
  // Set the depth of the memory as a function of an highest address
  // ---------------------------------------------------------------------------
  function void set_addr_width(int addr_width);
    _memory_depth = 2**(addr_width - $clog2(MEM_P.DATA_BYTES_P));
    if (_memory_depth == 0 || addr_width == 0) begin
      `uvm_fatal(get_name(), $sformatf("[MEM] The memory depth was calculated to (%0d)", _memory_depth))
    end
  endfunction

  // ---------------------------------------------------------------------------
  // This function will randomize all data in the memory
  // ---------------------------------------------------------------------------
  function void randomize_memory();
    logic [MEM_P.DATA_BYTES_P*8-1 : 0] _r;
    for (int i = 0; i < (2**_memory_depth) / MEM_P.DATA_BYTES_P; i++) begin
      void'(std::randomize(_r));
      _memory[i] = _r;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Write an array of data (data) to the memory starting at some address (addr)
  // ---------------------------------------------------------------------------
  function void wr(
      logic   [MEM_P.ADDR_WIDTH_P-1 : 0] addr,
      logic [MEM_P.DATA_BYTES_P*8-1 : 0] data [$]
    );

    int memory_start_index = unsigned'(addr) / MEM_P.DATA_BYTES_P;
    int memory_stop_index  = memory_start_index + data.size() - 1;

    if (memory_start_index > (_memory_depth-1) || memory_stop_index > _memory_depth) begin
      `uvm_fatal(get_name(), $sformatf("[MEM] Memory range undefined (%0d - %0d) > (%0d)",
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
      logic   [MEM_P.ADDR_WIDTH_P-1 : 0] awaddr,
      logic                      [7 : 0] awlen,
      logic [MEM_P.DATA_BYTES_P*8-1 : 0] wdata [],
      logic   [MEM_P.DATA_BYTES_P-1 : 0] wstrb []
    );

    logic [MEM_P.DATA_BYTES_P*8-1 : 0] write_row;

    int memory_start_index = 0;
    int write_range        = 0;
    int memory_stop_index  = 0;
    int write_counter      = 0;

    memory_start_index = unsigned'(awaddr) / MEM_P.DATA_BYTES_P;
    write_range        = unsigned'(awlen) + 1;
    memory_stop_index  = memory_start_index + write_range;

    if (memory_start_index > (_memory_depth-1) || memory_stop_index > _memory_depth) begin
      `uvm_fatal(get_name(), $sformatf("[MEM] Memory range undefined (%0d - %0d) > (%0d)", memory_start_index, memory_stop_index, _memory_depth))
    end

    // Writing the data to memory
    write_counter = 0;
    for (int i = memory_start_index; i < memory_stop_index; i++) begin

      if (wstrb[write_counter] === '1) begin

        if (_mem_x_severity != VIP_MEM_X_WR_IGNORE_E) begin
          if (^wdata[write_counter] === 1'bX) begin
            if (_mem_x_severity == VIP_MEM_X_WR_WARNING_E) begin
              `uvm_warning(get_name(), $sformatf("[MEM] Writing X to index (%0d), address = (%h)", memory_start_index, awaddr))
            end else begin
              `uvm_fatal(get_name(), $sformatf("[MEM] Writing X to index (%0d), address = (%h)", memory_start_index, awaddr))
            end
          end
        end

        _memory[i] = wdata[write_counter];

      end
      else begin

        // Only writing bytes that have 'wstrb' high
        write_row = '0;

        for (int s = 0; s < MEM_P.DATA_BYTES_P; s++) begin

          if (wstrb[write_counter][s]) begin

            if (_mem_x_severity != VIP_MEM_X_WR_IGNORE_E) begin
              if (^wdata[write_counter][8*s +: 8] === 1'bX) begin
                if (_mem_x_severity == VIP_MEM_X_WR_WARNING_E) begin
                  `uvm_warning(get_name(), $sformatf("[MEM] Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, awaddr, s))
                end else begin
                  `uvm_fatal(get_name(), $sformatf("[MEM] Writing X to index (%0d), address = (%h), byte = (%0d)", memory_start_index, awaddr, s))
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
  function logic [MEM_P.DATA_BYTES_P*8-1 : 0] rd_index(int index);
    if (!_memory.exists(index)) begin
      rd_index = '0;
    end else begin
      rd_index = _memory[index];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // This function returns data from an address in the memory array
  // ---------------------------------------------------------------------------
  function logic [MEM_P.DATA_BYTES_P*8-1 : 0] rd_addr(longint addr);

    int read_index = unsigned'(addr) / MEM_P.DATA_BYTES_P;

    if (read_index > (_memory_depth-1)) begin
      `uvm_fatal(get_name(), $sformatf("MEM: Memory range undefined (%0d)", read_index))
    end

    if (!_memory.exists(read_index)) begin
      rd_addr = '0;
    end else begin
      rd_addr = _memory[read_index];
    end
  endfunction

endclass
