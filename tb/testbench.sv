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
	`define DEBUG

	`include "design.sv"
	`include "tb_pkg.sv"
	// Other .sv or .v files to be included...

	`timescale 1ns/1ps


	module testbench();
				
		import tb_pkg::* ;

		/* Local Parameters: */
		localparam 	CLK_PERIOD = 10;
		localparam  INIT_DELAY_RST = 5; // Initial delay before deasserting the reset (e.g 5ns)
		localparam  SIM_TIME = 1000; 		// Simulation time
		
		/* Events */
		event write_event ; // Triggered when write is performed
		event read_event ;  // Triggered when read  is performed

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


		/* Initialize signals */
		initial begin
			s_wr			= 1'b0 ;
			s_rd			= 1'b0 ;
			s_w_data	= '0 ;
		end


		/* Perfrom W/R operations */
		initial begin
			// Reset the DUT
			tb_resetn = 1;
			#1 ;
			tb_resetn = 0;
			#(INIT_DELAY_RST) ;
			tb_resetn = 1;
			
			
			for (int i = 0; i < (2**`ADDR_SIZE_B + 10) ; i++ ) begin 
				fork
					begin // Write to the FIFO
						// Generate random data
						rand_data = $urandom_range(0, (2**`WORD_LENGTH)-1) ;
						
						// push data to the queue
						queue_fifo.push_front(rand_data) ;

					`ifdef DEBUG	
						$display("+++++++++++++++++++++++++++++++++++++++++++++");
						$display("[%0t] PUSHING : data = %d ", $time, rand_data);
					`endif // DEBUG
						// push data to the fifo
						@(posedge tb_clk) ;
						s_w_data  = rand_data ;
						s_wr      = 1'b1 ;
						@(posedge tb_clk) ;
						->write_event ;
						s_wr      = 1'b0 ;
						s_w_data  = '0 ;
						@(posedge tb_clk) ; 
						@(posedge tb_clk) ;
					end

					begin // Monitor the DUT
						@(write_event.triggered) ;
					`ifdef DEBUG	
						$display("[%0t] MONITORING: Empty = %d ; Full = %d ", $time, s_empty, s_full);
						$display("[%0t] MONITORING: dut.write_ptr_reg = %d ", $time, dut.w_ptr_reg);
						// $display("[%0t] MONITORING: dut.state_reg     = %0s ", $time, dut.state_reg.name());
						$display("+++++++++++++++++++++++++++++++++++++++++++++");
					`endif // DEBUG
					end

				join
			end

		`ifdef DEBUG	
			$display("+++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] FIFO content   : %p ", $time, dut.array_reg) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] QUEUE content  : %p ", $time, queue_fifo) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++");
		`endif // DEBUG

			for (int i = 0; i < (2**`ADDR_SIZE_B + 10) ; i++ ) begin 
				begin // READ to the FIFO
					fork
						begin
							@(posedge tb_clk) ;
							s_rd      = 1'b1 ;
							@(posedge tb_clk) ;
							->read_event ;
							s_rd      = 1'b0 ;
							@(posedge tb_clk) ;
						end

						begin // Monitor the DUT
							@(read_event.triggered) ;
							q_rd_data = queue_fifo.pop_back() ;
							if((s_r_data != q_rd_data) && (s_empty != 1'b1)) begin
								$display("[%0t] ERROR: NOT MATCHING DATA: FIFO_rdata = %d, QUEUE_rdata = %d ", $time, s_r_data, q_rd_data);
							end
						`ifdef DEBUG	
							$display("+++++++++++++++++++++++++++++++++++++++++++++");
							$display("[%0t] QUEUE content   : %p ", $time, queue_fifo) ;
							$display("+++++++++++++++++++++++++++++++++++++++++++++");
							$display("[%0t] PULLED  : data = %d ", $time, s_r_data) ;
							$display("[%0t] QUEUE   : data = %d ", $time, q_rd_data) ;
							$display("[%0t] MONITORING: Empty = %d ; Full = %d ", $time, s_empty, s_full);
							$display("[%0t] MONITORING: dut.read_ptr_reg = %d ", $time, dut.r_ptr_reg);
							// $display("[%0t] MONITORING: dut.state_reg    = %0s ", $time, dut.state_reg.name());
							$display("+++++++++++++++++++++++++++++++++++++++++++++");
						`endif // DEBUG
						end
					join
				end
			end

			$finish ;

		end

		
	endmodule


`endif

