/*
	Date    			: 2025-10-27
	Author  			: Abderrahim EL HAMZI.
	Project 			: fifo.  
	Description	: Testbench for a Circular-queue-based implementation of a FIFO. 
	File    			: testbench.v
*/ 

/*
	TEST Cases: 
		+=========================+========================================================+
		|        Tests            |                      Checkers                          |
		+=========================+========================================================+
		| Emptiness of FIFO in    | - dut.empty == 1'b1
		|  its initial state      | - dut.full  == 1'b1
		+-------------------------+--------------------------------------------------------+
		|                         | - After one WRITE (dut.empty==1'b0 && dut.full==1'b0)
		|        WRITING          | - After FIFO_SIZE of WRITE (dut.full==1'b1)
		|  initially: FIFO EMTPY  | - All the time !(dut.empty==1'b1 && dut.full==1'b1)
		+-------------------------+--------------------------------------------------------+
		|                         | - After one READ (dut.empty==1'b0 && dut.full==1'b0)
		|        READING          | - After FIFO_SIZE of WRITE (dut.full==1'b1)
		|  initially: FIFO FULL   | - All the time !(dut.empty==1'b1 && dut.full==1'b1)
		|                         | - Check data matching comparing to a reference model 
		|                         |   (a queue using push_front(), pop_back() methods ).
		+-------------------------+--------------------------------------------------------+

*/

`ifndef TESTBENCH_SV
	`define TESTBENCH_SV


	// Macros Definitions:
	`define DEBUG
	`define DETAIL_DEBUG

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
		localparam int unsigned queue_max_size = 2**`ADDR_SIZE_B ;
		bit [`WORD_LENGTH-1:0] queue_fifo[$:queue_max_size-1] ;

		// Write/Read data to/from the queue signals
		bit [`WORD_LENGTH-1:0] q_wr_data ;
		bit [`WORD_LENGTH-1:0] q_rd_data ;

		// Readed data from the FIFO signal
		reg [`WORD_LENGTH-1:0] fifo_rd_data ;

		// Variable to hold random data
		bit [`WORD_LENGTH-1:0] rand_data ;

		// Variables for test statistics
		int unsigned total_access = 0 ;
		int unsigned total_read   = 0 ;
		int unsigned total_write  = 0 ;

		int unsigned failed_read  = 0 ;
		int unsigned failed_write = 0 ;
		int unsigned total_failed = 0 ;
		
		int unsigned passed_read  = 0 ;
		int unsigned passed_write = 0 ;
		int unsigned total_passed = 0 ;

		real read_success_prcent ;
		real write_success_prcent ;

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

		/* Verbosity degree for printing messages  
			- Levels of Verbosity
					1: Print messages with type FAILED/ERROR
					2: Print messages with type PASSED + Message with lower number (1)
					3: Print messages with type INFO   + Message with lower number (1 and 2)
		*/
		int unsigned message_verbosity = 1 ;
		
		/* Tasks and Functions */
		// Function to print Info/Error/Failed/Success messages based on verbosity
		function void message_display(string type_message , string message);
			// Checker for the type of the message
			if(type_message != "FAILED" && type_message != "ERROR" && type_message != "PASSED" && type_message != "INFO") begin
				$display("ALGO-ERROR: The function message_display(type_message,...) type_message=(%0s) parameter is not supported", type_message) ;
				$display("ALGO-INFO : The supported types are : \"FAILED\" or \"ERROR\" or \"PASSED\" or \"INFO\".") ;
			end

			if(message_verbosity >= 3) begin
				$display("[%0t] %0s: %s", $time, type_message, message) ;
			end 
			else if (message_verbosity == 2) begin
				if(type_message == "FAILED" || type_message == "ERROR" || type_message == "PASSED") begin
					$display("[%0t] %0s: %s", $time, type_message, message) ;
				end
			end
			else if (message_verbosity == 1) begin
				if(type_message == "FAILED" || type_message == "ERROR") begin
					$display("[%0t] %0s: %s", $time, type_message, message) ;
				end
			end
		endfunction : message_display

  	// Task that performs write to the FIFO
		task write_to_fifo( input [`WORD_LENGTH-1:0] data, input int post_drive_delay) ;
			// Perform Write
			@(posedge tb_clk) ;
			s_wr      = 1'b1 ;
			s_w_data  = data ;
			// idle state of signals
			@(posedge tb_clk) ;
			s_wr      = 1'b0; 
			s_w_data  = '0 ;
			repeat(post_drive_delay) @(posedge tb_clk) ;
  	endtask: write_to_fifo

		// Task that performs read from the FIFO
		task read_from_fifo ( output [`WORD_LENGTH-1:0] data) ;
			// Perform Read
			@(posedge tb_clk) ;
			s_rd      = 1'b1 ; 
			data      = s_r_data ;
			// idle state of signals
			@(posedge tb_clk) ;
			s_rd      = 1'b0;
		endtask: read_from_fifo

		// Function for checking non matching data
		function bit check_missmatch( bit[`WORD_LENGTH-1:0] fifo_pop_data, bit[`WORD_LENGTH-1:0] queue_pop_data);
			if(queue_pop_data != fifo_pop_data) begin
				$display("[%0t] FAILED: Data Missmatch FIFO (0x%0h) , QUEUE-REF-MODEL (0x%0h). \n", 
									$time, fifo_pop_data, queue_pop_data) ; 
				return 1'b0 ;
			end	
			else begin
			`ifdef DETAIL_DEBUG
				message_display("PASSED", 
												$sformatf("Data Matching (0x%0h).\n", 
																	queue_pop_data) ) ;
			`endif // DETAIL_DEBUG
				return 1'b1 ;
			end
		endfunction: check_missmatch



		/* Main W/R Tests */
		initial begin
			// Reset the DUT
			tb_resetn = 1;
			#1 ;
			tb_resetn = 0;
			#(INIT_DELAY_RST) ;
			tb_resetn = 1;
			
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] Start of WRITING tests", $time) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			for (int i = 0; i < (2**`ADDR_SIZE_B + 10) ; i++ ) begin 
				fork
					begin // Thrd-1: Write to the FIFO
						// Generate random data
						rand_data = $urandom_range(0, (2**`WORD_LENGTH)-1) ;						
					
						message_display("INFO", 
														$sformatf("PUSHING data = %d to the FIFO and the QUEUE(ref. model).", 
																			rand_data) ) ;

						// push data to the queue
						if(i < queue_max_size) queue_fifo.push_front(rand_data) ;
						
						// Push the data to the FIFO
						write_to_fifo(.data(rand_data), .post_drive_delay(2)) ;

						message_display("INFO", 
														$sformatf("PUSHED data = %d to the FIFO and the QUEUE(ref. model).", 
																						rand_data) ) ;
						total_write += 1 ;
						// Trigger the event of the end of Write operation
						->write_event ;
					end // Thrd-1

					begin	// Thrd-2: Monitor Write operations
						// Check if the default state of the FIFO is empty
						if( (i == 0) && (queue_fifo.size() == 0) ) begin // When no write op is not perfromed
							total_access += 1 ;
							if (s_empty == 1'b1) begin
								total_passed += 1 ;
								message_display( "PASSED", 
																		$sformatf("Default state of the FIFO is empty, empty signal is asserted (=0x%0h). ", 
																							s_empty) );
							end else begin
								total_failed += 1 ;
								message_display( "FAILED",
																		$sformatf("Default state of the FIFO should be empty, empty signal is not asserted (=0x%0h). ", 
																							s_empty) );
							end
						end // Initial state of the FIFO checker

						// wait(write_event.triggered) ; // for our use case it's not the best choice, because it detects the trigger that occured in the same timestep.
						@write_event ; // waits for the next trigger (to avoid running the checkers on the previous DATA)
						// Checker for full state of the FIFO
						if(queue_fifo.size() < queue_max_size) begin // When FIFO is not full yet
							if(s_full == 1'b1)begin
								failed_write += 1 ;
								message_display( "FAILED", 
																	$sformatf("FIFO is not full and Full signal (=0x%0h) should not be asserted. ", 
																						s_full) );
							end else begin
								passed_write += 1 ;
								message_display("PASSED", 
																$sformatf("FIFO is not full and Full signal (=0x%0h) is not asserted. ", 
																					s_full) ) ;
							end
						end else begin // When FIFO is full
							if(s_full==1'b1)begin
								passed_write += 1 ;
								message_display("PASSED", 
																$sformatf("FIFO is full and Full signal (=0x%0h) is asserted.", 
																					s_full) ) ;
							end else begin
								failed_write += 1 ;
								message_display("FAILED", 
																$sformatf("FIFO is full and Full signal (=0x%0h) should be asserted.", 
																					s_full) ) ;
							end
						end
					end // Thrd-2

					begin // Thrd-3: Check if Full & Empty are not asserted at the same time
						if(s_empty == 1'b1 && s_full == 1'b1) begin
							total_failed += 1 ;
							message_display("FAILED", 
																$sformatf("Empty (=0x%0h) and Full (=0x%0h) asserted at the same time.", 
																					s_empty, s_full) ) ;
						end
					end // Thrd-3

					begin // Thrd-4: Check if Empty are not asserted when FIFO has data
						@write_event;
						if(s_empty == 1'b1) begin
							if (queue_fifo.size() != 0) begin
								total_failed += 1 ;
								message_display("FAILED", 
																	$sformatf("FIFO is not empty and the Empty signal (=0x%0h) is asserted.", 
																						s_empty) ) ;
							end
						end
					end // Thrd-3

				join
			end

			$display("| WRITE report: ") ;
			$display("|   + Passed WRITE : %0d ", passed_write) ;
			$display("|   - Failed WRITE : %0d ", failed_write) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] End of WRITING tests", $time) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");


			// Display the content of the FIFO and the ref model
			message_display("INFO", $sformatf("FIFO  content   : %p ", dut.array_reg)) ;
			message_display("INFO", $sformatf("QUEUE content   : %p ", queue_fifo)) ;



			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] Start of READING tests", $time) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			for (int i = 0; i < (2**`ADDR_SIZE_B + 10) ; i++ ) begin 
				begin // READ from the FIFO
					fork
						begin // Thrd-1: Perform the Read operations
							read_from_fifo(.data(fifo_rd_data)) ;
							total_read 		+= 1 ;
							q_rd_data = queue_fifo.pop_back() ;
							if(!s_empty) begin
								failed_read = (check_missmatch(.fifo_pop_data(fifo_rd_data), .queue_pop_data(q_rd_data)))
															? failed_read : (failed_read+1) ;
							end
							// Trigger the event of read after one clock cycle in order to wait for the dut 
							//  to update its state after that clock cycle which comes after performing the
							//  Read access that causes the FIFO to be empty. 
							@(posedge tb_clk) ;
							->read_event ;
						end // Thrd-1

						begin // Thrd-2: Monitor the Read operations
							// Checking transition from full to non-full state, after performing one read of the filled FIFO
							if( i == 1 ) begin
								total_access += 1 ;
								if (s_full == 1'b0) begin
									total_passed += 1 ;
									message_display( "PASSED", 
																			$sformatf("State of the FIFO FULL=>NON-FULL after one read, full signal is deasserted (=0x%0h). ", 
																								s_full) );
								end else begin
									total_failed += 1 ;
									message_display( "FAILED",
																			$sformatf("State of the FIFO didn't change from FULL to NON-FULL after one read, full signal (=0x%0h) should be deasserted. ", 
																								s_full) );
								end
							end // After one read of the filled FIFO checker

							@read_event ; // Wait for read access to end.
							if(queue_fifo.size() == 0) begin
								if(s_empty == 1'b0)begin
									failed_read += 1 ;
									message_display( "FAILED", 
																		$sformatf("FIFO should be empty and Empty signal (=0x%0h) should not be asserted. ", 
																							s_empty) );
								end else begin
									passed_read += 1 ;
									message_display("PASSED", 
																	$sformatf("FIFO is empty and Empty signal (=0x%0h) is asserted. ", 
																						s_empty) ) ;
								end
							end else begin
								if(s_empty==1'b0)begin
									passed_read += 1 ;
									message_display("PASSED", 
																	$sformatf("FIFO is not empty and Empty signal (=0x%0h) is not asserted.", 
																						s_empty) ) ;
								end else begin
									failed_read += 1 ;
									message_display("FAILED", 
																	$sformatf("FIFO is not empty and Empty signal (=0x%0h) should not be asserted.", 
																						s_empty) ) ;
								end
							end
						end // Thrd-2
						
						begin // Thrd-3: Check if Full & Empty are not asserted at the sametime
						if(s_empty == 1'b1 && s_full == 1'b1) begin
							total_failed += 1 ;
							message_display("FAILED", 
																$sformatf("Empty (=0x%0h) and Full (=0x%0h) asserted at the sametime.", 
																					s_empty, s_full) ) ;
						end
					end // Thrd-3
					join
				end
			end
			
			$display("| READ report: ") ;
			$display("|   + Passed READ : %0d ", passed_read) ;
			$display("|   - Failed READ : %0d ", failed_read) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			$display("[%0t] End of READING tests", $time) ;
			$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			
			// Sumup the number of access
			total_failed += (failed_write + failed_read) ;
			total_passed += (passed_write + passed_read) ;			
			total_access += (total_write  + total_read ) ;

			// Global Statistics
			read_success_prcent = (passed_read/total_read)*100 ;
			write_success_prcent = (passed_write/total_write)*100 ;


			$display("\n") ;
			$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			$display("+-----------------------------------------------------------------");
			$display("| TEST REPORT (total access of %01d)", total_access) ;
			$display("|   + Passed READ  : %0d ", passed_read ) ;
			$display("|   + Passed WRITE : %0d ", passed_write) ;
			$display("|   - Failed READ  : %0d ", failed_read ) ;
			$display("|   - Failed WRITE : %0d ", failed_write) ;
			$display("|  -> Total Failed : %0d ", total_failed) ;
			$display("|  -> Total Passed : %0d ", total_passed) ;
			$display("|  Statistics (%%):  ") ;
			$display("|   + Passed WRITE : %0f %% ", read_success_prcent) ;
			$display("|   + Passed READ  : %0f %% ", write_success_prcent ) ;
			$display("+-----------------------------------------------------------------");
			$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n");

			$finish ;

		end

		
	endmodule


`endif

