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

`ifndef VIP_AXI4_TYPES_PKG
`define VIP_AXI4_TYPES_PKG

package vip_axi4_types_pkg;

  // ---------------------------------------------------------------------------
  // AXI4 specification defines
  // ---------------------------------------------------------------------------

  localparam int VIP_AXI4_MAX_BURST_LENGTH_C    = 256;
  localparam int VIP_AXI4_4K_ADDRESS_BOUNDARY_C = 4096;

  // Burst codes
  localparam logic [1 : 0] VIP_AXI4_BURST_FIXED_C    = 2'b00;
  localparam logic [1 : 0] VIP_AXI4_BURST_INCR_C     = 2'b01;
  localparam logic [1 : 0] VIP_AXI4_BURST_WRAP_C     = 2'b10;
  localparam logic [1 : 0] VIP_AXI4_BURST_RESERVED_C = 2'b11;

  // Response codes
  localparam logic [1 : 0] VIP_AXI4_RESP_OK_C        = 2'b00;
  localparam logic [1 : 0] VIP_AXI4_RESP_EXOK_C      = 2'b01;
  localparam logic [1 : 0] VIP_AXI4_RESP_SLVERR_C    = 2'b10;
  localparam logic [1 : 0] VIP_AXI4_RESP_DECERR_C    = 2'b11;

  // Burst size encoding
  localparam logic [2 : 0] VIP_AXI4_SIZE_1B_C        = 3'b000;
  localparam logic [2 : 0] VIP_AXI4_SIZE_2B_C        = 3'b001;
  localparam logic [2 : 0] VIP_AXI4_SIZE_4B_C        = 3'b010;
  localparam logic [2 : 0] VIP_AXI4_SIZE_8B_C        = 3'b011;
  localparam logic [2 : 0] VIP_AXI4_SIZE_16B_C       = 3'b100;
  localparam logic [2 : 0] VIP_AXI4_SIZE_32B_C       = 3'b101;
  localparam logic [2 : 0] VIP_AXI4_SIZE_64B_C       = 3'b110;
  localparam logic [2 : 0] VIP_AXI4_SIZE_128B_C      = 3'b111;

  `ifndef BOOL_T
  `define BOOL_T
  typedef enum bit {
    FALSE,
    TRUE
  } bool_t;
  `endif

  typedef enum {
    VIP_AXI4_MASTER_AGENT_E,
    VIP_AXI4_SLAVE_AGENT_E
  } vip_axi4_agent_type_t;

  typedef struct packed {
    int VIP_AXI4_ID_WIDTH_P;
    int VIP_AXI4_ADDR_WIDTH_P;
    int VIP_AXI4_DATA_WIDTH_P;
    int VIP_AXI4_STRB_WIDTH_P;
    int VIP_AXI4_USER_WIDTH_P;
  } vip_axi4_cfg_t;

  typedef enum {
    VIP_AXI4_WR_REQUEST_E,
    VIP_AXI4_RD_REQUEST_E,
    VIP_AXI4_RD_RESPONSE_E
  } vip_axi4_access_t;

  typedef enum {
    VIP_AXI4_DATA_COUNTER_E,
    VIP_AXI4_DATA_RANDOM_E,
    VIP_AXI4_DATA_CUSTOM_E
  } vip_axi4_data_type_t;

  typedef enum {
    VIP_AXI4_STRB_ALL_E,
    VIP_AXI4_STRB_RANDOM_E
  } vip_axi4_strb_t;

  typedef enum {
    VIP_AXI4_X_WR_IGNORE_E,
    VIP_AXI4_X_WR_WARNING_E,
    VIP_AXI4_X_WR_FATAL_E
  } vip_axi4_x_severity_t;

  typedef enum logic [2 : 0] {
    VIP_AXI4_SIZE_1_BYTE_E    = VIP_AXI4_SIZE_1B_C,
    VIP_AXI4_SIZE_2_BYTES_E   = VIP_AXI4_SIZE_2B_C,
    VIP_AXI4_SIZE_4_BYTES_E   = VIP_AXI4_SIZE_4B_C,
    VIP_AXI4_SIZE_8_BYTES_E   = VIP_AXI4_SIZE_8B_C,
    VIP_AXI4_SIZE_16_BYTES_E  = VIP_AXI4_SIZE_16B_C,
    VIP_AXI4_SIZE_32_BYTES_E  = VIP_AXI4_SIZE_32B_C,
    VIP_AXI4_SIZE_64_BYTES_E  = VIP_AXI4_SIZE_64B_C,
    VIP_AXI4_SIZE_128_BYTES_E = VIP_AXI4_SIZE_128B_C
  } vip_axi4_size_t;

  typedef enum logic [1 : 0] {
    VIP_AXI4_BURST_FIXED_E    = VIP_AXI4_BURST_FIXED_C,
    VIP_AXI4_BURST_INCR_E     = VIP_AXI4_BURST_INCR_C,
    VIP_AXI4_BURST_WRAPPING_E = VIP_AXI4_BURST_WRAP_C,
    VIP_AXI4_BURST_RESERVED_E = VIP_AXI4_BURST_RESERVED_C
  } vip_axi4_burst_t;

  typedef enum logic [1 : 0] {
    VIP_AXI4_RESP_OKAY_E         = VIP_AXI4_RESP_OK_C,
    VIP_AXI4_RESP_EXOKAY_E       = VIP_AXI4_RESP_EXOK_C,
    VIP_AXI4_RESP_SLAVE_ERROR_E  = VIP_AXI4_RESP_SLVERR_C,
    VIP_AXI4_RESP_DECODE_ERROR_E = VIP_AXI4_RESP_DECERR_C
  } vip_axi4_resp_t;

  typedef enum {
    VIP_AXI4_MEM_SIZE_1KB_E   = 10,
    VIP_AXI4_MEM_SIZE_2KB_E   = 11,
    VIP_AXI4_MEM_SIZE_4KB_E   = 12,
    VIP_AXI4_MEM_SIZE_8KB_E   = 13,
    VIP_AXI4_MEM_SIZE_16KB_E  = 14,
    VIP_AXI4_MEM_SIZE_32KB_E  = 15,
    VIP_AXI4_MEM_SIZE_64KB_E  = 16,
    VIP_AXI4_MEM_SIZE_128KB_E = 17,
    VIP_AXI4_MEM_SIZE_256KB_E = 18,
    VIP_AXI4_MEM_SIZE_512KB_E = 19,
    VIP_AXI4_MEM_SIZE_1MB_E   = 20,
    VIP_AXI4_MEM_SIZE_2MB_E   = 21,
    VIP_AXI4_MEM_SIZE_4MB_E   = 22,
    VIP_AXI4_MEM_SIZE_8MB_E   = 23,
    VIP_AXI4_MEM_SIZE_16MB_E  = 24,
    VIP_AXI4_MEM_SIZE_32MB_E  = 25,
    VIP_AXI4_MEM_SIZE_64MB_E  = 26,
    VIP_AXI4_MEM_SIZE_128MB_E = 27,
    VIP_AXI4_MEM_SIZE_256MB_E = 28,
    VIP_AXI4_MEM_SIZE_512MB_E = 29,
    VIP_AXI4_MEM_SIZE_1GB_E   = 30,
    VIP_AXI4_MEM_SIZE_2GB_E   = 31,
    VIP_AXI4_MEM_SIZE_4GB_E   = 32,
    VIP_AXI4_MEM_SIZE_8GB_E   = 33,
    VIP_AXI4_MEM_SIZE_16GB_E  = 34,
    VIP_AXI4_MEM_SIZE_32GB_E  = 35,
    VIP_AXI4_MEM_SIZE_64GB_E  = 36,
    VIP_AXI4_MEM_SIZE_128GB_E = 37,
    VIP_AXI4_MEM_SIZE_256GB_E = 38,
    VIP_AXI4_MEM_SIZE_512GB_E = 39,
    VIP_AXI4_MEM_SIZE_1TB_E   = 40
  } vip_axi4_memory_size_t;


  function automatic vip_axi4_size_t size_as_enum(int burst_size);
    case (burst_size)
      1:       return VIP_AXI4_SIZE_1_BYTE_E;
      2:       return VIP_AXI4_SIZE_2_BYTES_E;
      4:       return VIP_AXI4_SIZE_4_BYTES_E;
      8:       return VIP_AXI4_SIZE_8_BYTES_E;
      16:      return VIP_AXI4_SIZE_16_BYTES_E;
      32:      return VIP_AXI4_SIZE_32_BYTES_E;
      64:      return VIP_AXI4_SIZE_64_BYTES_E;
      128:     return VIP_AXI4_SIZE_128_BYTES_E;
      default: $error("ERROR [size_as_enum] Invalid size");
    endcase
  endfunction


  function automatic int burst_size_as_integer(vip_axi4_size_t burst_size);
    case (burst_size)
      VIP_AXI4_SIZE_1_BYTE_E:    return 1;
      VIP_AXI4_SIZE_2_BYTES_E:   return 2;
      VIP_AXI4_SIZE_4_BYTES_E:   return 4;
      VIP_AXI4_SIZE_8_BYTES_E:   return 8;
      VIP_AXI4_SIZE_16_BYTES_E:  return 16;
      VIP_AXI4_SIZE_32_BYTES_E:  return 32;
      VIP_AXI4_SIZE_64_BYTES_E:  return 64;
      VIP_AXI4_SIZE_128_BYTES_E: return 128;
    endcase
  endfunction


  function automatic int burst_as_integer(vip_axi4_burst_t burst_type);
    case (burst_type)
      VIP_AXI4_BURST_FIXED_E:    return VIP_AXI4_BURST_FIXED_C;
      VIP_AXI4_BURST_INCR_E:     return VIP_AXI4_BURST_INCR_C;
      VIP_AXI4_BURST_WRAPPING_E: return VIP_AXI4_BURST_WRAP_C;
      VIP_AXI4_BURST_RESERVED_E: return VIP_AXI4_BURST_RESERVED_C;
    endcase
  endfunction

endpackage

`endif
