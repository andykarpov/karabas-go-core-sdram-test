`timescale 1ns / 1ps
`default_nettype none

/*-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######                                         ############### ############### 
--                                                                                 #               #             # 
--                                                                                 #   ########### #             # 
--                                                                                 #             # #             # 
-- https://github.com/andykarpov/karabas-go                                        ############### ############### 
--
-- FPGA SDRAM Test core for Karabas-Go
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

module karabas_go_top (
	//---------------------------
	input wire 				CLK_50MHZ,

	//---------------------------
	inout wire 				UART_RX,
	inout wire 				UART_TX,
	inout wire 				UART_CTS,
	inout wire 				ESP_RESET_N,
	inout wire 				ESP_BOOT_N,

	//---------------------------
	output wire [20:0] 	MA,
	inout wire [15:0] 	MD,
	output wire [1:0] 	MWR_N,
	output wire [1:0] 	MRD_N,

	//---------------------------
	output wire [1:0] 	SDR_BA,
	output wire [12:0] 	SDR_A,
	output wire 			SDR_CLK,
	output wire [1:0] 	SDR_DQM,
	output wire 			SDR_WE_N,
	output wire 			SDR_CAS_N,
	output wire 			SDR_RAS_N,
	inout wire [15:0] 	SDR_DQ,

	//---------------------------
	output wire 			SD_CS_N,
	output wire 			SD_CLK,
	inout wire 				SD_DI,
	inout wire 				SD_DO,
	input wire 				SD_DET_N,

	//---------------------------
	output wire [7:0] 	VGA_R,
	output wire [7:0] 	VGA_G,
	output wire [7:0] 	VGA_B,
	output wire 			VGA_HS,
	output wire 			VGA_VS,
	output wire 			V_CLK,

	//---------------------------
	output wire 			FT_SPI_CS_N,
	output wire 			FT_SPI_SCK,
	input wire 				FT_SPI_MISO,
	output wire 			FT_SPI_MOSI,
	input wire 				FT_INT_N,
	input wire 				FT_CLK,
	output wire 			FT_OE_N,

	//---------------------------
	output wire [2:0] 	WA,
	output wire [1:0] 	WCS_N,
	output wire 			WRD_N,
	output wire 			WWR_N,
	output wire 			WRESET_N,
	inout wire [15:0] 	WD,

	//---------------------------
	input wire 				FDC_INDEX,
	output wire [1:0] 	FDC_DRIVE,
	output wire 			FDC_MOTOR,
	output wire 			FDC_DIR,
	output wire 			FDC_STEP,
	output wire 			FDC_WDATA,
	output wire 			FDC_WGATE,
	input wire 				FDC_TR00,
	input wire 				FDC_WPRT,
	input wire 				FDC_RDATA,
	output wire 			FDC_SIDE_N,

	//---------------------------
	output wire 			TAPE_OUT,
	input wire 				TAPE_IN,
	output wire 			BEEPER,

	//---------------------------
	output wire 			DAC_LRCK,
	output wire 			DAC_DAT,
	output wire 			DAC_BCK,
	output wire 			DAC_MUTE,

	//---------------------------
	input wire 				MCU_CS_N,
	input wire 				MCU_SCK,
	inout wire 				MCU_MOSI,
	output wire 			MCU_MISO,
	input wire 				MCU_SPI_FT_CS_N,
	input wire 				MCU_SPI_SD2_CS_N,
	inout wire [1:0] 		MCU_SPI_IO,

	//---------------------------
	output wire 			MIDI_TX,
	output wire 			MIDI_CLK,
	output wire 			MIDI_RESET_N,

	//---------------------------
	output wire 			FLASH_CS_N,
	input wire  			FLASH_DO,
	output wire 			FLASH_DI,
	output wire 			FLASH_SCK,
	output wire 			FLASH_WP_N,
	output wire 			FLASH_HOLD_N
);

// parameters for MT48LC16M16A2
parameter DRAM_COL_SIZE = 9;
parameter DRAM_ROW_SIZE = 13;

// unused signals
assign ESP_RESET_N 	= 1'bZ;
assign ESP_BOOT_N 	= 1'bZ;
//assign FLASH_CS_N 	= 1'b1;
assign FLASH_DI 		= 1'b1;
assign FLASH_SCK 		= 1'b0;
assign FLASH_WP_N 	= 1'b1;
assign FLASH_HOLD_N 	= 1'b1;
assign TAPE_OUT 		= 1'b0;
assign BEEPER 			= 1'b0;
assign UART_CTS 		= 1'b0;
assign WA 				= 3'b0;
assign WCS_N 			= 2'b11;
assign WRD_N 			= 1'b1;
assign WWR_N 			= 1'b1;
assign WRESET_N 		= 1'b1;
assign MA 				= 21'b0;
assign MWR_N			= 2'b11;
assign MRD_N 			= 2'b11;
assign FDC_DRIVE 		= 2'b00;
assign FDC_MOTOR 		= 1'b0;
assign SD_CS_N			= 1'b1;
assign FDC_SIDE_N		= 1'b1;
assign SD_CLK			= 1'b1;
assign FDC_WDATA		= 1'b1;
assign FDC_WGATE		= 1'b1;
assign MIDI_RESET_N	= 1'b1;
assign FDC_STEP		= 1'b1;
assign FDC_DIR			= 1'b1;
assign MIDI_TX			= 1'b1;
assign MIDI_CLK      = 1'b0;
assign FT_SPI_CS_N 	= 1'b1;
assign FT_SPI_SCK 	= 1'b1;
assign FT_SPI_MOSI 	= 1'b1;
assign FT_OE_N 		= 1'b1;
assign DAC_BCK			= 1'b0;
assign DAC_LRCK		= 1'b0;
assign DAC_DAT			= 1'b0;
assign DAC_MUTE 		= 1'b0; // 0 = mute

// pll
wire clk, clk_27, sdram_clk, clk_50, locked;
wire areset, reset, kb_reset, rst_n;
PLL_clock pll (                                 	  // 140 MHz - 140
	.CLK_IN1        (CLK_50MHZ  ),              // 150 MHz - 200 phase
	.CLK_OUT1       (clk        ),              // 155 MHz - 220 phase
	.CLK_OUT2       (clk_27     ),              // 160 MHz - 240 phase
	.CLK_OUT3       (sdram_clk  ),              // 166 MHz - 260 phase  - (240 phase - bad)
	.CLK_OUT4       (clk_50     ),              // 175 MHz - 280\300 phase  -  bad
	.LOCKED         (locked     ));

// clk = 100 @ 180
// sdram_clk = 100 @ 0

// sdram clk out
ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_inst 
(
	.Q(SDR_CLK),   // 1-bit DDR output data
	.C0(sdram_clk),  // 1-bit clock input
	.C1(!sdram_clk), // 1-bit clock input
	.CE(1'b1), 		// 1-bit clock enable input
	.D0(1'b1), 		// 1-bit data input (associated with C0)
	.D1(1'b0), 		// 1-bit data input (associated with C1)
	.R(1'b0),   	// 1-bit reset input
	.S(1'b0)    	// 1-bit set input
);

assign areset = ~locked;
assign reset = areset || kb_reset;
assign rst_n = ~reset;

// mem tester
wire [31:0] passcount, failcount;
wire [ 3:0] mmtst_state;
wire [ 5:0] sdram_state;
defparam my_memtst.DRAM_COL_SIZE = DRAM_COL_SIZE;
defparam my_memtst.DRAM_ROW_SIZE = DRAM_ROW_SIZE;

mem_tester my_memtst(
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .passcount      (passcount  ),
        .failcount      (failcount  ),
        .mmtst_state    (mmtst_state),
        .sdram_state    (sdram_state),
        .DRAM_DQ        (SDR_DQ     ),
        .DRAM_ADDR      (SDR_A[DRAM_ROW_SIZE-1:0]),
        .DRAM_LDQM      (SDR_DQM[0] ),
        .DRAM_UDQM      (SDR_DQM[1] ),
        .DRAM_WE_N      (SDR_WE_N   ),
        .DRAM_CS_N      (FLASH_CS_N ), // used as SDR_CS_N
        .DRAM_RAS_N     (SDR_RAS_N  ),
        .DRAM_CAS_N     (SDR_CAS_N  ),
        .DRAM_BA_0      (SDR_BA[0]  ),
        .DRAM_BA_1      (SDR_BA[1]  ));
		  
// elapsed time 

reg  [ 5:0] pos   = 0;
reg  [15:0] mins  = 0;
reg  [15:0] secs  = 0;
reg         auto  = 0;
reg         recfg = 0;
integer     min = 0, sec = 0;

always @(posedge clk_50) begin

    if(recfg) begin
        {min, mins} <= 0;
        {sec, secs} <= 0;
    end else begin
        min <= min + 1;
        if(min == 2999999999) begin
            min <= 0;
            if(mins[3:0]<9) mins[3:0] <= mins[3:0] + 1'd1;
            else begin
                mins[3:0] <= 0;
                if(mins[7:4]<9) mins[7:4] <= mins[7:4] + 1'd1;
                else begin
                    mins[7:4] <= 0;
                    if(mins[11:8]<9) mins[11:8] <= mins[11:8] + 1'd1;
                    else begin
                        mins[11:8] <= 0;
                        if(mins[15:12]<9) mins[15:12] <= mins[15:12] + 1'd1;
                        else mins[15:12] <= 0;
                    end
                end
            end
        end
        sec <= sec + 1;
        if(sec == 4999999) begin
            sec <= 0;
            secs <= secs + 1'd1;
        end
    end
end

// vga output
 wire hs, vs, de;
 wire [1:0] b, r, g;

vgaout showrez(
	  .clk            (clk_27     ),
	  .rez1           (passcount  ),
	  .rez2           (failcount  ),
	  .rez3           ({2'b00,mmtst_state}),

	  .bg             (6'b000010  ),					 // color fon?
	  .freq           (16'h0100   ),              // clock memory: 100 MHz
	  .elapsed        (mins       ),
	  .mark           (8'h80 >> {~auto, secs[2:0]}),
	  .hs             (hs         ),
	  .vs             (vs         ),
	  .de					(de			),
	  .b              (b          ),
	  .r              (r          ),
	  .g              (g          ));

// vga / ft mux
assign VGA_R[7:0] 	= {r, 6'b0};
assign VGA_G[7:0] 	= {g, 6'b0};
assign VGA_B[7:0] 	= {b, 6'b0};
assign VGA_HS 			= hs;
assign VGA_VS 			= vs;

// vclk
ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) ODDR2_vclk 
(
	.Q(V_CLK),   // 1-bit DDR output data
	.C0(clk_27),  // 1-bit clock input
	.C1(!clk_27), // 1-bit clock input
	.CE(1'b1), 		// 1-bit clock enable input
	.D0(1'b1), 		// 1-bit data input (associated with C0)
	.D1(1'b0), 		// 1-bit data input (associated with C1)
	.R(1'b0),   	// 1-bit reset input
	.S(1'b0)    	// 1-bit set input
);

//---------- MCU ------------
wire mcu_busy;
wire dvi_only;

mcu mcu(
	.CLK				(clk),
	.N_RESET			(~areset),

	.MCU_MOSI		(MCU_MOSI),
	.MCU_MISO		(MCU_MISO),
	.MCU_SCK			(MCU_SCK),
	.MCU_SS			(MCU_CS_N),

	.DVI_ONLY		(dvi_only),
	
	.BUSY				(mcu_busy)
);

endmodule
