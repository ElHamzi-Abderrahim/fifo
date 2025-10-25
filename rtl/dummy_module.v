/*
   Date    		: YYYY-MM-DD
   Author  		: Abderrahim EL HAMZI.
   Project 		: rtl_project_t.  
   Description	: template .v file to be used in GitHub for RTL related projects.
   File    		: dummy_module.v
*/ 

`ifndef DUMMY_MODULE_V
`define DUMMY_MODULE_V

module dummy_module 
        #(  parameter MY_PARAM = 1)
        (
            input clk, 
            input reset_n,
            output reg [$clog2(MY_PARAM):0] sig_output
        );

reg flip_bit ;

// A dummy Design, its outputs is alternating between '0' and "MY_PARAM value" 
always @(posedge clk, negedge reset_n) begin
    if(!reset_n) begin
        sig_output <= '0 ;
        flip_bit   <= 0 ;
    end else begin
        flip_bit   <= ~flip_bit ;
        if(flip_bit) begin
            sig_output <= 0 ;
        end else begin 
            sig_output <= MY_PARAM ;
        end   
    end
end

endmodule

`endif