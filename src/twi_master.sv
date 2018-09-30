/*	
*	File:	twi_master.sv
*	Author:	Vlasov D.V.
*	Date: 	2018.09.24 
*/

module twi_master 
(
	//reset and clock
	input					clk,
	input					rst,
	//controller interface
	input			[6:0]	chip_addr,
	input			[7:0]	reg_addr,
	input			[7:0]	datain,
	output			[7:0]	dataout,
	input					wr,
	input					rd,
	output	logic			tr,
	input					tr_clr,
	//twi interface
	output					scl,
	inout					sda
);
	
	enum logic [2:0]	{ WAIT, START, START_R, READ, WRITE, DATA, STOP, WAIT_CLR } state, next_state ;	//FSM states
	
	localparam		t_start = 95 ,
					t_stop	= 95 ,
					t_start_change = 65 ,
					t_stop_change = 30 ,
					t_data = 125 ,
					t_clk_h = 30 ,
					t_clk_l = 96 ;
	
	logic			int_scl ;
	logic			int_sda ;
	logic			ans ;
	logic	[1:0]	rd_wr ;
	logic			rd_wr_cycle ;
	logic	[7:0]	int_reg ;
	logic	[8:0]	int_data_out ;
	logic	[3:0]	bit_counter ;
	logic	[2:0]	pos_counter ;
	assign			scl = ( state == WAIT ) ? '1 : int_scl ,
					sda = rd_wr				? 'z : int_sda ,
					dataout = int_data_out[8:1] ;
					
	logic	[7:0]	counter ;


	//FSM state change
	always_ff @( posedge	clk )
		if( rst )
		begin
			state <= next_state ;
		end
		else
			state <= WAIT ;
	//Finding next state for FSM
	always_comb 
	begin
		next_state = state ;
			case( state )
				WAIT	: 
						if( ( wr || rd ) && ( tr_clr == '0 ) && ( tr == '0 ) )
							next_state = START ;
				START	:
						if( ( wr == '1 ) && ( counter == t_start ) )
						begin
							next_state = WRITE ;
						end
						else if( ( rd == '1 ) && ( counter == t_start ) )
						begin
							next_state = READ ;
						end
				START_R	:
						if( counter == 90 )
							next_state = DATA ;
				READ	:
						if( pos_counter == 3'b100 )
							next_state	= STOP ;
						else if( pos_counter == 3'b010 )
							next_state	= START_R ;
						else
							next_state	= DATA ;
				WRITE	:
						if( pos_counter == 3'b011 )
							next_state	= STOP ;
						else
							next_state	= DATA ;
				DATA	: 
						if( ( bit_counter == 8 ) && ( counter == t_data ) )
						begin
							if( int_data_out[0] == '0 )
								begin
									if(	rd_wr_cycle == 0 )
										next_state	= READ ;
									else
										next_state	= WRITE ;
								end
							else
								next_state	= STOP ;
						end
				STOP	:
						if( counter == t_stop )
							next_state	= WAIT_CLR ;
				WAIT_CLR:
						if( tr_clr == '0 )
							next_state	= WAIT ;
				default	:
						next_state = WAIT ;
			endcase
	end
	//Other FSM sequence logic
	always_ff @( posedge clk )
	begin
		if( rst )
		begin
			tr <= '0 ;
			case( state )
				WAIT	:
						begin
							bit_counter <= '0 ;
							int_sda	<= '1 ;
							counter <= '0 ;
							int_scl <= '1 ;
							rd_wr <= 0 ;
							pos_counter <= '0 ;
						end
				START	: 
						begin
							int_sda	<= '1 ;
							int_scl <= '1 ;
							counter <= counter + 1'b1 ;
							if( counter > t_start_change )
								int_sda	<= '0 ;
							if( counter == t_start )
								counter <= '0 ;
							if( ( wr == '1 ) && ( counter == t_start ) )
							begin
								rd_wr_cycle <= '1 ;
							end
							else if( ( rd == '1 ) && ( counter == t_start ) )
							begin
								rd_wr_cycle <= '0 ;
							end
						end
				START_R	: 
						begin
							int_sda	<= '1 ;
							int_scl <= '0 ;
							counter <= counter + 1'b1 ;
							if( counter > 30 )
								int_scl	<= '1 ;
							if( counter > 60 )
								int_sda	<= '0 ;
							if( counter == 90 )
								counter <= '0 ;
						end
				READ	:
						begin
							pos_counter <= pos_counter + 1'b1 ;
							rd_wr <= '0 ;
							if( pos_counter == 3'b000 )
								int_reg <= { chip_addr , 1'b0 } ;
							else if( pos_counter == 3'b001 )
								int_reg <= reg_addr ;
							else if( pos_counter == 3'b010 )
								int_reg <= { chip_addr , 1'b1 } ;
							else if( pos_counter == 3'b011 )
							begin
								int_reg <= datain ;
								rd_wr <= '1 ;
							end
							bit_counter <= '0 ;
							counter <= '0 ;
						end
				WRITE	:
						begin
							pos_counter <= pos_counter + 1'b1 ;
							rd_wr <= '0 ;
							if( pos_counter == 3'b000 )
								int_reg <= { chip_addr , 1'b0 } ;
							else if( pos_counter == 3'b001 )
								int_reg <= reg_addr ;
							else if( pos_counter == 3'b010 )
							begin
								int_reg <= datain ;
							end
							bit_counter <= '0 ;
							counter <= '0 ;
						end
				DATA	: 
						begin
							counter <= counter + 1'b1 ;
							int_sda <= '0 ;
							if( ( counter > ( 10 ) ) && ( counter < ( t_data - 10 ) )  )
							begin
								int_sda <= int_reg[7] ;
								if( pos_counter == 3'b100 )
									int_sda <= '1 ;
							end
							if( ( bit_counter == 8 ) && ( counter == '0 ) )
								rd_wr <= ~ rd_wr ;
							if( ( bit_counter == 8 ) && ( counter == t_data ) )
							begin
								rd_wr <= '0 ;
								counter <= '0 ;
							end
							if( ( counter == t_data ) && ( bit_counter < 8 ) )
							begin
								counter <= '0 ;
								int_reg <= { int_reg[6:0] , 1'b0 } ;
								bit_counter <= bit_counter + 1'b1 ;
							end
							if( ( counter == ( t_clk_l / 2 + t_clk_h / 2 ) ) )
								int_data_out <= {int_data_out[7:0],sda} ;
							int_scl <= '0 ;
							if( ( counter > ( t_clk_l / 2 ) ) && ( counter < ( t_clk_l / 2 + t_clk_h ) )  )
								int_scl <= '1 ;
						end
				STOP	: 
						begin
							rd_wr <= '0 ;
							int_sda	<= '0 ;
							int_scl <= '1 ;
							counter <= counter + 1'b1 ;
							if( counter > t_stop_change )
								int_sda	<= '1 ;
							if( counter == t_stop )
								counter <= '0 ;
						end
				WAIT_CLR:
						begin	
							$stop();
							if( tr_clr == '0 )
								tr <= '1 ;
						end
			endcase
		end
		else
		begin
			counter <= '0 ;
			bit_counter <= '0 ;
			ans <= '0 ;
			pos_counter <= '0 ;
			tr <= '0 ;
		end
	end

endmodule : twi_master
