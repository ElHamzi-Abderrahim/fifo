/*
   Date         : 2025-10-27
   Author       : Abderrahim EL HAMZI.
   Project      : FIFO.  
   Description  : Top module of the FIFO RTL block.
   File         : fifo_top.sv
*/ 


/* 
  NOTES:
      Legend:
        O : Empty place
        X : Full  place
        wr_ptr: The place to written to.
        rd_ptr: The place to be read.

          rd_ptr
          wr_ptr
             |
             v
        >----O----O----O----O----O----O---v
        |                                 |
        +---------------------------------+

      - After performing 1 Write:
        rd_ptr    wr_ptr
             |    |
             v    v
        >----X----O----O----O----O----O---v
        |                                 |
        +---------------------------------+

      - After performing 1 Read:
                rd_ptr
                wr_ptr
                  |
                  v
        >----O----O----O----O----O----O---v
        |                                 |
        +---------------------------------+

      - Full state (One clock cycle before):
        The condition to detect Full state: (wr_ptr+1) == rd_ptr
                  wr_ptr    rd_ptr
                       |    |
                       v    v
        >----X----X----O----X----X----X---v
        |                                 |
        +---------------------------------+
      
      - Empty state (One clock cycle before):
        The condition to detect Full state: (rd_ptr+1) == wr_ptr
                  rd_ptr    wr_ptr
                       |    |
                       v    v
        >----O----O----X----O----O----O---v
        |                                 |
        +---------------------------------+
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
    reg [WORD_LENGTH-1:0] array_reg [(2**ADDR_SIZE_B)-1:0]  ; // Unpacked array 

    // Pointers to be used for R/W operations
    reg [ADDR_SIZE_B-1:0] r_ptr_reg, r_ptr_next, r_ptr_plus_1; 
    reg [ADDR_SIZE_B-1:0] w_ptr_reg, w_ptr_next, w_ptr_plus_1; 

    // Read/Write Enable signals
    reg wr_en ;
    reg rd_en ;

    // empty/full reg signals
    reg empty_next, empty_reg ;
    reg full_next,  full_reg ;


    /* W/R enable control logic */
    assign wr_en = (~full_reg  & wr) ; 
    assign rd_en = (~empty_reg & rd) ; 

    
    /* Assign empty/full to output signal */
    assign empty = empty_reg  ;
    assign full  = full_reg   ;


    /* Logic for :
        - Access to array_reg; 
        - Incrementing the r/w pointer; and 
        - Detecting Empty/Full states.
    */
    always_comb begin
      w_ptr_plus_1 = w_ptr_reg + 1 ;
      r_ptr_plus_1 = r_ptr_reg + 1 ;

      // Always output the value to which the read pointer pointed to
      r_data      = array_reg[r_ptr_reg];

      // Default values
      r_ptr_next = r_ptr_reg ;
      w_ptr_next = w_ptr_reg ;
      full_next   = full_reg  ;
      empty_next  = empty_reg ;
      
      case({wr_en, rd_en})
        2'b10: begin // when wr enable asserted
          // Performing a write will cause the FIFO to not be empty
          empty_next  = 1'b0 ;
          // Write the data to the array, and increment the WR pointer
          array_reg[w_ptr_reg]  = w_data ;
          w_ptr_next            = w_ptr_plus_1 ;
          // If the next write_pointer will point to the current read_pointer, 
          //    that means that the FIFO will be full (Check the comments in the
          //    beginning of this code).
          full_next   = (w_ptr_plus_1 == r_ptr_reg) ? 1'b1 : 1'b0 ;
        end 
        2'b01: begin  // when rd enable asserted
          // Performing a read will cause the FIFO to not be full
          full_next   = 1'b0 ;
          r_ptr_next  = r_ptr_plus_1 ;
          // If the next read_pointer will point to the current write_pointer, 
          //    that means that the FIFO will be empty.
          empty_next  = (r_ptr_plus_1 == w_ptr_reg) ? 1'b1 : 1'b0 ;
        end
        2'b11: begin // when wr and rd enable asserted
          array_reg[w_ptr_reg]  = w_data ;
          w_ptr_next            = w_ptr_plus_1 ;
          r_ptr_next            = r_ptr_plus_1 ;
          full_next             = (w_ptr_plus_1 == r_ptr_reg) ? 1'b1 : 1'b0 ;
          empty_next            = (r_ptr_plus_1 == w_ptr_reg) ? 1'b1 : 1'b0 ;
        end
        default: begin // Default values as a good practice
          full_next   = full_reg  ;
          empty_next  = empty_reg ;
          r_ptr_next  = r_ptr_reg ;
          w_ptr_next  = w_ptr_reg ;
        end
      endcase
    end


    /*   Sequential Logic   */
    always_ff @(posedge clk, negedge reset_n) begin
      if(!reset_n) begin
        w_ptr_reg <= '0 ;
        r_ptr_reg <= '0 ;
        empty_reg <= 1'b1 ;
        full_reg  <= 1'b0 ;
      end else begin
        w_ptr_reg <= w_ptr_next ;
        r_ptr_reg <= r_ptr_next ;
        empty_reg <= empty_next ;
        full_reg  <= full_next  ;
      end
    end



  endmodule

`endif