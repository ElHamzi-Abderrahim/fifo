**Release:** `v1.0.0`

# About:
This is a circular buffer based FIFO implementation using SystemVerilog.

![fifo_block](doc/fifo_block.jpg)


## Technical Aspects:
- The FIFO block is performing its operations based on a synchronous clock signal `clk` on the positive edge;
- The reset of the block is asynchronous, and is a low active by de-asserting `reset_n` signal; 
- Data can be writing/reading can be perfromed just in one clock cycle, when `wr`/`rd` signals are asserted;
- FIFO has two state signals `empty` and `full` to indicate if the FIFO is empty or full consicutively when asserted (impossible to have both asserted simultanuously), and otherwise when it's not neither empty of full.
- Writing and Reading can be performed simultanuously; and
- Data in the tail of the FIFO is available in the `r_data` directly, but the `rd` signal should be asserted in order to pop that data and advance the internal pointer to the following data if the FIFO is not empty.




## Global View:
### Project Status: 
- Basic implementation is finished, with some basic tests and checkers to verify the basic functionality of the FIFO.

### To-Do List: 
- Perform more functional verification (tests) using either OOP concepts of SysVerilog or UVM, in order to have more flexibility on Verification work;
- Synthesis the RTL code using VIVADO Tool, or online tool EDAPlayGround.




## Mini User Guide:
### Pre-requirements:
- Linux Based Operating System;
- Installed QuestaSim, or its free version ModelSim; and
- In case of using UVM libraries: the uvm-1.2 library should be downloaded online and located under `$(HOME)/uvm-1.2`.

### How to use:
Currently the only simulator that is supported is Modelsim (aka QuestaSim). 
The makefile targets are used as the following:
```
make <target>  
```
#### Targets: 
```
    all      : Clean, Compile and Simulate the project.
    compile  : compile the project.
            NO_UVM=<1|0> : <Without|With> compiling UVM libs (in order to reduce compilation time).
    simulate : simulate the project using ModelSim.
            GUI=<1|0> 1: with GUI, 0: without GUI.
    clean    : clean work directory.
```




## Project Structure: 
    .
    ├── do
    │   ├── sim_steps.do
    │   └── waves.do
    ├── doc
    │   ├── fifo_block.drawio
    │   └── fifo_block.jpg
    ├── Makefile
    ├── README.md
    ├── rtl
    │   ├── design.sv
    │   ├── fifo_top.sv
    │   └── filelist.f
    ├── sim
    │   ├── dump.vcd
    │   └── work
    │       └──...
    └── tb
        ├── filelist.f
        ├── tb_defines.sv
        ├── tb_pkg.sv
        └── testbench.sv



## Notices: 
- This project was produced a real human brain, no LLM modul used to produce/correct this project's code.
- If you found errors/bugs let me know (my contact is bellow), I'm just a beginner trying to learn by doing it from scratch :-) . 
- This RTL code can be used under the user responsibility.


## Contacts:
- abderrahimelhamzi.dev@gmail.com


