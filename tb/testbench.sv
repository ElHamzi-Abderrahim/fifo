/*
   Date    		: YYYY-MM-DD
   Author  		: Abderrahim EL HAMZI.
   Project 		: rtl_project_t.  
   Description	: template testbench to be used in GitHub for RTL related projects.
   File    		: testbench.v
*/ 

`ifndef TESTBENCH_SV
`define TESTBENCH_SV


// Macros Definitions:
`define YOUR_MACRO

`include "design.sv"
`include "tb_pkg.sv"
// Other .sv or .v files to be included...

`timescale 1ns/1ps


module testbench();
      
  	import tb_pkg::* ;

  	/* Local Parameters: */
  	localparam 	CLK_PERIOD = 10;
	localparam  INIT_DELAY_RST = 7; // Initial delay before deasserting the reset (e.g 10ns)
  
  	/* Signals Declaration: */
  	// Clock and Reset:
  	reg tb_clk ;
  	reg tb_resetn;
  	reg [$clog2(`PARAM_VALUE):0] tb_sigout;


	/* Clock generator: */
    initial tb_clk = 0 ;
    always #(CLK_PERIOD/2) tb_clk = ~tb_clk;


	/* Reset generator: */
    initial begin
        tb_resetn = 1;
      	#1 ;
        tb_resetn = 0;
      	#(INIT_DELAY_RST) ;
        tb_resetn = 1;
    end


    /* Run for 300ns: */
	initial begin
		#300ns ;
		$finish ;
	end


	/* Read design outputs */
	always @(posedge tb_clk) begin
		$display("DUT sig_output = %d", tb_sigout);
	end


    /* DUT Instantiation: */
    dummy_module 
  		#(.MY_PARAM (`PARAM_VALUE) 
        )
  	dut(
        .clk			(tb_clk),
      	.reset_n		(tb_resetn),
		.sig_output		(tb_sigout)
    );

  
  	initial begin
		/* Dump values simulation results to .vcd (Variable Change Dump) file */
		$dumpfile("sim/dump.vcd");
		$dumpvars;
	end
  
endmodule


`endif

