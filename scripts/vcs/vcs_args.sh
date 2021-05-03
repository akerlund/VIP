vcs_args+="-debug_acc+all "        # Simulate the design in the interactive mode
vcs_args+="-debug_region+cell "    # Applies debug capabilities to the cells
vcs_args+="-debug_region+encrypt " # Applies debug capabilities to the fully-encrypted instances
vcs_args+="-full64 "               # Enables compilation and simulation in 64-bit mode
vcs_args+="-ntb_opts uvm-1.2 "     # Specifying the version explicitly
vcs_args+="-notice "               # Enables verbose diagnostic messages
vcs_args+="-licqueue "             # Tells VCS MX to try for the license till it finds the license.
vcs_args+="-timescale=1ns/1ps "    # Timescale of all files, <time_unit/time_resolution>
vcs_args+="-l elaboration.log "    # Specifies a file where VCS MX records compilation messages
vcs_args+="-suppress=PCTI-L "      # Interface port, filed enhancement STAR: 9001199588
vcs_args+="-j8 "                   # Parallell execution of compilation, 8 threads
vcs_args+="+lint=TFIPC-L "         # Print out the name of missing ports
#vcs_args+="-V "
#vcs_args+="-Vt "
