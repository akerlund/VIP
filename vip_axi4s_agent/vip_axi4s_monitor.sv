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

class vip_axi4s_monitor #(
  vip_axi4s_cfg_t CFG_P = '{default: '0}
  ) extends uvm_monitor;

  // Analysis ports
  uvm_analysis_port #(vip_axi4s_item #(CFG_P)) tdata_port;

  // Class variables
  protected virtual vip_axi4s_if #(CFG_P) vif;
  protected int    id;
  vip_axi4s_config cfg;

  // Ingress data is saved in dynamic list
  protected logic [CFG_P.VIP_AXI4S_TDATA_WIDTH_P : 0] _tdata_beats [$];
  protected logic [CFG_P.VIP_AXI4S_TSTRB_WIDTH_P : 0] _tstrb_beats [$];
  protected logic [CFG_P.VIP_AXI4S_TKEEP_WIDTH_P : 0] _tkeep_beats [$];
  protected logic [CFG_P.VIP_AXI4S_TUSER_WIDTH_P : 0] _tuser_beats [$];


  `uvm_component_param_utils_begin(vip_axi4s_monitor #(CFG_P))
    `uvm_field_int(id, UVM_DEFAULT)
  `uvm_component_utils_end

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    tdata_port = new("tdata_port", this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual vip_axi4s_if #(CFG_P))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.rst_n);
      fork
        monitor_start();
      join
      @(negedge vif.rst_n);
      disable fork;
    end
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task monitor_start();
    fork
      collect_transfers();
    join
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void handle_reset();
    _tdata_beats.delete();
    _tstrb_beats.delete();
    _tkeep_beats.delete();
    _tuser_beats.delete();
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  protected task collect_transfers();

    vip_axi4s_item #(CFG_P) axi4s_item;

    forever begin

      @(posedge vif.clk);

      if (vif.tvalid === '1 && vif.tready === '1) begin
        _tdata_beats.push_back(vif.tdata);
        _tstrb_beats.push_back(vif.tstrb);
        _tkeep_beats.push_back(vif.tkeep);
        _tuser_beats.push_back(vif.tuser);
      end

      if (vif.tvalid === '1 && vif.tready === '1 && vif.tlast === '1) begin

        axi4s_item       = new();
        axi4s_item.tid   = vif.tid;
        axi4s_item.tdest = vif.tdest;
        axi4s_item.tdata = new[_tdata_beats.size()];
        axi4s_item.tstrb = new[_tstrb_beats.size()];
        axi4s_item.tkeep = new[_tkeep_beats.size()];
        axi4s_item.tuser = new[_tuser_beats.size()];
        foreach (_tdata_beats[i]) begin axi4s_item.tdata[i] = _tdata_beats[i]; end
        foreach (_tstrb_beats[i]) begin axi4s_item.tstrb[i] = _tstrb_beats[i]; end
        foreach (_tkeep_beats[i]) begin axi4s_item.tkeep[i] = _tkeep_beats[i]; end
        foreach (_tuser_beats[i]) begin axi4s_item.tuser[i] = _tuser_beats[i]; end
        _tdata_beats.delete();
        _tstrb_beats.delete();
        _tkeep_beats.delete();
        _tuser_beats.delete();

        `uvm_info(get_type_name(), $sformatf("Collected transfer:\n%s", axi4s_item.sprint()), UVM_HIGH)
        tdata_port.write(axi4s_item);
      end
    end
  endtask
endclass
