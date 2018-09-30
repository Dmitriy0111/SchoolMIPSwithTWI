/*	
*	File:	cdc.sv
*	Author:	Vlasov D.V.
*	Date: 	2018.09.27 
*/

module cdc
(
    input           rst,
    input           clk1,
    input           clk2,
    input           wr1,
    input           wr2,
    input  [7:0]    data1,
    input  [7:0]    data2,
    output [7:0]    data1out,
    output [7:0]    data2out,
    output          wait1,
    output          wait2
);

   logic [7:0]  int_reg1 ;
   logic [7:0]  int_reg2 ;
   logic        req1 ;
   logic        ans1 ;
   logic        req2 ;
   logic        ans2 ;

   assign wait1 = req1 || ans2 ;
   assign wait2 = req2 || ans1 ;

   assign data1out = int_reg1 ;
   assign data2out = int_reg2 ;

   always_ff @(posedge clk1) 
   begin : write2first_reg
        if( ~rst )
        begin
            int_reg1 <= '0 ;
        end
        else if( wr1 )
            int_reg1 <= data1 ;
        else if( req2 )
            int_reg1 <= data2 ;
   end

   always_ff @(posedge clk1) 
   begin : answer_first
        if( ~rst )
        begin
            ans1 <= '0 ;
        end
        else 
            ans1 <= req2 ;
   end

   always_ff @(posedge clk1) 
   begin : request_first
        if( ~rst )
        begin
            req1 <= '0 ;
        end
        else if( wr1 )
        begin
            req1 <= '1 ;
        end
        if( ans2 == '1  )
            req1 <= '0 ;
   end

   always_ff @(posedge clk2) 
   begin : write2second_reg
        if( ~rst )
        begin
            int_reg2 <= '0 ;
        end
        else if( wr2 )
            int_reg2 <= data2 ;
        else if( req1 )
            int_reg2 <= data1 ;
   end

   always_ff @(posedge clk2) 
   begin : answer_second
        if( ~rst )
        begin
            ans2 <= '0 ;
        end
        else 
            ans2 <= req1 ;
   end

   always_ff @(posedge clk2) 
   begin : request_second
        if( ~rst )
        begin
            req2 <= '0 ;
        end
        else if( wr2 )
        begin
            req2 <= '1 ;
        end
        if( ans1 == '1  )
            req2 <= '0 ;
   end

endmodule : cdc
