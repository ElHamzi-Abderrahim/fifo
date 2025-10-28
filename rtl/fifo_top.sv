/*
   Date    		: 2025-10-27
   Author  		: Abderrahim EL HAMZI.
   Project 		: FIFO.  
   Description	: Top module of the FIFO RTL block.
   File    		: fifo_top.sv
*/ 

`ifndef FIFO_TOP_SV
  `define FIFO_TOP_SV

  module fifo_top 
          #(  parameter WORD_LENGTH = 8, // Word length in bits
              parameter ADDR_SIZE_B = 8    // Address size in bits
          )
          (
            input                         clk, 
            input                         reset_n,

            input                         wr,
            input       [WORD_LENGTH-1:0] w_data,

            input                         rd,
            output reg  [WORD_LENGTH-1:0] r_data,

            output reg                    empty,
            output reg                    full
          );

    // Array of regs to store the elements of the fifo
    reg [ADDR_SIZE_B-1:0] array_reg [(2**ADDR_SIZE_B)-1:0]  ; // Unpacked array 

    // Pointers to be used for R/W operations
    reg [WORD_LENGTH-1:0] r_ptr_reg, r_ptr_next, r_ptr_plus_1; 
    reg [WORD_LENGTH-1:0] w_ptr_reg, w_ptr_next, w_ptr_plus_1; 

    // Empty and Full registers
    reg empty_reg;
    reg full_reg ;

    // Control R/W signals
    wire w_en ; // Read enable
    wire r_en ; // Write enable

    // Assign empty/full reg to outputs signals
    assign empty = empty_reg ;
    assign full  = full_reg ;

    // Main process or R/W from/to the FIFO internal array (array_reg[])
    always_ff @(posedge clk, negedge reset_n) begin : process_rw_access
      if(!reset_n) begin
        array_reg <= '{'0} ;
        r_ptr_reg <= '0 ;
        w_ptr_reg <= '0 ;
        empty_reg <= 1'b1 ;
        full_reg  <= 1'b0 ;
      end 
      else begin
        r_ptr_reg <= r_ptr_next ;
        w_ptr_reg <= w_ptr_next ;

        // Store the next address of r/w pointer (to be used to determine if empty/full) 
        r_ptr_plus_1 <= r_ptr_reg + 1 ;
        w_ptr_plus_1 <= w_ptr_reg + 1 ;
        
        case ({wr,rd})
          2'b10: // Write Operation
            // Check if write is enabled (when FIFO is not full)
            if(w_en) begin
              array_reg[r_ptr_reg]  <= w_data ;
              w_ptr_next            <= w_ptr_reg + 1; 
            end
          2'b01: // Read Operation
            // Check if read is enabled (when FIFO is not empty)
            if(r_en) begin
              r_data      <= array_reg[r_ptr_reg] ;
              r_ptr_next  <= r_ptr_reg + 1; 
            end
          default: begin // Nor Read/Write r/w_ptr regs keeps previous values
            r_ptr_next <= r_ptr_reg ;
            w_ptr_next <= w_ptr_reg ;
          end 
        endcase
      end // else
    end // always_ff

    // Control W/R enable signals
    assign w_en = (!full_reg) ; 
    assign r_en = (!empty_reg) ; 

    // Process to control the empty/full states
    always_ff @( posedge clk, negedge reset_n) begin : control_rw_en
      if(!reset_n) begin
        full_reg  <= 1'b0 ;
        empty_reg <= 1'b1 ;
      end else begin
        // full is detected when the next pointer of Write equal to the current Read pointer
        full_reg  <= (w_ptr_plus_1 == r_ptr_reg) ; 
        // empty is detected when the next pointer of Read equal to the current Write pointer
        empty_reg <= (r_ptr_plus_1 == w_ptr_reg) ;
      end // else
    end // always_ff

  endmodule

`endif