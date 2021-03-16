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

import uvm_pkg::*;
import axi4_tb_pkg::*;
import axi4_tc_pkg::*;

module axi4_tb_top;

  // IF
  clk_rst_if                    clk_rst_vif();
  vip_axi4_if #(VIP_AXI4_CFG_C) wr_vif (clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if #(VIP_AXI4_CFG_C) rd_vif0(clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if #(VIP_AXI4_CFG_C) mem_vif(clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if #(VIP_REG_CFG_C)  reg_vif(clk_rst_vif.clk, clk_rst_vif.rst_n);
  axi_cfg_if  #(
    .AXI4_ID_WIDTH_P   ( AXI4_ID_WIDTH_C   ),
    .AXI4_ADDR_WIDTH_P ( AXI4_ADDR_WIDTH_C ),
    .AXI4_DATA_WIDTH_P ( AXI4_DATA_WIDTH_C ),
    .AXI4_STRB_WIDTH_P ( AXI4_STRB_WIDTH_C )
  ) cfg_vif (clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if #(VIP_AXI4_CFG_C) rd_vif1(clk_rst_vif.clk, clk_rst_vif.rst_n);
  vip_axi4_if #(VIP_AXI4_CFG_C) rd_vif2(clk_rst_vif.clk, clk_rst_vif.rst_n);

  initial begin
    wr_vif.sink_read_channel();
    rd_vif0.sink_write_channel();
    rd_vif1.sink_write_channel();
    rd_vif2.sink_write_channel();
    rd_vif1.sink_read_address_channel();
    rd_vif2.sink_read_address_channel();
  end

  //----------------------------------------------------------------------------
  // Write -> Memory -> Read
  //----------------------------------------------------------------------------

  // Write Address Channel
  assign mem_vif.awid      = wr_vif.awid;
  assign mem_vif.awaddr    = wr_vif.awaddr;
  assign mem_vif.awlen     = wr_vif.awlen;
  assign mem_vif.awsize    = wr_vif.awsize;
  assign mem_vif.awburst   = wr_vif.awburst;
  assign mem_vif.awlock    = wr_vif.awlock;
  assign mem_vif.awcache   = wr_vif.awcache;
  assign mem_vif.awprot    = wr_vif.awprot;
  assign mem_vif.awqos     = wr_vif.awqos;
  assign mem_vif.awregion  = wr_vif.awregion;
  assign mem_vif.awuser    = wr_vif.awuser;
  assign mem_vif.awvalid   = wr_vif.awvalid;
  assign wr_vif.awready    = mem_vif.awready;

  // Write Data Channel
  assign mem_vif.wdata    = wr_vif.wdata;
  assign mem_vif.wstrb    = wr_vif.wstrb;
  assign mem_vif.wlast    = wr_vif.wlast;
  assign mem_vif.wuser    = wr_vif.wuser;
  assign mem_vif.wvalid   = wr_vif.wvalid;
  assign wr_vif.wready    = mem_vif.wready;

  // Write Response Channel
  assign wr_vif.bid       = mem_vif.bid;
  assign wr_vif.bresp     = mem_vif.bresp;
  assign wr_vif.buser     = mem_vif.buser;
  assign wr_vif.bvalid    = mem_vif.bvalid;
  assign mem_vif.bready   = wr_vif.bready;

  // Read Address Channel
  assign mem_vif.arid     = rd_vif0.arid;
  assign mem_vif.araddr   = rd_vif0.araddr;
  assign mem_vif.arlen    = rd_vif0.arlen;
  assign mem_vif.arsize   = rd_vif0.arsize;
  assign mem_vif.arburst  = rd_vif0.arburst;
  assign mem_vif.arlock   = rd_vif0.arlock;
  assign mem_vif.arcache  = rd_vif0.arcache;
  assign mem_vif.arprot   = rd_vif0.arprot;
  assign mem_vif.arqos    = rd_vif0.arqos;
  assign mem_vif.arregion = rd_vif0.arregion;
  assign mem_vif.aruser   = rd_vif0.aruser;
  assign mem_vif.arvalid  = rd_vif0.arvalid;
  assign rd_vif0.arready  = mem_vif.arready;

  // Read Data Channel
  assign rd_vif0.rid      = mem_vif.rid;
  assign rd_vif0.rdata    = mem_vif.rdata;
  assign rd_vif0.rresp    = mem_vif.rresp;
  assign rd_vif0.rlast    = mem_vif.rlast;
  assign rd_vif0.ruser    = mem_vif.ruser;
  assign rd_vif0.rvalid   = mem_vif.rvalid;
  assign mem_vif.rready   = rd_vif0.rready;

  //----------------------------------------------------------------------------
  // Register
  //----------------------------------------------------------------------------

  // Write Address Channel
  assign cfg_vif.awaddr   = reg_vif.awaddr;
  assign cfg_vif.awvalid  = reg_vif.awvalid;
  assign reg_vif.awready  = cfg_vif.awready;

  // Write Data Channel
  assign cfg_vif.wdata    = reg_vif.wdata;
  assign cfg_vif.wstrb    = reg_vif.wstrb;
  assign cfg_vif.wlast    = reg_vif.wlast;
  assign cfg_vif.wvalid   = reg_vif.wvalid;
  assign reg_vif.wready   = cfg_vif.wready;

  // Write Response Channel
  assign reg_vif.bresp    = cfg_vif.bresp;
  assign reg_vif.bvalid   = cfg_vif.bvalid;
  assign cfg_vif.bready   = reg_vif.bready;

  // Read Address Channel
  assign cfg_vif.araddr   = reg_vif.araddr;
  assign cfg_vif.arlen    = reg_vif.arlen;
  assign cfg_vif.arvalid  = reg_vif.arvalid;
  assign reg_vif.arready  = cfg_vif.arready;

  // Read Data Channel
  assign reg_vif.rdata    = cfg_vif.rdata;
  assign reg_vif.rresp    = cfg_vif.rresp;
  assign reg_vif.rlast    = cfg_vif.rlast;
  assign reg_vif.rvalid   = cfg_vif.rvalid;
  assign cfg_vif.rready   = reg_vif.rready;

  //----------------------------------------------------------------------------
  // Read (SLV) -> Read (Master)
  //----------------------------------------------------------------------------

  // Read Data Channel
  assign rd_vif2.rid      = rd_vif1.rid;
  assign rd_vif2.rdata    = rd_vif1.rdata;
  assign rd_vif2.rresp    = rd_vif1.rresp;
  assign rd_vif2.rlast    = rd_vif1.rlast;
  assign rd_vif2.ruser    = rd_vif1.ruser;
  assign rd_vif2.rvalid   = rd_vif1.rvalid;
  assign rd_vif1.rready   = rd_vif2.rready;

  initial begin
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                    "uvm_test_top.tb_env*",                "vif", clk_rst_vif);
    uvm_config_db #(virtual clk_rst_if)::set(uvm_root::get(),                    "uvm_test_top.tb_env.clk_rst_agent0*", "vif", clk_rst_vif);
    uvm_config_db #(virtual vip_axi4_if #(VIP_AXI4_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.wr_agent0*",      "vif", wr_vif);
    uvm_config_db #(virtual vip_axi4_if #(VIP_AXI4_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.rd_agent0*",      "vif", rd_vif0);
    uvm_config_db #(virtual vip_axi4_if #(VIP_AXI4_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.mem_agent0*",     "vif", mem_vif);
    uvm_config_db #(virtual vip_axi4_if  #(VIP_REG_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.reg_agent0*",     "vif", reg_vif);
    uvm_config_db #(virtual vip_axi4_if #(VIP_AXI4_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.rd_agent1*",      "vif", rd_vif1);
    uvm_config_db #(virtual vip_axi4_if #(VIP_AXI4_CFG_C))::set(uvm_root::get(), "uvm_test_top.tb_env.rd_agent2*",      "vif", rd_vif2);
    run_test();
    $stop();
  end

  logic [63 : 0] sr_status;

  axi4_axi_slave #(
    .AXI_ADDR_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_ADDR_WIDTH_P ),
    .AXI_DATA_WIDTH_P ( VIP_REG_CFG_C.VIP_AXI4_DATA_WIDTH_P ),
    .AXI_ID_P         ( 0                                   )
  ) axi4_axi_slave_i0 (
    .cif              ( cfg_vif                             ),
    .cmd_command      (                                     ), // output
    .cr_configuration ( sr_status                           ), // output
    .sr_status        ( sr_status                           )  // input
  );

  initial begin
    $timeformat(-9, 0, "", 11);  // units, precision, suffix, min field width
    if ($test$plusargs("RECORD")) begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_FULL);
    end else begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_NONE);
    end
  end

endmodule
