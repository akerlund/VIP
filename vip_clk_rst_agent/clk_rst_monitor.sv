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

class clk_rst_monitor extends uvm_monitor;

  protected virtual clk_rst_if _vif;
  protected realtime           _measured_reset_duration;
  protected clk_rst_config     _cfg;
  protected uvm_event          _rst_event;

  `uvm_component_utils(clk_rst_monitor);

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
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual clk_rst_if)::get(this, "", "vif", _vif)) begin
      `uvm_fatal("NOVIF", {"FATAL [CLK] Virtual interface must be set for: ",
      get_full_name(), ".vif"});
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (_cfg.rst_event_enabled == '1) begin
      _rst_event = new("EV_RST");
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);

    if ($realtime == 0) begin
      // Waiting half a period because apparently the reset is "asserted" at
      // delta-time 0 (a kind of UVM DC component?) which will trigger the
      // Monitor to react falsely.
      #(_cfg.clock_period/2);
    end

    fork
      monitor_reset_assertions();
      monitor_reset_deassertions();
    join
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task monitor_reset_assertions();

    forever begin
      @(posedge _vif.rst);

      `uvm_info(get_name(), "INFO [CLK] Reset asserted", UVM_LOW)
      _measured_reset_duration = $realtime;

      if (_cfg.rst_event_enabled == '1) begin
        _rst_event.trigger();
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task monitor_reset_deassertions();

    forever begin

      @(negedge _vif.rst);

      _measured_reset_duration = $realtime - _measured_reset_duration;
      if (_measured_reset_duration < _cfg.clock_period) begin
        `uvm_info(get_name(), $sformatf("INFO [CLK] Reset de-asserted: period is lower than (1) clock period: (%f) < (%f)",
        _measured_reset_duration, _cfg.clock_period), UVM_LOW)
      end
      else begin
        `uvm_info(get_name(), $sformatf("INFO [CLK] Reset de-asserted: was active for (%.2f) clock periods",
        (_measured_reset_duration / _cfg.clock_period)), UVM_LOW)
      end
    end
  endtask

endclass
