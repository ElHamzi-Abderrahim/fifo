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
		localparam  INIT_DELAY_RST = 5; // Initial delay before deasserting the reset (e.g 5ns)
		localparam  SIM_TIME = 200; 		// Simulation time


		/* Signals Declaration: */
		// Clock and Reset:
		reg tb_clk ;
		reg tb_resetn;

		// DUT signals
		reg                   		s_wr ;
		reg	 [`WORD_LENGTH-1:0]  	s_w_data ;
		reg                   		s_rd ;
		reg  [`WORD_LENGTH-1:0]  	s_r_data ;
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

		// Variable to hold random data
		bit [`WORD_LENGTH-1:0] rand_data ;


		/* Clock generator */
		initial tb_clk = 0 ;
		always #(CLK_PERIOD/2) tb_clk = ~tb_clk;


		/* Dump values simulation results to .vcd (Variable Change Dump) file */
		initial begin
			$dumpfile("sim/dump.vcd");
			$dumpvars;
		end


		/* DUT Instantiation */
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

		/* Reset DUT */
		initial begin
			tb_resetn = 1;
			#1 ;
			tb_resetn = 0;
			#(INIT_DELAY_RST) ;
			tb_resetn = 1;
		end


		/* Initialize signals */
		initial begin
			s_wr			= 1'b0 ;
			s_rd			= 1'b0 ;
			s_w_data	= '0 ;
		end

		/* Run for 300ns */
		initial begin
			#(SIM_TIME) ;
			$finish ;
		end


		/* Perfrom W/R operations */
		always begin
			fork
				begin // Write to the FIFO
					for (int i = 0; i < (2**`ADDR_SIZE_B) ; i++ ) begin 
						// Generate random data
						rand_data = $urandom_range(0, (2**`WORD_LENGTH)-1) ;
						
						// push data to the queue
						queue_fifo.push_front(rand_data) ;

						// push data to the fifo
						$display("[%0t] PUSHING : data = %d", $time, rand_data);
						
						@(posedge tb_clk) ;
						s_wr      = 1'b1 ;
						s_w_data  = rand_data ;
						
						@(posedge tb_clk) ;
						s_wr      = 1'b0 ;
						s_w_data  = '0 ;
					end
				end

				begin // Monitor Empty/Full signals
					@(posedge tb_clk) ;
					$display("[%0t] MONITORING: Empty = %d ; Full = %d", $time, s_empty, s_full);
					$display("[%0t] MONITORING: dut.write_ptr_reg = %d", $time, dut.w_ptr_reg);
				end

			join
			// write_to_fifo(.clk(tb_clk), .data(rand_data), .w_data(s_w_data), .wr(s_wr))  ;

		end

		
	endmodule


`endif

