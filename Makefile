# Makefile for RTL simulation

info:
	@echo "all      : Clean, Compile and Simulate the project."
	@echo "compile  : compile the project."
	@echo "           NO_UVM=<1|0> : <Without|With> compiling UVM libs."
	@echo "simulate : simulate the project using ModelSim."
	@echo "           GUI=<1|0> 1: with GUI, 0: without GUI."
	@echo "clean    : clean work directory."



# Directrories variables:
RTL_DIR     = rtl
TB_DIR      = tb
WORK_DIR    = sim/work
DO_DIR      = do

# UVM Related variables:
UVM_HOME	= $(HOME)/uvm-1.2
UVM_SRC		= $(HOME)/uvm-1.2/src
UVM_PKG		= $(UVM_SRC)/uvm_pkg.sv
DPI_SRC 	= $(UVM_HOME)/src/dpi/uvm_dpi.cc

# Design files:
RTL_TOP 	= $(RTL_DIR)/design.sv
RTL_FLIST 	= $(RTL_DIR)/filelist.f
TB_TOP	 	= $(TB_DIR)/testbench.sv
TB_FLIST 	= $(TB_DIR)/filelist.f

# With/Without UVM variable (defaulted to Without UVM)
NO_UVM ?= 1 

# Check the passed value from the command line
ifeq ($(NO_UVM), 0)
	CMP_ARGS  += $(UVM_PKG) $(DPI_SRC)
	CMP_ARGS  += +incdir+$(UVM_SRC)
endif

# Simulation mode is defaulted without graphical user interface:
GUI ?= 0 

# Simulate with/without graphical user interface:
ifeq ($(GUI), 1) # Run with GUI:
	SIM_ARGS  += -gui
else # Run without GUI
	SIM_ARGS  += -c
endif

# Args for compilation
CMP_ARGS += $(TB_TOP)
CMP_ARGS += +acc
CMP_ARGS += -work $(WORK_DIR)
CMP_ARGS += +incdir+$(RTL_DIR)
CMP_ARGS += +incdir+$(TB_DIR)
CMP_ARGS += -f $(TB_FLIST)

# Args for simulation
SIM_ARGS += testbench
SIM_ARGS += -do "set gui_mode $(GUI);"
SIM_ARGS += -do $(DO_DIR)/waves.do
SIM_ARGS += -do $(DO_DIR)/sim_steps.do



# Makefile Targets
.PHONY: info all fetch_file_list compile simulate clean

all: clean compile simulate

compile: clean fetch_file_list
	@echo "Compiling the design and testbench..."
	export QUESTA=1
	vlib $(WORK_DIR)
	vmap work $(WORK_DIR)
	vlog 	$(CMP_ARGS)

simulate: clean compile
	@echo "Running Simulation..."
	vsim  $(SIM_ARGS)

clean: 
	@echo "Cleaning work direcory..."
	rm -rf $(WORK_DIR) transcript vsim.wlf

