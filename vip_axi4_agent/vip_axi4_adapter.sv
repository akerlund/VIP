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

class vip_axi4_adapter #(
  vip_axi4_cfg_t CFG_P = '{
    VIP_AXI4_ID_WIDTH_P   : 1,
    VIP_AXI4_ADDR_WIDTH_P : 1,
    VIP_AXI4_DATA_WIDTH_P : 8,
    VIP_AXI4_STRB_WIDTH_P : 1,
    VIP_AXI4_USER_WIDTH_P : 0}
  ) extends uvm_reg_adapter;

  `uvm_object_param_utils(vip_axi4_adapter #(CFG_P))

  function new (string name = "vip_axi4_adapter");
    super.new(name);
  endfunction

  function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);

    vip_axi4_item #(CFG_P) reg_item;

    if (rw.kind == UVM_WRITE) begin

      reg_item                 = vip_axi4_item #(CFG_P)::type_id::create("reg_item");
      reg_item.cfg             = new();
      reg_item.cfg.axi4_access = VIP_AXI4_WR_REQUEST_E;

      reg_item.awid   = 0;
      reg_item.awaddr = rw.addr;
      reg_item.awlen  = 0;

      reg_item.wdata    = new[1];
      reg_item.wstrb    = new[1];
      reg_item.wuser    = new[1];
      reg_item.wdata[0] = rw.data;
      reg_item.wstrb[0] = '1;
      reg_item.wuser[0] = '0;

      return reg_item;

    end
    else begin

      reg_item = vip_axi4_item #(CFG_P)::type_id::create("reg_item");

      reg_item                     = vip_axi4_item #(CFG_P)::type_id::create("reg_item");
      reg_item.cfg                 = new();
      reg_item.cfg.axi4_access     = VIP_AXI4_RD_REQUEST_E;
      reg_item.cfg.get_rd_response = TRUE;

      reg_item.arid   = 0;
      reg_item.araddr = rw.addr;
      reg_item.arlen  = 0;

      reg_item.rdata  = new[1];
      reg_item.ruser  = new[1];

      return reg_item;

    end

  endfunction


  function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);

    vip_axi4_item #(CFG_P) reg_item;

    assert ($cast(reg_item, bus_item)) else
      `uvm_fatal(get_name(), "Cannot cast to vip_axi4_item")

    rw.addr   = reg_item.araddr;
    rw.kind   = UVM_READ;
    rw.data   = reg_item.rdata[0];
    rw.status = UVM_IS_OK;

  endfunction

endclass
