////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2021 Fredrik Åkerlund
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

class vip_axi4_sequencer #(
  vip_axi4_cfg_t CFG_P = '{default: '0}
  ) extends uvm_sequencer #(vip_axi4_item #(CFG_P));

  `uvm_component_param_utils(vip_axi4_sequencer #(CFG_P));

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void handle_reset(uvm_phase phase);

    uvm_objection objection = phase.get_objection();
    int objections_count;

    stop_sequences();

    objections_count = objection.get_objection_count(this);
    if (objections_count > 0) begin
      objection.drop_objection(this, $sformatf("Dropping %0d objections at reset", objections_count), objections_count);
    end

    start_phase_sequence(phase);

  endfunction

endclass
