/*
 * schoolMIPS - small MIPS CPU for "Young Russian Chip Architects" 
 *              summer school ( yrca@googlegroups.com )
 *
 * AHB-Lite gpio 
 * 
 * Copyright(c) 2017-2018 Stanislav Zhelnio
 */

`include "ahb_lite.vh"
`include "sm_settings.vh"

`define SM_GPIO_REG_CONTROL 5'h00
`define SM_GPIO_REG_ADDR_C  5'h04
`define SM_GPIO_REG_ADDR_R  5'h08
`define SM_GPIO_REG_DATA_I  5'h0C
`define SM_GPIO_REG_DATA_O  5'h10

module ahb_twi
(
    //bus side
    input            HCLK,
    input            HRESETn,
    input            HSEL,
    input            HWRITE,
    input            HREADY,
    input     [ 1:0] HTRANS,
    input     [31:0] HADDR,
    output    [31:0] HRDATA,
    input     [31:0] HWDATA,
    output           HREADYOUT,
    output           HRESP,
    //twi side
    input            clk_twi,
	output			 scl,
	inout			 sda
);
    // bus input decode
    wire request   = HREADY & HSEL & HTRANS != `HTRANS_IDLE;
    wire request_r = request & !HWRITE;

    wire request_w;
    wire request_w_new = request & HWRITE;
    sm_register_c r_request_w (HCLK, HRESETn, request_w_new, request_w);

    wire [31:0] addr_w;
    wire [31:0] addr_r = HADDR;
    sm_register_we #(32) r_addr_w (HCLK, HRESETn, request, HADDR, addr_w);

    // peripheral module interface
    wire        pm_we    = request_w;
    wire [31:0] pm_wd    = HWDATA;
    wire [31:0] pm_addr  = request_w ? addr_w : addr_r;
    wire        pm_valid = request_r | request_w;
    wire [31:0] pm_rd;

    sm_twi twi
    (
        .clk        ( HCLK         ),
        .rst_n      ( HRESETn      ),
        .bSel       ( pm_valid     ),
        .bAddr      ( pm_addr      ),
        .bWrite     ( pm_we        ),
        .bWData     ( pm_wd        ),
        .bRData     ( pm_rd        ),
        .clk_twi    ( clk_twi      ),
        .sda        ( sda          ),
        .scl        ( scl          )
    );

    // read after write hazard
    wire hz_raw;
    wire hz_raw_new = (request_r & request_w) | request_w_new;
    sm_register_c r_hz_raw (HCLK, HRESETn, hz_raw_new, hz_raw );

    // bus output
    assign HREADYOUT = ~hz_raw;
    assign HRDATA    = pm_rd;
    assign HRESP     = 1'b0;

endmodule


module sm_twi
(
    //bus side
    input             clk,
    input             rst_n,
    input             bSel,
    input      [31:0] bAddr,
    input             bWrite,
    input      [31:0] bWData,
    output reg [31:0] bRData,

    //twi side
    input             clk_twi,
	output			  scl,
	inout			  sda
);

    wire     [6:0]   chip_addr ;
    wire     [7:0]   reg_addr ;
    wire     [7:0]   data_in ;
    wire     [7:0]   data_out ;
    wire     [7:0]   control ;
    wire             control_we ;
    wire     [7:0]   conrol_from_cdc ;
    wire             rd_twi ;
    wire             wr_twi ;
    wire             wr2 ;
    wire             wait2 ;

    assign  control_we = ( bWrite && bAddr[4:0] == `SM_GPIO_REG_CONTROL ) ,
            { rd_twi, wr_twi} = conrol_from_cdc[1:0] ;

    localparam BLANK_WIDTH = 32 - `SM_GPIO_WIDTH;

    always @ (*)
        case(bAddr[4:0])
            default              : bRData = { 24'b0, control   };
            `SM_GPIO_REG_CONTROL : bRData = { 24'b0, control   };
            `SM_GPIO_REG_ADDR_C  : bRData = { 25'b0, chip_addr };
            `SM_GPIO_REG_ADDR_R  : bRData = { 24'b0, reg_addr  };
            `SM_GPIO_REG_DATA_I  : bRData = { 24'b0, data_in   };
            `SM_GPIO_REG_DATA_O  : bRData = { 24'b0, data_out  };
        endcase

    sm_register_we #(32) r_addr_chip     (clk, rst_n, bWrite && ( bAddr[4:0] == `SM_GPIO_REG_ADDR_C ), bWData, chip_addr);
    sm_register_we #(32) r_addr_reg      (clk, rst_n, bWrite && ( bAddr[4:0] == `SM_GPIO_REG_ADDR_R ), bWData, reg_addr);
    sm_register_we #(32) r_addr_data_in  (clk, rst_n, bWrite && ( bAddr[4:0] == `SM_GPIO_REG_DATA_I ), bWData, data_in);

    cdc cdc_0
    (
        //reset and clock
        .clk1       ( clk               ),
        .clk2       ( clk_twi           ),
        .rst        ( rst_n             ),
        .wr1        ( control_we        ),
        .wr2        ( wr2               ),
        .data1      ( bWData            ),
        .data2      ( 8'b0              ),
        .data1out   ( control           ),
        .data2out   ( conrol_from_cdc   ),
        .wait1      (                   ),
        .wait2      ( wait2             )
    );

    twi_master twi_master_0
    (
        //reset and clock
        .clk        ( clk_twi       ),
        .rst        ( rst_n         ),
        //controller interface
        .chip_addr  ( chip_addr     ),
        .reg_addr   ( reg_addr      ),
        .datain     ( data_in       ),
        .dataout    ( data_out      ),
        .wr         ( wr_twi        ),
        .rd         ( rd_twi        ),
        .tr         ( wr2           ),
        .tr_clr     ( wait2         ),
        //twi interface
        .scl        ( scl           ),
        .sda        ( sda           )
    );

endmodule
