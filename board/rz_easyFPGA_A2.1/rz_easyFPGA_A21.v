module rz_easyFPGA_A21(
	input       CLK100MHZ,
	input       KEY0,
	input       KEY1,
	output      [3:0]  LED,
	output		scl,
	inout		sda
);

    // wires & inputs
    wire          clk;
    wire          clkIn     =  CLK100MHZ;
    wire          rst_n     =  KEY0;
    wire          clkEnable =  ~KEY1;
    wire [ 31:0 ] regData;

    //cores
    sm_top sm_top
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .clkDevide  ( 4'b1000   ),
        .clkEnable  ( clkEnable ),
        .clk        ( clk       ),
        .regAddr    ( 4'b0010   ),
        .regData    ( regData   ),
		.sda		( sda		),
		.scl		( scl		)
    );

    //outputs
    //assign LED[0]   = clk;
    assign LED[3:0] = ~ regData[3:0];

endmodule