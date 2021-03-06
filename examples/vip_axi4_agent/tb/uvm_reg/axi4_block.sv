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

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//           AUTOGENERATED FILE, DO NOT CHANGE THIS FILE MANUALLY.            //
//           CHANGE THE YAML FILE AND RERUN THE SCRIPT TO GENERATE.           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

class axi4_block extends uvm_reg_block;

  `uvm_object_utils(axi4_block)

  rand command_reg command;
  rand configuration_reg configuration;
  rand status_reg status;


  function new (string name = "axi4_block");
    super.new(name, build_coverage(UVM_NO_COVERAGE));
  endfunction


  function void build();

    command = command_reg::type_id::create("command");
    command.build();
    command.configure(this);

    configuration = configuration_reg::type_id::create("configuration");
    configuration.build();
    configuration.configure(this);

    status = status_reg::type_id::create("status");
    status.build();
    status.configure(this);



    default_map = create_map("axi4_map", 0, 8, UVM_LITTLE_ENDIAN);

    default_map.add_reg(command, 0, "WO");
    default_map.add_reg(configuration, 8, "RW");
    default_map.add_reg(status, 16, "RW");


    lock_model();

  endfunction

endclass

