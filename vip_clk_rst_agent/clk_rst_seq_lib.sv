////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
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

class reset_sequence extends uvm_sequence #(clk_rst_item);

  `uvm_object_utils(reset_sequence);

  protected realtime _rst_time;

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name = "reset_sequence");
    super.new(name);
    _rst_time = 100.0;
  endfunction

  // ---------------------------------------------------------------------------
  // Sets the reset duration.
  // ---------------------------------------------------------------------------
  function void set_rst_time(input realtime rst_time);
    _rst_time = rst_time;
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  task body();

    req = new("item");

    // Enable reset
    req.reset_edge  = RESET_ASYNCHRONOUSLY_E;
    req.reset_value = RESET_ACTIVE_E;
    start_item(req);
    finish_item(req);

    #_rst_time;

    // Disable reset
    req.reset_edge  = RESET_AT_CLK_RISING_EDGE_E;
    req.reset_value = RESET_INACTIVE_E;
    start_item(req);
    finish_item(req);

  endtask

endclass
