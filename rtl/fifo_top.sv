/*
   Date    		: 2025-10-27
   Author  		: Abderrahim EL HAMZI.
   Project 		: FIFO.  
   Description	: Top module of the FIFO RTL block.
   File    		: fifo_top.sv
*/ 


/* 
  NOTES:
      O : Empty place
      X : Full  place

          rd_ptr
          wr_ptr
             |
             v
        >----O----O----O----O----O----O---v
        |                                 |
        +---------------------------------+

			rd_ptr: The place to be read.
			wr_ptr: The place to written to.

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

    // State type
    typedef enum logic [1:0] {EMPTY_STATE, WRITE_STATE, FULL_STATE, READ_STATE} state_t ;

    // Current/Next state
    state_t state_reg, state_next ;


    /* Next State Logic */
    always_comb begin : next_state_logic
      case (state_reg)
        EMPTY_STATE: begin
          case({wr,rd})
            2'b10 : begin
            state_next = WRITE_STATE ;
            end 
            2'b01 : begin
              state_next = EMPTY_STATE ;
            end
            default: 
              state_next = EMPTY_STATE ;
          endcase
        end

        WRITE_STATE: begin
          case({wr,rd})
            2'b10 : begin
              if(w_ptr_plus_1 == r_ptr_reg) begin
                state_next = FULL_STATE ;
              end else begin
                state_next = WRITE_STATE ;
              end
            end 
            2'b01 : begin
              state_next = READ_STATE ;
            end
            default: 
              state_next = WRITE_STATE ;
          endcase
        end

        FULL_STATE: begin
          case({wr,rd})
            2'b01 : begin
            state_next = READ_STATE ;
            end 
            2'b10 :  begin
              state_next = FULL_STATE ;
            end
            default: 
              state_next = FULL_STATE ;
          endcase
        end
        
        READ_STATE: begin
          case({wr,rd})
            2'b01 : begin
              if(r_ptr_plus_1 == w_ptr_reg) begin
                state_next = EMPTY_STATE ;
              end else begin
                state_next = READ_STATE ;
              end
            end 
            2'b10 :  begin
              state_next = WRITE_STATE ;
            end
            default: 
              state_next = READ_STATE ;
          endcase
        end 
        default: 
          state_next = EMPTY_STATE ; 
      endcase
    end
    
    /* State Register */
    always_ff @( posedge clk, negedge reset_n ) begin : state_register
      if(!reset_n) begin
        state_reg  <= EMPTY_STATE ;
        r_ptr_reg  <= '0 ;
        w_ptr_reg  <= '0 ;
      end else begin
        state_reg  <= state_next ;
        r_ptr_reg  <= r_ptr_next ;
        w_ptr_reg  <= w_ptr_next ;
      end
    end

    /* Output Logic (FSM Moore type) */
    always_comb begin : output_logic
      w_ptr_plus_1 = w_ptr_reg + 1 ;
      r_ptr_plus_1 = r_ptr_reg + 1 ;

      r_ptr_next = r_ptr_reg ;
      w_ptr_next = w_ptr_reg ;

      r_data = '0 ; 

      case (state_reg)
        EMPTY_STATE: begin
          empty = 1'b1 ;
          full  = 1'b0 ;
        end

        WRITE_STATE: begin
          empty                 = 1'b0 ;
          full                  = 1'b0 ;
          if(wr) begin
            array_reg[w_ptr_reg]  = w_data ;
            w_ptr_next            = w_ptr_plus_1 ;
          end 
        end

        FULL_STATE: begin
          full                  = 1'b1 ;
          empty                 = 1'b0 ;
        end

        READ_STATE: begin
          empty       = 1'b0 ;
          full        = 1'b0 ;
          if(rd) begin
            r_data      = array_reg[r_ptr_reg];
            r_ptr_next  = r_ptr_plus_1 ;\
          end
        end
        default: begin
          empty       = 1'b0 ;
          full        = 1'b0 ;
        end
      endcase
    end

  endmodule

`endif