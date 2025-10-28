`ifndef TB_TASKS_SV
  `define TB_TASKS_SV

  // Task that performs write to the FIFO
  task write_to_fifo (
                      input clk, 
                      input [`WORD_LENGTH-1:0] data,
                      output [`WORD_LENGTH-1:0] w_data,
                      output wr
                      ) ;
    @(posedge clk) ;
    // Perform Write
    wr = 1; 
    w_data = data ;

    // idle state of signals
    wr = 0; 
    w_data = '0 ;


  endtask: write_to_fifo


`endif
