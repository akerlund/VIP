# ------------------------------------------------------------------------------
# Common variables
# ------------------------------------------------------------------------------

MAKE_ROOT?=$(shell git rev-parse --show-toplevel)

# Defaults
RUN_DIR?=$(shell pwd)/rundir
PYRG_DIR?=$(shell pwd)/pyrg
UVM_TR_RECORD?=UVM_HIGH
UVM_VERBOSITY?=LOW
VIV_OOC?=1
GUI?=0
QUIET=0

# Define Vivado options
VIV_BUILD=0
VIV_SYNTH=1
VIV_ROUTE=2

# Module file list script
COMPILE_SH=./scripts/compile.sh

# Create list of available testcases for module
TC_LIST=$(patsubst %.sv,%,$(shell find ./tc -name tc_*.sv -printf "%f " 2> /dev/null))


# Tool scripts
RUN_VIVADO    = $(MAKE_ROOT)/scripts/vivado/run.sh
RUN_XSCT      = $(MAKE_ROOT)/scripts/xsct/run.sh
RUN_ZYNQ      = $(MAKE_ROOT)/scripts/vivado/run_zynq.sh
RUN_XSIM      = $(MAKE_ROOT)/scripts/vivado/xsim.sh
RUN_VERILATOR = $(MAKE_ROOT)/scripts/verilator/run.sh
RUN_PYRG      = $(MAKE_ROOT)/../PYRG/pyrg.py
RUN_VCS       = $(MAKE_ROOT)/scripts/vcs/run.sh
RUN_FPV       = $(MAKE_ROOT)/scripts/fpv/run.sh
RUN_FCA       = $(MAKE_ROOT)/scripts/fca/run.sh
SUM_REPORT    = $(MAKE_ROOT)/scripts/vivado/summary_report.sh

# ------------------------------------------------------------------------------
# Make targets
# ------------------------------------------------------------------------------

.PHONY: help build synth route zynq pyrg verilate vitis sw fpga fpv fca list clean $(TC_LIST)

help:
	@echo "  ------------------------------------------------------------------------------"
	@echo "  RTL Common Design - Make Environment"
	@echo "  ------------------------------------------------------------------------------"
	@echo ""
	@echo "  USAGE: make <target> [<make_variable>=some_value]"
	@echo ""
	@echo "  Targets:"
	@echo "  ------------------------------------------------------------------------------"
	@echo "  build    : Compile testbench with Vivado"
	@echo "  synth    : Vivado synthesis"
	@echo "  place    : Vivado synthesis and design place"
	@echo "  route    : Vivado synthesis, design place, routing and bitstream"
	@echo "  zynq     : Export a generated IP inside a block design for ZynQ"
	@echo "  pyrg     : Create register RTL with the module's register yaml file"
	@echo "  verilate : Run Verilator"
	@echo "  vitis    : Create Vitis project"
	@echo "  sw       : Vitis compile"
	@echo "  fpga     : FPGA bitstream upload"
	@echo "  vcs      : Compile with VCS"
	@echo "  fpv      : Run Formal Propery Verification (FPV)"
	@echo "  fca      : Run Formal Coverage Analyzer (FCA)"
	@echo "  list     : List the module's testcases"
	@echo "  tc_*     : Run testcase tc_*"
	@echo "  clean    : Remove RUN_DIR"
	@echo ""
	@echo "  Make variables:"
	@echo "  ------------------------------------------------------------------------------"
	@echo "  RUN_DIR       : Directory of builds and other runs, default is /run"
	@echo "  UVM_VERBOSITY : Verbosity in UVM simulations"
	@echo "  VIV_OOC       : Set Vivado to run out-of-context (OOC) (default enabled)"
	@echo ""

build:
	@$(RUN_VIVADO) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) $(VIV_BUILD) $(VIV_OOC)

synth:
	@$(RUN_VIVADO) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) $(VIV_SYNTH) $(VIV_OOC)

route:
	@$(RUN_VIVADO) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) $(VIV_ROUTE) $(VIV_OOC)

zynq:
	@$(RUN_ZYNQ) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) $(GUI)

pyrg:
	@$(RUN_PYRG) $(PYRG_DIR)

verilate:
	@$(RUN_VERILATOR) $(COMPILE_SH) $(RUN_DIR)

vitis:
	@$(RUN_XSCT) $(MAKE_ROOT) $(RUN_DIR) $(COMPILE_SH) 0

sw:
	@$(RUN_XSCT) $(MAKE_ROOT) $(RUN_DIR) $(COMPILE_SH) 1

fpga:
	@$(RUN_XSCT) $(MAKE_ROOT) $(RUN_DIR) $(COMPILE_SH) 2

vcs:
	@$(RUN_VCS) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) 0

fpv:
	@$(RUN_FPV) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) 1

fca:
	@$(RUN_FCA) $(MAKE_ROOT) $(COMPILE_SH) $(RUN_DIR) $(GUI)

list:
	@echo "List of testcases:"
	@for tc in $(TC_LIST); do echo " $$tc"; done

$(TC_LIST): tc_%: ${RUN_DIR}
	@$(RUN_XSIM) $(RUN_DIR) $(@) $(UVM_VERBOSITY) $(GUI) $(QUIET)

print_header:
	@echo "Testcase                        Result | Warnings | Errors | Failures | Time"
	@echo "---------------------------------------+----------+--------+----------+---------"


run_all: QUIET = 1
run_all: print_header $(TC_LIST)
	@$(SUM_REPORT) $(RUN_DIR)        # Create summary report from last line in each tc log

clean:
	@echo "Removing ${RUN_DIR}"
	@rm -rf ${RUN_DIR}
