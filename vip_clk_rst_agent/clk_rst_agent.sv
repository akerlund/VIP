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

class clk_rst_agent extends uvm_agent;

  protected int               _id = 0;
  protected string            _id_str;
  protected clk_rst_config    _cfg;
            clk_rst_monitor   monitor;
            clk_rst_driver    driver;
            clk_rst_sequencer sequencer;

  `uvm_component_utils_begin(clk_rst_agent);
  `uvm_field_int(_id,     UVM_DEFAULT)
  `uvm_field_object(_cfg, UVM_DEFAULT)
  `uvm_component_utils_end;

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db #(clk_rst_config)::get(this, "", "cfg", _cfg)) begin
      `uvm_info(get_type_name(), "INFO [CLK] Creating a default config", UVM_LOW)
      _cfg = clk_rst_config::type_id::create("clk_default_config", this);
    end

    _id_str.itoa(_id);
    monitor     = clk_rst_monitor::type_id::create({"clk_rst_monitor",     _id_str}, this);
    driver      = clk_rst_driver::type_id::create({"clk_rst_driver",       _id_str}, this);
    sequencer   = clk_rst_sequencer::type_id::create({"clk_rst_sequencer", _id_str}, this);
    monitor.set_cfg(_cfg);
    driver.set_cfg(_cfg);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
