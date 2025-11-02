`ifndef TB_TASKS_SV
  `define TB_TASKS_SV
  
  `include "tb_defines.sv"
  
  // Task that performs write to the FIFO
  task write_to_fifo (
                      input clk, 
                      input [`WORD_LENGTH-1:0] data,
                      output [`WORD_LENGTH-1:0] w_data,
                      output wr
                      ) ;
    // Perform Write
    $display("I'm in write_to_fifo task !") ;
    @(posedge clk) ;
    wr      = 1'b1 ;
    w_data  = data ;

    // idle state of signals
    @(posedge clk) ;
    wr      = 1'b0; 
    w_data  = '0 ;
  endtask: write_to_fifo


  // Task that performs read from the FIFO
  task read_from_fifo (
                      input clk, 
                      output [`WORD_LENGTH-1:0] data,
                      input  [`WORD_LENGTH-1:0] r_data,
                      output rd
                      ) ;
    // Perform Read
    @(posedge clk) ;
    rd      = 1'b1 ; 
    data    = r_data ;

    // idle state of signals
    @(posedge clk) ;
    rd      = 1'b0; 
    data    = '0 ;
  endtask: read_from_fifo


`endif
