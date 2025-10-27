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
        #(  parameter FIFO_WIDTH = 8, // Width of the fifo (bits)
            parameter FIFO_LENGTH = 8 // Length of the fifo
        )
        (
            input clk, 
            input reset_n
        );



// always @(posedge clk, negedge reset_n) begin
//     if(!reset_n) begin
        
//     end else begin
           
//     end
// end

endmodule

`endif