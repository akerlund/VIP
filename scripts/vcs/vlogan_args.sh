vlogan_args+="-kdb "                        # Compile the Knowledge Database (KDB) for Verdi
vlogan_args+="-ntb_opts uvm-1.2 "           # Specifying the version explicitly
vlogan_args+="-timescale=1ns/1ps "          # Timescale of all files, <time_unit/time_resolution>
vlogan_args+="-full64 "                     # Enables compilation and simulation in 64-bit mode
vlogan_args+="-l analyze.log "              # Log file name
vlogan_args+="+define+AXI4PC_EOS_OFF "      # Disabling End of Simulation checks
vlogan_args+="+define+UVM_NO_DEPRECATED=1 " #
vlogan_args+="+define+RTL_ASSERT_ON "       #

if [ ! -z "$usecase" ]; then
  vlogan_args+="+define+${usecase} "
fi

vlogan_args+="-assert svaext "              # Fix for enabling 2012 assert properties
