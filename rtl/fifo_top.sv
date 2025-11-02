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

    // State type
    typedef enum logic [1:0] {EMPTY_STATE, WRITE_STATE, FULL_STATE, READ_STATE} state_t ;

    // Empty and Full registers
    reg empty_next, empty_reg;
    reg full_next, full_reg ;

    // Control R/W signals
    wire w_en ; // Read enable
    wire r_en ; // Write enable

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
        empty_reg  <= empty_next ;
        full_reg   <= full_next  ;
      end
    end

    /* Output Logic (FSM Moore type) */
    always_comb begin : output_logic
      w_ptr_plus_1 = w_ptr_reg + 1 ; 
      r_ptr_plus_1 = r_ptr_reg + 1 ; 

      case (state_reg)
        EMPTY_STATE: begin
          empty = 1'b1 ;
          array_reg[w_ptr_reg]  = w_data ;
          w_ptr_next            = w_ptr_plus_1 ;
          // if(wr) begin // Write at the same clock cycle the wr is asserted
          // end
        end

        WRITE_STATE: begin
          empty                 = 1'b0 ;
          full                  = 1'b0 ;
          array_reg[w_ptr_reg]  = w_data ;
          w_ptr_next            = w_ptr_plus_1 ;
        end

        FULL_STATE: begin
          empty                 = 1'b0 ;
          full                  = 1'b1 ;
        end

        READ_STATE: begin
          empty       = 1'b0 ;
          full        = 1'b0 ;
          r_data      = array_reg[r_ptr_reg];
          r_ptr_next  = r_ptr_plus_1 ;
        end
        default: begin
          empty       = 1'b0 ;
          full        = 1'b0 ;
        end
      endcase
    end






  // `define OLD_CODE
  `ifdef OLD_CODE

    /* Next-State Logic (Combinational) */
    always_comb begin : next_state_logic
      case ({wr,rd})
        2'b10: // Write Operation
          if(w_en) begin
            w_ptr_next            <= w_ptr_reg + 1; 
          end
        2'b01: // Read Operation
          if(r_en) begin
            r_ptr_next  <= r_ptr_reg + 1; 
          end
        default: begin // Nor Read/Write r/w_ptr regs keeps previous values
          r_ptr_next <= r_ptr_reg ;
          w_ptr_next <= w_ptr_reg ;
        end 
      endcase      
    end


    /* State Register */
    always_ff @(posedge clk, negedge reset_n) begin : state_register
      if(!reset_n) begin
        r_ptr_reg <= '0 ;
        w_ptr_reg <= '0 ;
        full_reg  <= 1'b0 ;
        empty_reg <= 1'b1 ;
      end 
      else begin
        w_ptr_reg <= w_ptr_next ;
        r_ptr_reg <= r_ptr_next ;
      end // else
    end // always_ff


    /* Output Logic (Combinational) */
    always_comb begin : output_logic
      // Control W/R enable signals
      w_en = wr & ~full_reg ; 
      r_en = rd & ~empty_reg ; 
      
    end
  `endif // OLD_CODE

  `ifdef ANOTHER_OLD_CODE

    // Assign empty/full reg to outputs signals
    assign empty = empty_reg ;
    assign full  = full_reg ;

    // Main process or R/W from/to the FIFO internal array (array_reg[])
    always_ff @(posedge clk, negedge reset_n) begin : process_rw_access
      if(!reset_n) begin
        // array_reg <= '{'0} ;
        r_ptr_reg <= '0 ;
        w_ptr_reg <= '0 ;
      end 
      else begin
        w_ptr_reg <= w_ptr_next ;
        r_ptr_reg <= r_ptr_next ;

        // Store the next address of the current r/w pointer (to be used to determine if empty/full state) 
        r_ptr_plus_1 <= r_ptr_reg + 1 ;
        w_ptr_plus_1 <= w_ptr_reg + 1 ;
        
        case ({wr,rd})
          2'b10: // Write Operation
            // Check if write is enabled (when FIFO is not full)
            if(w_en) begin
              array_reg[w_ptr_reg]  <= w_data ;
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
    assign w_en = (!full_reg)  ; 
    assign r_en = (!empty_reg) ; 

    // Process to control the empty/full states
    always_ff @( posedge clk, negedge reset_n) begin : control_rw_en
      if(!reset_n) begin
        empty_reg <= 1'b1 ;
        full_reg  <= 1'b0 ;
      end else begin
        // full  is detected when : write pointer -> read pointer
        full_reg  <= (w_ptr_plus_1 == r_ptr_reg) ; 
        // empty is detected when : read pointer -> write pointer
        empty_reg <= (r_ptr_plus_1 == w_ptr_reg) ;
      end // else
    end // always_ff
  
  `endif // ANOTHER_OLD_CODE 

  endmodule

`endif