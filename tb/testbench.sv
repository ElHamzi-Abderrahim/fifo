/*
   Date    			: 2025-10-27
   Author  			: Abderrahim EL HAMZI.
   Project 			: fifo.  
   Description	: Circular-queue-based implementation of a FIFO. 
   File    			: testbench.v
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

		// DUT signals
		reg                   		s_wr ;
		reg	 [`ADDR_SIZE_B-1:0]  	s_w_data ;
		reg                   		s_rd ;
		reg  [`ADDR_SIZE_B-1:0]  	s_r_data ;
		reg                  			s_empty ;
		reg                  			s_full ;


		/* Local Variables to be used to stimulate the DUT */
		// Queue as ref module for the FIFO
		bit [`WORD_LENGTH-1:0] queue_fifo[$:(2**`ADDR_SIZE_B)-1] ;

		// Write/Read data to/from the queue
		bit [`WORD_LENGTH-1:0] q_wr_data ;
		bit [`WORD_LENGTH-1:0] q_rd_data ;

		// Write/Read data to/from the FIFO
		reg [`WORD_LENGTH-1:0] fifo_wr_data ;
		reg [`WORD_LENGTH-1:0] fifo_rd_data ;


		/* Clock generator: */
		initial tb_clk = 0 ;
		always #(CLK_PERIOD/2) tb_clk = ~tb_clk;


		/* Dump values simulation results to .vcd (Variable Change Dump) file */
		initial begin
			$dumpfile("sim/dump.vcd");
			$dumpvars;
		end


		/* DUT Instantiation: */
		fifo_top 	#(.WORD_LENGTH(`WORD_LENGTH),
								.ADDR_SIZE_B(`ADDR_SIZE_B)
							) 
		dut(
				.clk			(tb_clk),
				.reset_n	(tb_resetn),
				.wr				(s_wr)		,
				.w_data		(s_w_data),
				.rd				(s_rd)		,
				.r_data		(s_r_data),
				.empty		(s_empty)	,
				.full			(s_full)						
		);

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


		/* Perfrom W/R operations */
		always @(posedge tb_clk) begin
			
		end



		
	endmodule


`endif

