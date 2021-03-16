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

`uvm_analysis_imp_decl(_mst0_awaddr_port)
`uvm_analysis_imp_decl(_mst0_bresp_port)
`uvm_analysis_imp_decl(_mst1_araddr_port)
`uvm_analysis_imp_decl(_mst1_rdata_port)
`uvm_analysis_imp_decl(_slv2_bresp_port)
`uvm_analysis_imp_decl(_slv2_rdata_port)
`uvm_analysis_imp_decl(_slv3_araddr_port)
`uvm_analysis_imp_decl(_slv3_rdata_port)
`uvm_analysis_imp_decl(_mst4_araddr_port)
`uvm_analysis_imp_decl(_mst4_rdata_port)

class axi4_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi4_scoreboard)

  typedef logic [VIP_AXI4_CFG_C.VIP_AXI4_ADDR_WIDTH_P-1 : 0] mem_addr_type_t;

  // Master (Write) Agent
  uvm_analysis_imp_mst0_awaddr_port #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst0_awaddr_port;
  uvm_analysis_imp_mst0_bresp_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst0_bresp_port;

  // Master (Read) Agent
  uvm_analysis_imp_mst1_araddr_port #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst1_araddr_port;
  uvm_analysis_imp_mst1_rdata_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst1_rdata_port;

  // Slave (Memory) Agent
  uvm_analysis_imp_slv2_bresp_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) slv2_bresp_port;
  uvm_analysis_imp_slv2_rdata_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) slv2_rdata_port;

  // Slave (Read) Agent
  uvm_analysis_imp_slv3_araddr_port #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) slv3_araddr_port;
  uvm_analysis_imp_slv3_rdata_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) slv3_rdata_port;

  // Master (Read) Agent
  uvm_analysis_imp_mst4_araddr_port #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst4_araddr_port;
  uvm_analysis_imp_mst4_rdata_port  #(vip_axi4_item #(VIP_AXI4_CFG_C), axi4_scoreboard) mst4_rdata_port;

  // Storage for comparison
  vip_axi4_item #(VIP_AXI4_CFG_C) mst0_awaddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) mst0_bresp_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) mst1_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) mst1_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) slv2_bresp_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) slv2_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) slv3_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) slv3_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) mst4_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) mst4_rdata_items  [$];

  // Debug storage
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst0_awaddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst0_bresp_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst1_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst1_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_slv2_bresp_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_slv2_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_slv3_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_slv3_rdata_items  [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst4_araddr_items [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) all_mst4_rdata_items  [$];

  // For raising objections
  uvm_phase current_phase;

  // Transaction counters
  int number_of_mst0_awaddr_items = 0;
  int number_of_mst0_bresp_items  = 0;
  int number_of_mst1_araddr_items = 0;
  int number_of_mst1_rdata_items  = 0;
  int number_of_slv2_rdata_items  = 0;
  int number_of_slv2_bresp_items  = 0;
  int number_of_slv3_araddr_items = 0;
  int number_of_slv3_rdata_items  = 0;
  int number_of_slv4_araddr_items = 0;
  int number_of_slv4_rdata_items  = 0;

  // Test counters
  int number_of_compared    = 0;
  int number_of_compared_wr = 0;
  int number_of_compared_rd = 0;
  int number_of_passed      = 0;
  int number_of_failed      = 0;

  vip_axi4_config cfg;
  protected logic [VIP_AXI4_CFG_C.VIP_AXI4_DATA_WIDTH_P-1 : 0] sb_memory [mem_addr_type_t];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(vip_axi4_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Scoreboard has no config")
    end
    mst0_awaddr_port = new("mst0_awaddr_port", this);
    mst0_bresp_port  = new("mst0_bresp_port",  this);
    mst1_araddr_port = new("mst1_araddr_port", this);
    mst1_rdata_port  = new("mst1_rdata_port",  this);
    slv2_bresp_port  = new("slv2_bresp_port",  this);
    slv2_rdata_port  = new("slv2_rdata_port",  this);
    slv3_araddr_port = new("slv3_araddr_port", this);
    slv3_rdata_port  = new("slv3_rdata_port",  this);
    mst4_araddr_port = new("mst4_araddr_port", this);
    mst4_rdata_port  = new("mst4_rdata_port",  this);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void start_of_simulation_phase(uvm_phase phase);
    current_phase = phase;
    super.start_of_simulation_phase(phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    current_phase = phase;
    super.connect_phase(current_phase);
  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    current_phase = phase;
    super.run_phase(current_phase);
  endtask

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  function void check_phase(uvm_phase phase);

    current_phase = phase;
    super.check_phase(current_phase);

    if (number_of_failed != 0) begin
      `uvm_error(get_name(), $sformatf("Test failed! (%0d) mismatches", number_of_failed))
    end
    else begin
      `uvm_info(get_name(), $sformatf("Test passed (%0d/%0d) finished transfers", number_of_passed, number_of_compared), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Compared (%0d) writes", number_of_compared_wr), UVM_LOW)
      `uvm_info(get_name(), $sformatf("Compared (%0d) reads",  number_of_compared_rd), UVM_LOW)
    end

  endfunction

  // ---------------------------------------------------------------------------
  //
  // ---------------------------------------------------------------------------
  virtual function void handle_reset();
    mst0_awaddr_items.delete();
    mst0_bresp_items.delete();
    mst1_araddr_items.delete();
    mst1_rdata_items.delete();
    slv2_bresp_items.delete();
    slv2_rdata_items.delete();
    slv3_araddr_items.delete();
    slv3_rdata_items.delete();
    mst4_araddr_items.delete();
    mst4_rdata_items.delete();
  endfunction

  //----------------------------------------------------------------------------
  // Master (Write) Agent0 - Address Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst0_awaddr_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_mst0_awaddr_items++;
    all_mst0_awaddr_items.push_back(trans);
    mst0_awaddr_items.push_back(trans);
    current_phase.raise_objection(this);

  endfunction

  //----------------------------------------------------------------------------
  // Master (Write) Agent0 - Data Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst0_bresp_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_mst0_bresp_items++;
    all_mst0_bresp_items.push_back(trans);
    mst0_bresp_items.push_back(trans);

    if (slv2_bresp_items.size() != 0) begin
      compare_write();
      current_phase.drop_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  // Master (Read) Agent1 - Address Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst1_araddr_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_mst1_araddr_items++;
    all_mst1_araddr_items.push_back(trans);
    mst1_araddr_items.push_back(trans);
    current_phase.raise_objection(this);

  endfunction

  //----------------------------------------------------------------------------
  // Master (Read) Agent1 - Data Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst1_rdata_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_mst1_rdata_items++;
    all_mst1_rdata_items.push_back(trans);
    mst1_rdata_items.push_back(trans);

    // Because there is no DUT which delays the data, only in this example
    if (slv2_rdata_items.size() != 0) begin
      compare_read0();
      current_phase.drop_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  // Slave (Memory) Agent2 - Write Channel
  //----------------------------------------------------------------------------
  virtual function void write_slv2_bresp_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_slv2_bresp_items++;
    all_slv2_bresp_items.push_back(trans);
    slv2_bresp_items.push_back(trans);

    mem_write(trans);

    if (mst0_bresp_items.size() != 0) begin
      compare_write();
      current_phase.drop_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  // Slave (Memory) Agent2 - Read Channel
  //----------------------------------------------------------------------------
  virtual function void write_slv2_rdata_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_slv2_rdata_items++;
    all_slv2_rdata_items.push_back(trans);
    slv2_rdata_items.push_back(trans);

    // Same as above
    if (mst1_rdata_items.size() != 0) begin
      compare_read0();
      current_phase.drop_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  // Slave (Read) Agent3 - Address Channel
  //----------------------------------------------------------------------------
  virtual function void write_slv3_araddr_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

  endfunction

  //----------------------------------------------------------------------------
  // Slave (Read) Agent3 - Data Channel
  //----------------------------------------------------------------------------
  virtual function void write_slv3_rdata_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_slv3_rdata_items++;
    all_slv3_rdata_items.push_back(trans);
    slv3_rdata_items.push_back(trans);

    // Because there is no DUT which delays the data, only in this example
    if (mst4_rdata_items.size() != 0) begin
      compare_read1();
      current_phase.drop_objection(this);
    end else begin
      current_phase.raise_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  // Master (Read) Agent4 - Address Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst4_araddr_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

  endfunction

  //----------------------------------------------------------------------------
  // Master (Read) Agent4 - Data Channel
  //----------------------------------------------------------------------------
  virtual function void write_mst4_rdata_port(vip_axi4_item #(VIP_AXI4_CFG_C) trans);

    number_of_slv4_rdata_items++;
    all_mst4_rdata_items.push_back(trans);
    mst4_rdata_items.push_back(trans);

    // Because there is no DUT which delays the data, only in this example
    if (slv3_rdata_items.size() != 0) begin
      compare_read1();
      current_phase.drop_objection(this);
    end else begin
      current_phase.raise_objection(this);
    end

  endfunction

  //----------------------------------------------------------------------------
  //
  //----------------------------------------------------------------------------
  virtual function void compare_write();

    vip_axi4_item #(VIP_AXI4_CFG_C) mst_bresp_item;
    vip_axi4_item #(VIP_AXI4_CFG_C) slv_bresp_item;

    mst_bresp_item = mst0_bresp_items.pop_front();
    slv_bresp_item = slv2_bresp_items.pop_front();

    if (mst_bresp_item == null) begin
      `uvm_fatal(get_name(), $sformatf("Fetched mst0_bresp_items NULL object"))
    end

    if (slv_bresp_item == null) begin
      `uvm_fatal(get_name(), $sformatf("Fetched slv2_bresp_items NULL object"))
    end

    number_of_compared++;
    number_of_compared_wr++;

    if (!mst_bresp_item.compare(slv_bresp_item)) begin
      `uvm_error(get_name(), $sformatf("Packet number (%0d) mismatches", number_of_compared))
      number_of_failed++;
    end
    else begin
      number_of_passed++;
    end

  endfunction

  //----------------------------------------------------------------------------
  //
  //----------------------------------------------------------------------------
  virtual function void compare_read0();

    vip_axi4_item #(VIP_AXI4_CFG_C) mst_rdata_item;
    vip_axi4_item #(VIP_AXI4_CFG_C) slv_rdata_item;

    bool_t compare_ok = TRUE;
    int    memory_i0;
    int    memory_i1;
    int    counter;

    logic [VIP_AXI4_CFG_C.VIP_AXI4_DATA_WIDTH_P-1 : 0] rdata;


    mst_rdata_item = mst1_rdata_items.pop_front(); // rd_agent0
    slv_rdata_item = slv2_rdata_items.pop_front(); // mem_agent0
    if (mst_rdata_item == null) begin `uvm_fatal(get_name(), $sformatf("Fetched mst1_rdata_items NULL object")) end
    if (slv_rdata_item == null) begin `uvm_fatal(get_name(), $sformatf("Fetched slv2_rdata_items NULL object")) end

    if (!mst_rdata_item.compare(slv_rdata_item)) begin
      compare_ok = FALSE;
      `uvm_error(get_name(), $sformatf("compare_read0: mem_agent0 and rd_agent0 differ"))
    end

    memory_i0 = unsigned'(mst_rdata_item.araddr) / VIP_AXI4_CFG_C.VIP_AXI4_STRB_WIDTH_P;
    memory_i1 = unsigned'(mst_rdata_item.arlen) + 1;
    counter   = 0;

    for (int i = memory_i0; i < memory_i1; i++) begin

      if (!sb_memory.exists(i)) begin
        rdata = '0;
      end else begin
        rdata = sb_memory[i];
      end

      if (rdata !== mst_rdata_item.rdata[counter]) begin
        `uvm_error(get_name(), $sformatf("SB = (%0d), rdata = (%0d)", rdata, counter))
      end
      counter++;
    end

    number_of_compared++;
    number_of_compared_rd++;
    if (!compare_ok) begin
      `uvm_error(get_name(), $sformatf("compare_read0: Packet number (%0d) mismatches", number_of_compared))
      compare_ok = FALSE;
      number_of_failed++;
    end
    else begin
      number_of_passed++;
    end

  endfunction

  //----------------------------------------------------------------------------
  //
  //----------------------------------------------------------------------------
  virtual function void compare_read1();

    vip_axi4_item #(VIP_AXI4_CFG_C) mst_rdata_item;
    vip_axi4_item #(VIP_AXI4_CFG_C) slv_rdata_item;
    bool_t compare_ok = TRUE;
    mst_rdata_item = mst4_rdata_items.pop_front(); // rd_agent2
    slv_rdata_item = slv3_rdata_items.pop_front(); // rd_agent1
    if (mst_rdata_item == null) begin `uvm_fatal(get_name(), $sformatf("Fetched mst4_rdata_items NULL object")) end
    if (slv_rdata_item == null) begin `uvm_fatal(get_name(), $sformatf("Fetched slv3_rdata_items NULL object")) end
    if (!mst_rdata_item.compare(slv_rdata_item)) begin
      compare_ok = FALSE;
    end
    number_of_compared++;
    number_of_compared_rd++;
    if (!compare_ok) begin
      `uvm_error(get_name(), $sformatf("compare_read1: Packet number (%0d) mismatches", number_of_compared))
      compare_ok = FALSE;
      number_of_failed++;
    end
    else begin
      number_of_passed++;
    end

  endfunction

  //----------------------------------------------------------------------------
  //
  //----------------------------------------------------------------------------
  function void mem_write(vip_axi4_item #(VIP_AXI4_CFG_C) item);

    // Memory-write loop variables
    int memory_i0 = 0;
    int memory_i1 = 0;
    int counter   = 0;

    // We build up the final write in this
    logic [VIP_AXI4_CFG_C.VIP_AXI4_DATA_WIDTH_P-1 : 0] write_row;

    memory_i0 = unsigned'(item.awaddr) / VIP_AXI4_CFG_C.VIP_AXI4_STRB_WIDTH_P;
    memory_i1 = memory_i0 + unsigned'(item.awlen) + 1;
    counter   = 0;

    for (int i = memory_i0; i < memory_i1; i++) begin

      if (item.wstrb[counter] == '1) begin

        if (^item.wdata[counter] === 1'bX) begin
          `uvm_warning(get_name(), $sformatf("MEM: Writing X to index (%0d)", memory_i0))
        end
        sb_memory[i] = item.wdata[counter];

      end else begin

        write_row = '0;

        for (int j = 0; j < VIP_AXI4_CFG_C.VIP_AXI4_STRB_WIDTH_P; j++) begin

          if (item.wstrb[counter][j]) begin
            if (^item.wdata[counter][8*j +: 8] === 1'bX) begin
              `uvm_warning(get_name(), $sformatf("MEM: Writing X to index (%0d)", i))
            end
            write_row[8*j +: 8] = item.wdata[counter][8*j +: 8];
          end
          else begin
            write_row[8*j +: 8] = sb_memory[i][8*j +: 8];
          end

        end

        sb_memory[i] = write_row;
      end

      counter++;
    end
  endfunction

endclass
