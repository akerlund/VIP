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

class clk_rst_driver extends uvm_driver #(clk_rst_item);

  protected virtual clk_rst_if _vif;
  protected clk_rst_config     _cfg;

  `uvm_component_utils(clk_rst_driver);

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function set_cfg(ref clk_rst_config cfg);
    _cfg = cfg;
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db #(virtual clk_rst_if)::get(this, "", "vif", _vif)) begin
      `uvm_fatal("NOVIF", {"FATAL [CLK] Virtual interface must be set for: ",
      get_full_name(), ".vif"});
    end

    if (!_cfg.clock_period > 0) begin
      `uvm_fatal(get_full_name(), $sformatf("Clock period must be higher than: (%0f)", _cfg.clock_period))
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  task pre_reset_phase(uvm_phase phase);
    _vif.clk   <= '0;
    _vif.rst   <= '0;
    _vif.rst_n <= '1;
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);

    fork
      drive_clock();
      get_reset_item();
    join
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task drive_clock();

    #(_cfg.clock_period);

    forever begin
      _vif.clk <= ~_vif.clk;
      #(_cfg.clock_period/2);
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task get_reset_item();

    _vif.rst   <= '0;
    _vif.rst_n <= '1;

    forever begin
      seq_item_port.get_next_item(req);
      drive_reset();
      seq_item_port.item_done();
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task drive_reset();

    if ($realtime == 0) begin
      // Waiting half a period for the monitor to start.
      #(_cfg.clock_period/2);
    end

    // Different delay before driving the reset for either:
    //  - RESET_ASYNCHRONOUSLY_E
    //  - RESET_AT_CLK_RISING_EDGE_E
    //  - RESET_AT_CLK_FALLING_EDGE_E
    if (req.reset_edge != RESET_ASYNCHRONOUSLY_E) begin

      if (req.reset_edge == RESET_AT_CLK_RISING_EDGE_E) begin
        @(posedge _vif.clk);
      end
      else begin
        @(negedge _vif.clk);
      end

    end
    else begin
      #(3*_cfg.clock_period/4);
    end

    _vif.rst   <=  req.reset_value;
    _vif.rst_n <= ~req.reset_value;
  endtask
endclass
