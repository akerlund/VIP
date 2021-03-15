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

class tc_axi4_demonstration extends axi4_base_test;

  `uvm_component_utils(tc_axi4_demonstration)

  localparam logic [7 : 0] MAX_LEN_C = (VIP_AXI4_4K_ADDRESS_BOUNDARY_C / VIP_AXI4_CFG_C.VIP_AXI4_STRB_WIDTH_P)-1;

  vip_axi4_item #(VIP_AXI4_CFG_C) rd_responses [$];
  vip_axi4_item #(VIP_AXI4_CFG_C) rd_response;

  logic [VIP_AXI4_CFG_C.VIP_AXI4_DATA_WIDTH_P-1 : 0] custom_data [$];
  logic                                     [63 : 0] cr_configuration;

  function new(string name = "tc_axi4_demonstration", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_mem_cfg0.mem_addr_width = AXI4_ADDR_WIDTH_C;
  endfunction


  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    phase.raise_objection(this);

    // -------------------------------------------------------------------------
    // Normal write
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[WRITE] Normal: Address (0x00), Counter 0, 1, 2, ..., 255"), UVM_LOW)
    vip_axi4_write_seq0.set_addr(0);
    vip_axi4_write_seq0.set_len(15);
    vip_axi4_write_seq0.set_nr_of_requests(16);
    vip_axi4_write_seq0.set_data_type(VIP_AXI4_DATA_COUNTER_E);
    vip_axi4_write_seq0.set_log_denominator(4);
    vip_axi4_write_seq0.start(v_sqr.write_sequencer);

    clk_delay(200);

    // -------------------------------------------------------------------------
    // Normal read
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[READ] Normal: Address (0x00)"), UVM_LOW)
    vip_axi4_read_seq0.set_addr(0);
    vip_axi4_read_seq0.set_len(15);
    vip_axi4_read_seq0.set_nr_of_requests(16);
    vip_axi4_read_seq0.set_log_denominator(2);
    vip_axi4_read_seq0.start(v_sqr.read_sequencer);

    clk_delay(200);

    // -------------------------------------------------------------------------
    // Combined write, with all requests combined into one, i.e., passed to the
    // driver as one single request item
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[WRITE] Combining requests: Address (0x100), Counter 256, 257, 258, ..., 511"), UVM_LOW)
    vip_axi4_write_seq0.set_counter(256); // The counter is already 256 though
    vip_axi4_write_seq0.set_addr(256*AXI4_STRB_WIDTH_C);
    vip_axi4_write_seq0.set_len(15);
    vip_axi4_write_seq0.set_nr_of_requests(16);
    vip_axi4_write_seq0.set_data_type(VIP_AXI4_DATA_COUNTER_E);
    vip_axi4_write_seq0.set_combine_requests(TRUE);
    vip_axi4_write_seq0.set_log_denominator(4);
    vip_axi4_write_seq0.start(v_sqr.write_sequencer);

    clk_delay(200);

    // -------------------------------------------------------------------------
    // Read with requested responses which we can use in a testcase
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[READ] Requesting read responses: Address (0x100)"), UVM_LOW)
    vip_axi4_read_seq0.set_addr(256*AXI4_STRB_WIDTH_C);
    vip_axi4_read_seq0.set_get_rd_response(TRUE);
    vip_axi4_read_seq0.start(v_sqr.read_sequencer);
    compare_counter_read_responses(256); // We wrote counter values, now compare them

    // -------------------------------------------------------------------------
    // Same again, but combined
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[READ] Requesting (combined) read responses: Address (0x00)"), UVM_LOW)
    vip_axi4_read_seq0.set_addr(0);
    vip_axi4_read_seq0.set_combine_requests(TRUE);
    vip_axi4_read_seq0.start(v_sqr.read_sequencer);
    compare_counter_read_responses(0);

    clk_delay(20);

    // -------------------------------------------------------------------------
    // Writing custom data, we fill the custom data vector with new a counter
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[WRITE] Writing custom data: Address (0x00), Counter 1000, 1001, 1002, ..., 1255"), UVM_LOW)
    for (int i = 0; i <= MAX_LEN_C; i++) begin
      custom_data.push_back(1000 + i);
    end
    vip_axi4_write_seq0.set_addr(0);
    vip_axi4_write_seq0.set_nr_of_requests(1);
    vip_axi4_write_seq0.set_data_type(VIP_AXI4_DATA_CUSTOM_E);
    vip_axi4_write_seq0.set_custom_data(custom_data);
    vip_axi4_write_seq0.set_counter(8000); // This should not affect
    vip_axi4_write_seq0.set_log_denominator(4);
    vip_axi4_write_seq0.set_len(MAX_LEN_C);
    vip_axi4_write_seq0.start(v_sqr.write_sequencer);

    clk_delay(20);

    // -------------------------------------------------------------------------
    // Requesting back the written counter values
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[READ] requesting responses: Address (0x00)"), UVM_LOW)
    vip_axi4_read_seq0.set_addr(0);
    vip_axi4_read_seq0.start(v_sqr.read_sequencer);
    compare_counter_read_responses(1000);

    clk_delay(20);

    // -------------------------------------------------------------------------
    // We have created two Agents in the environment for testing read responses,
    // i.e., sending data only over the Read Data Channel. See the basetest
    // for their configurations (axi4_rd_cfg1, axi4_rd_cfg2).
    // -------------------------------------------------------------------------
    `uvm_info(get_name(), $sformatf("[RESPONSE] Active Slave: Sending read responses"), UVM_LOW)
    vip_axi4_response_seq0.set_len(15);
    vip_axi4_response_seq0.set_data_type(VIP_AXI4_DATA_COUNTER_E);
    vip_axi4_response_seq0.set_nr_of_requests(16);
    vip_axi4_response_seq0.set_log_denominator(4);
    vip_axi4_response_seq0.start(v_sqr.response_sequencer);

    clk_delay(20);

    // -------------------------------------------------------------------------
    // Register and reset testing
    // -------------------------------------------------------------------------
    cr_configuration = $urandom_range(2**31, 0);
    reg_model.axi4.configuration.write(uvm_status, cr_configuration);
    `uvm_info(get_name(), $sformatf("[REGISTER] Wrote (%0d)", cr_configuration), UVM_LOW)
    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("[REGISTER] Read  (%0d)", value), UVM_LOW)

    if (cr_configuration !== value) begin
      `uvm_error(get_name(), $sformatf("Register mismatch: wr(%0d) != rd(%0d)", cr_configuration, value))
    end

    // Reset and read
    `uvm_info(get_name(), $sformatf("[RESET] Starting the reset sequence"), UVM_LOW)
    reset_seq0.start(v_sqr.clk_rst_sequencer0);


    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("[REGISTER] Read  (%0d)", value), UVM_LOW)

    // Write and read
    cr_configuration = $urandom_range(2**31, 0);
    reg_model.axi4.configuration.write(uvm_status, cr_configuration);
    `uvm_info(get_name(), $sformatf("[REGISTER] Wrote (%0d)", cr_configuration), UVM_LOW)
    reg_model.axi4.status.read(uvm_status, value);
    `uvm_info(get_name(), $sformatf("[REGISTER] Read  (%0d)", value), UVM_LOW)

    if (cr_configuration !== value) begin
      `uvm_error(get_name(), $sformatf("Register mismatch: wr(%0d) != rd(%0d)", cr_configuration, value))
    end

    `uvm_info(get_name(), $sformatf("Done!"), UVM_LOW)
    phase.drop_objection(this);

  endtask


  task compare_counter_read_responses(int counter_start);
    bool_t ok = TRUE;
    rd_responses = vip_axi4_read_seq0.get_rd_responses();
    for (int i = 0; i < rd_responses.size(); i++) begin
      rd_response = rd_responses[i];
      if (!ok) begin
        break;
      end
      for (int j = 0; j < rd_response.rdata.size(); j++) begin
        if (i*16+j+counter_start != rd_response.rdata[j]) begin
          `uvm_error(get_name(), $sformatf("Check(%0d): %0d != %0d", i*16+j, i*16+j+counter_start,rd_response.rdata[j]))
          ok = FALSE;
          break;
        end
      end
    end
    if (ok) begin
      `uvm_info(get_name(), $sformatf("[COUNTER CHECK] PASSED"), UVM_LOW)
    end else begin
      `uvm_error(get_name(), $sformatf("[COUNTER CHECK] FAILED"))
    end
  endtask

endclass
