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

    // State type
    typedef enum logic [2:0] {EMPTY_STATE, WRITE_STATE, FULL_STATE, READ_STATE, NOP_STATE} state_t ;

    // Current/Next state
    state_t state_reg, state_next ;

    // Read/Write Enable signals
    reg wr_en ;
    reg rd_en ;


    /***************** FSM (Mealy & Moore) section *********************/
    // Next State Logic
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
            2'b10 : begin // when wr is asserted
              state_next = WRITE_STATE ;
              // if(w_ptr_plus_1 == r_ptr_reg) begin
              //   state_next = FULL_STATE ;
              // end else begin
              //   state_next = WRITE_STATE ;
              // end

            end 
            2'b01 : begin // when rd is asserted
              state_next = READ_STATE ;
            end
            2'b00 : begin // when wr is deasserted
              state_next = NOP_STATE ;
            end
            2'b11: // when wr and rd are asserted (R/W simultaneously NOT SUPPORTED )
              state_next = state_reg ;
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
              state_next = state_reg ;
          endcase
        end
        
        READ_STATE: begin
          case({wr,rd})
            2'b01: begin // when rd asserted
              state_next = READ_STATE ;
              // if(r_ptr_plus_1 == w_ptr_reg) begin
              //   state_next = EMPTY_STATE ;
              // end else begin
              //   state_next = READ_STATE ;
              // end
            end 
            2'b10: begin // when wr asserted
              state_next = WRITE_STATE ;
            end
            2'b00: begin // when rd deasserted
              state_next = NOP_STATE ;
            end
            default: 
              state_next = READ_STATE ;
          endcase
        end 

        NOP_STATE: begin
          case({wr,rd})
            2'b10: begin // when wr asserted
              if(w_ptr_plus_1 == r_ptr_reg) begin
                state_next = FULL_STATE ;
              end else begin
                state_next = WRITE_STATE ;
              end
            end
            2'b01: begin // when rd asserted
              if(r_ptr_plus_1 == w_ptr_reg) begin
                state_next = EMPTY_STATE ;
              end else begin
                state_next = READ_STATE ;
              end
            end
            default: begin // when wr and rd not asserted OR when both asserted
              state_next = NOP_STATE ;
            end
          endcase
        end

        default: 
          state_next = EMPTY_STATE ; 
      endcase
    end
    
    // State Register
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

    // Output Logic (Depends on the Currend state and the Input signals)
    always_comb begin : output_logic
      // Default values
      wr_en = 1'b0 ;
      rd_en = 1'b0 ;

      case (state_reg)
        EMPTY_STATE: begin
          empty = 1'b1 ;
          full  = 1'b0 ;

          // if(wr) begin
          //   wr_en = 1'b1 ;
          // end else begin
          //   wr_en = 1'b0 ;
          // end
        end

        WRITE_STATE: begin
          empty = 1'b0 ;
          full  = 1'b0 ;
          wr_en = 1'b1 ;
          
          // if(wr) begin
          //   wr_en = 1'b1 ;
          // end else begin
          //   wr_en = 1'b0 ;
          // end
        end

        FULL_STATE: begin
          full  = 1'b1 ;
          empty = 1'b0 ;
        end

        READ_STATE: begin
          empty   = 1'b0 ;
          full    = 1'b0 ;
          rd_en = 1'b1 ;
          // if(rd) begin
          //   rd_en = 1'b1 ;
          // end else begin
          //   rd_en = 1'b0 ;
          // end
        end
        
        NOP_STATE: begin
          empty = 1'b0 ;
          full  = 1'b0 ;
          wr_en = 1'b0 ;
          rd_en = 1'b0 ;
        end

        default: begin
          empty = 1'b0 ;
          full  = 1'b0 ;
        end
      endcase
    end


    /***************** R/W Controller section *********************/
    always_comb begin : rw_ctrl
      w_ptr_plus_1 = w_ptr_reg + 1 ;
      r_ptr_plus_1 = r_ptr_reg + 1 ;

      r_ptr_next = r_ptr_reg ;
      w_ptr_next = w_ptr_reg ;

      case({wr_en, rd_en})
        2'b10: begin
          array_reg[w_ptr_reg]  = w_data ;
          w_ptr_next            = w_ptr_plus_1 ;
        end 

        2'b01: begin
          r_data      = array_reg[r_ptr_reg];
          r_ptr_next  = r_ptr_plus_1 ;
        end
      endcase
    end


  endmodule

`endif