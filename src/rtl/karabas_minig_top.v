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
-- FPGA SDRAM Test core for Karabas-Go Mini rev.G
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

// Warning! HW_ID3 macros defined in the Synthesize - XST process properties!

module karabas_minig_top (
	//---------------------------
	input wire 				CLK_50MHZ,

	//---------------------------
	inout wire 				UART_RX,
	inout wire 				UART_TX,
	inout wire 				UART_CTS,

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
	input wire [7:0] 		VGA_R,
	input wire [7:0] 		VGA_G,
	input wire [7:0] 		VGA_B,
	input wire 				VGA_HS,
	input wire 				VGA_VS,

	output wire [3:0] 	TMDS_P,
	output wire [3:0] 	TMDS_N,

	//---------------------------
	output wire 			FT_SPI_CS_N,
	output wire 			FT_SPI_SCK,
	input wire 				FT_SPI_MISO,
	output wire 			FT_SPI_MOSI,
	input wire 				FT_INT_N,
	input wire 				FT_CLK,
	input wire 				FT_DE,
	output wire 			FT_CLK_OUT,

	//---------------------------
	output wire [2:0] 	WA,
	output wire [1:0] 	WCS_N,
	output wire 			WRD_N,
	output wire 			WWR_N,
	output wire 			WRESET_N,
	inout wire [15:0] 	WD,

	//---------------------------	
	output wire 			TAPE_OUT,
	input wire 				TAPE_IN,
	
   //---------------------------
	output wire          DAC_BCK,
	output wire          DAC_WS,
	output wire          DAC_DAT,

	//---------------------------
	output wire 			ADC_CLK,
	inout wire 				ADC_BCK,
	inout wire 				ADC_LRCK,
	input wire 				ADC_DOUT,
	
	//---------------------------
	output wire          ESP32_SPI_CS_N,
	input wire           ESP32_PCM_BCK,
	input wire           ESP32_PCM_RLCK,
	input wire           ESP32_PCM_DAT,

	//---------------------------
	input wire 				MCU_CS_N,
	input wire 				MCU_SCK,
	input wire 				MCU_MOSI,
	output wire 			MCU_MISO,
	inout wire [5:0] 		MCU_IO,   // [1] INT of link v2, [2] sd2 cs_n, [3] ft cs_n

	//---------------------------
	output wire 			MIDI_TX,

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

// unused signals yet
assign FLASH_DI 		= 1'b1;
assign FLASH_SCK 		= 1'b0;
assign FLASH_WP_N 	= 1'b1;
assign FLASH_HOLD_N 	= 1'b1;
assign MA				= 21'b0;
assign MWR_N			= 1'b1;
assign MRD_N			= 1'b1;
assign SD_CS_N			= 1'b1;
assign SD_CLK			= 1'b1;
assign WA				= 3'b000;
assign WCS_N			= 1'b1;
assign WRD_N			= 1'b1;
assign WWR_N			= 1'b1;
assign WRESET_N		= 1'b1;
assign MIDI_TX			= 1'b1;
assign TAPE_OUT		= 1'b0;
assign DAC_BCK = 1'b0;
assign DAC_WS = 1'b0;
assign DAC_DAT = 1'b0;
assign ADC_CLK = 1'b0;
assign ADC_BCK = 1'b0;
assign ADC_LRCK = 1'b0;
assign ESP32_SPI_CS_N = 1'b1;

// ------------------------------------------------------------------ clocks

// the PLL: clk_27 (video), clk_50 (the MCU link, the counters); its 100 MHz outputs are not used:
// the tester clock comes from the DCM below
wire clk_pll_unused, sdram_clk_unused, clk_27, clk_50, locked;
PLL_clock pll (
	.CLK_IN1        (CLK_50MHZ  ),
	.CLK_OUT1       (clk_pll_unused),
	.CLK_OUT2       (clk_27     ),
	.CLK_OUT3       (sdram_clk_unused),
	.CLK_OUT4       (clk_50     ),
	.LOCKED         (locked     ));
wire areset = ~locked;

// the clock of the FT812: 50 / 6 = 8.33 MHz, it must always have one (karabas-go-notes ft-clk-out-required)
reg [1:0] ft_div = 2'd0;
reg ft_clk = 1'b0;
always @(posedge clk_50) begin
	ft_div <= (ft_div == 2'd2) ? 2'd0 : ft_div + 2'd1;
	if (ft_div == 2'd2) ft_clk <= ~ft_clk;
end
assign FT_CLK_OUT = ft_clk;

// the tester clock: a DCM_CLKGEN on clk_50, CLKFX = 50 x M / D, M and D set at run time over its
// PROG port (as the frequency keys of MiSTer MemTest, which reprograms its PLL); the SDRAM gets
// CLKFX180 through an ODDR2 (the half clock phase of the PLL before). The timing is derived for its
// start value M / D = 10 / 3 (166.7 MHz), the highest of the table.
wire clk_fx, clk_fx180;
wire clk, clk180, dcm_locked, progdone;
reg progen = 1'b0, progdata = 1'b0, dcm_rst = 1'b1;
DCM_CLKGEN #(
	.CLKFXDV_DIVIDE(2),
	.CLKFX_DIVIDE(3),
	.CLKFX_MULTIPLY(10),
	.CLKFX_MD_MAX(3.34),   // the highest M / D of the table (10 / 3): the timing is analysed at 167 MHz
	.CLKIN_PERIOD(20.0),
	.SPREAD_SPECTRUM("NONE"),
	.STARTUP_WAIT("FALSE")
) dcm (
	.CLKIN(clk_50),        // the 50 MHz of the PLL: CLK_50MHZ has its IBUFG in PLL_clock
	.CLKFX(clk_fx),
	.CLKFX180(clk_fx180),
	.CLKFXDV(),
	.LOCKED(dcm_locked),
	.PROGDONE(progdone),
	.STATUS(),
	.FREEZEDCM(1'b0),
	.PROGCLK(clk_50),
	.PROGDATA(progdata),
	.PROGEN(progen),
	.RST(dcm_rst)
);
BUFG bufg_fx (.I(clk_fx), .O(clk));
BUFG bufg_fx180 (.I(clk_fx180), .O(clk180));

ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
) ODDR2_inst (
	.Q(SDR_CLK),
	.C0(clk180),
	.C1(!clk180),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);

// ------------------------------------------------------------------ MCU

// MCU_SCK on a global buffer
wire mcu_sck_ibufg, mcu_sck;
IBUFG ibufg_mcu_sck (.I(MCU_SCK), .O(mcu_sck_ibufg));
BUFG bufg_mcu_sck (.I(mcu_sck_ibufg), .O(mcu_sck));

// MCU link v2 (karabas-go-firmware docs/link_v2.md, kg_mcu2); INT on IO1
wire mcu_int;
assign MCU_IO[1] = mcu_int;
assign MCU_IO[0] = 1'bz;
assign MCU_IO[5:2] = 4'bzzzz;

wire [15:0] sw;
wire [7:0] ps2_code;
wire ps2_kind, ps2_wr;
wire mcu_busy, dvi_only;
wire ft_cs_n, ft_mosi, ft_spi_on;
wire osd_wr, osd_en, osd_zoom;
wire [11:0] osd_waddr;
wire [7:0] osd_wdata;
wire [23:0] osd_fg, osd_bg;
wire [1:0] osd_alpha, osd_place;
wire [4:0] osd_px, osd_ph;
wire [3:0] osd_py;
wire [5:0] osd_pw;

kg_mcu2 #(
	.SW_N(2),
	.CS_FILTER(3),
	.ENABLE_OSD(1),
	.ENABLE_FT(1),
	.ENABLE_SD2(0)
) mcu (
	.CLK(clk_50),
	.N_RESET(~areset),

	.MCU_SCK(mcu_sck),
	.MCU_MOSI(MCU_MOSI),
	.MCU_MISO(MCU_MISO),
	.MCU_SS(MCU_CS_N),
	.MCU_INT(mcu_int),
	.MCU_SPI_FT_SS(MCU_IO[3]),
	.MCU_SPI_SD2_SS(MCU_IO[2]),

	.SW(sw), .SW_WR(), .SW_INDEX(), .SW_VALUE(), .HW_ID(), .DVI_ONLY(dvi_only), .CORE_BUILD(), .FW_BUILD(),
	.BUSY(mcu_busy), .BTNS(), .RELOAD_REQ(1'b0), .RELOAD_CORE(8'd0),

	.KBD(), .KBD_WR(), .PS2_CODE(ps2_code), .PS2_KIND(ps2_kind), .PS2_WR(ps2_wr),
	.MS_X(), .MS_Y(), .MS_Z(), .MS_B(), .MS_WR(),
	.JOY_L(), .JOY_R(), .JOY_WR(),
	.PS2_CMD(16'h0000), .PS2_CMD_WR(1'b0),

	.LD_KIND(), .LD_SLOT(), .LD_SIZE(), .LD_START(), .LD_ACTIVE(), .LD_END(),
	.LD_ADDR(), .LD_DATA(), .LD_WR(), .LD_READY(1'b1),

	.OSD_WR(osd_wr), .OSD_WADDR(osd_waddr), .OSD_WDATA(osd_wdata), .OSD_EN(osd_en),
	.OSD_FG(osd_fg), .OSD_BG(osd_bg), .OSD_ALPHA(osd_alpha), .OSD_PX(osd_px), .OSD_PY(osd_py),
	.OSD_PW(osd_pw), .OSD_PH(osd_ph), .OSD_PLACE(osd_place), .OSD_ZOOM(osd_zoom),

	.SDC_IMG_MOUNTED(), .SDC_IMG_SIZE(),
	.SDC_RD(8'd0), .SDC_WR(8'd0), .SDC_SECTOR(32'd0),
	.SDC_BUSY(), .SDC_DONE(), .SDC_ERROR(), .SDC_SLOT(),
	.SDC_BYTE_IN_STROBE(), .SDC_BYTE_ADDR(), .SDC_BYTE_IN_DATA(), .SDC_BYTE_OUT_DATA(8'd0),
	.IMG_WP(), .IMG_PHYS_WR(), .IMG_PHYS(), .IMG_FLUSH(), .FDD_CHNG_WR(), .FDD_CHNG(),
	.FDD_CHNG_REQ(1'b0), .FDD_CHNG_DS(2'd0),
	.BK_MOUNT(1'b0), .BK_FLUSHED(1'b0), .BK_SLOT(3'd0), .BK_SIZE(32'd0), .BK_KIND(8'd0), .BK_RESULT(8'd0),
	.IMG_ACTIVE(),

	.PORT_OUT_DATA(), .PORT_OUT_WR(), .PORT_OUT_READY(4'b1111), .PORT_IN_DATA(32'd0), .PORT_IN_WR(4'd0),
	.PORT_CFG(128'd0), .PORT_IN_FULL(), .PORT_STAT(), .PORT_STAT_WR(),
	.RTC_A(8'd0), .RTC_DI(8'd0), .RTC_CS(1'b0), .RTC_WR_N(1'b1), .RTC_DO(),
	.MATRIX_CMD(24'd0), .MATRIX_CMD_WR(1'b0), .DEBUG_ADDR(16'd0), .DEBUG_DATA(16'd0),

	.FT_SPI_ON(ft_spi_on), .FT_VGA_ON(), .FT_RESET(), .FT_SCK(), .FT_MOSI(ft_mosi), .FT_MISO(FT_SPI_MISO),
	.FT_CS_N(ft_cs_n),
	.SD2_SCK(), .SD2_MOSI(), .SD2_MISO(1'b1), .SD2_CS_N()
);

assign FT_SPI_CS_N = ft_spi_on ? ft_cs_n : 1'b1;
assign FT_SPI_SCK = ft_spi_on ? mcu_sck_ibufg : 1'b1;
assign FT_SPI_MOSI = ft_spi_on ? ft_mosi : 1'b1;

// OSD item 0 Reset: the test starts again (item 1 Global Reset is done by the firmware)
wire kb_reset = sw[0];

// ------------------------------------------------------------------ the frequency (clk_50)

// as MiSTer MemTest: Up / Down another frequency, Enter auto mode. In auto mode a minute with no
// error moves one step up; an error moves one step down and ends auto mode. A change reprograms
// the DCM and starts the test again (the counters and the time from 0).
// The table: M / D of 50 MHz, the BCD value shown in "MHz" of the screen.
reg [2:0] fsel = 3'd0;
function [7:0] f_m; input [2:0] i;
	case (i) 3'd0: f_m = 8'd2; 3'd1: f_m = 8'd11; 3'd2: f_m = 8'd12; 3'd3: f_m = 8'd13;
		3'd4: f_m = 8'd14; 3'd5: f_m = 8'd3; 3'd6: f_m = 8'd16; default: f_m = 8'd10; endcase
endfunction
function [7:0] f_d; input [2:0] i;
	case (i) 3'd0: f_d = 8'd1; 3'd1: f_d = 8'd5; 3'd2: f_d = 8'd5; 3'd3: f_d = 8'd5;
		3'd4: f_d = 8'd5; 3'd5: f_d = 8'd1; 3'd6: f_d = 8'd5; default: f_d = 8'd3; endcase
endfunction
function [15:0] f_bcd; input [2:0] i;
	case (i) 3'd0: f_bcd = 16'h0100; 3'd1: f_bcd = 16'h0110; 3'd2: f_bcd = 16'h0120; 3'd3: f_bcd = 16'h0130;
		3'd4: f_bcd = 16'h0140; 3'd5: f_bcd = 16'h0150; 3'd6: f_bcd = 16'h0160; default: f_bcd = 16'h0166; endcase
endfunction

// the keys: PS/2 set 2 bytes of kg_mcu2 (E0 75 Up, E0 72 Down, 5A Enter; F0 a release)
reg k_e0 = 1'b0, k_f0 = 1'b0;
reg key_up = 1'b0, key_dn = 1'b0, key_en = 1'b0;
always @(posedge clk_50) begin
	key_up <= 1'b0;
	key_dn <= 1'b0;
	key_en <= 1'b0;
	if (ps2_wr && !ps2_kind) begin
		if (ps2_code == 8'hE0) k_e0 <= 1'b1;
		else if (ps2_code == 8'hF0) k_f0 <= 1'b1;
		else begin
			if (!k_f0) begin
				key_up <= k_e0 && ps2_code == 8'h75;
				key_dn <= k_e0 && ps2_code == 8'h72;
				key_en <= !k_e0 && ps2_code == 8'h5A;
			end
			k_e0 <= 1'b0;
			k_f0 <= 1'b0;
		end
	end
end

// the fail counter of the tester (clk) seen in clk_50: an error is a change of it
wire [31:0] passcount, failcount;
reg [1:0] fail_s = 2'b00;
reg fail_d = 1'b0;
always @(posedge clk_50) begin
	fail_s <= { fail_s[0], failcount != 32'd0 };
	fail_d <= fail_s[1];
end
wire fail_new = fail_s[1] && !fail_d;

// the DCM program: LoadD (1 0, D-1 LSB first), LoadM (1 1, M-1), GO; then wait for PROGDONE and LOCKED
localparam P_IDLE = 3'd0, P_LOADD = 3'd1, P_LOADM = 3'd2, P_GAP = 3'd3, P_GO = 3'd4, P_WAIT = 3'd5;
reg [2:0] pst = P_IDLE;
reg [3:0] pbit = 4'd0;
reg [9:0] pword = 10'd0;
reg [7:0] pgap = 8'd0;
reg pnext_m = 1'b0;
reg prog_req = 1'b1;        // at the start: from 10 / 3 to the first value of the table
reg busy_f = 1'b1;          // the tester waits while the clock changes
reg recfg = 1'b1;
reg auto = 1'b0;
reg [31:0] minute = 32'd0;
reg [7:0] rst_cnt = 8'd0;

always @(posedge clk_50) begin
	progen <= 1'b0;
	progdata <= 1'b0;
	if (rst_cnt != 8'd255) rst_cnt <= rst_cnt + 8'd1;
	dcm_rst <= rst_cnt < 8'd8;

	// the choice
	if (pst == P_IDLE && !prog_req && rst_cnt == 8'd255) begin
		if (key_up && fsel != 3'd7) begin fsel <= fsel + 3'd1; prog_req <= 1'b1; end
		else if (key_dn && fsel != 3'd0) begin fsel <= fsel - 3'd1; prog_req <= 1'b1; end
		else if (key_en) begin auto <= !auto; minute <= 32'd0; end
		else if (auto && fail_new) begin
			auto <= 1'b0;
			if (fsel != 3'd0) begin fsel <= fsel - 3'd1; prog_req <= 1'b1; end
		end
		else if (auto) begin
			if (minute == 32'd2999999999) begin
				minute <= 32'd0;
				if (fsel != 3'd7) begin fsel <= fsel + 3'd1; prog_req <= 1'b1; end
				else auto <= 1'b0;
			end
			else minute <= minute + 32'd1;
		end
	end

	case (pst)
		P_IDLE:
			if (prog_req && rst_cnt == 8'd255 && dcm_locked) begin
				prog_req <= 1'b0;
				busy_f <= 1'b1;
				recfg <= 1'b1;
				minute <= 32'd0;
				pword <= { f_d(fsel) - 8'd1, 2'b01 };   // shifted out LSB first: 1, 0, then D-1
				pbit <= 4'd0;
				pnext_m <= 1'b1;
				pst <= P_LOADD;
			end
		P_LOADD, P_LOADM: begin
			progen <= 1'b1;
			progdata <= pword[0];
			pword <= { 1'b0, pword[9:1] };
			pbit <= pbit + 4'd1;
			if (pbit == 4'd9) begin
				pgap <= 8'd4;
				pst <= P_GAP;
			end
		end
		P_GAP:
			if (pgap != 8'd0) pgap <= pgap - 8'd1;
			else if (pnext_m) begin
				pnext_m <= 1'b0;
				pword <= { f_m(fsel) - 8'd1, 2'b11 };
				pbit <= 4'd0;
				pst <= P_LOADM;
			end
			else
				pst <= P_GO;
		P_GO: begin
			progen <= 1'b1;            // GO: PROGEN one cycle, PROGDATA 0
			pgap <= 8'd255;
			pst <= P_WAIT;
		end
		P_WAIT:
			if (pgap != 8'd0) pgap <= pgap - 8'd1;
			else if (progdone && dcm_locked) begin
				busy_f <= 1'b0;
				recfg <= 1'b0;
				pst <= P_IDLE;
			end
		default: pst <= P_IDLE;
	endcase
end

// the reset of the tester (clk): the PLL, the Reset item, a clock change
reg [2:0] rst_s = 3'b111;
always @(posedge clk) rst_s <= { rst_s[1:0], areset || kb_reset || busy_f || !dcm_locked };
wire rst_n = ~rst_s[2];

// ------------------------------------------------------------------ the tester

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

reg  [15:0] mins  = 0;
reg  [15:0] secs  = 0;
integer     min = 0, sec = 0;

always @(posedge clk_50) begin
    if(recfg || kb_reset) begin
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

	  .bg             (6'b000010  ),
	  .freq           (f_bcd(fsel)),              // the clock of the memory in MHz (BCD)
	  .elapsed        (mins       ),
	  .mark           (8'h80 >> {~auto, secs[2:0]}),
	  .hs             (hs         ),
	  .vs             (vs         ),
	  .de					(de			),
	  .b              (b          ),
	  .r              (r          ),
	  .g              (g          ));

// ------------------------------------------------------------------ OSD, HDMI

// the bitmap OSD of link v2 (kg_l2_osd_overlay): centred in de, 2 clocks of latency with its syncs
wire [23:0] osd_rgb;
wire osd_hs, osd_vs, osd_de;
kg_l2_osd_overlay osd (
	.wclk(clk_50),
	.osd_wr(osd_wr), .osd_waddr(osd_waddr), .osd_wdata(osd_wdata), .osd_en(osd_en),
	.osd_fg(osd_fg), .osd_bg(osd_bg), .osd_alpha(osd_alpha), .osd_px(osd_px), .osd_py(osd_py),
	.osd_pw(osd_pw), .osd_ph(osd_ph), .osd_place(osd_place), .osd_zoom(osd_zoom),
	.icon_on(8'd0), .icon_act(8'd0),
	.clk(clk_27),
	.rgb_i({r, 6'b0, g, 6'b0, b, 6'b0}), .hs_i(hs), .vs_i(vs), .de_i(de),
	.rgb_o(osd_rgb), .hs_o(osd_hs), .vs_o(osd_vs), .de_o(osd_de)
);

wire dvi_only_27;
kg_sync #(.W(1)) sync_dvi (.clk(clk_27), .d(dvi_only), .q(dvi_only_27));

// zhdmi of modules (its own x5 clocks from clk_27); no sound
zhdmi_top hdmi_top(
	.clk				(clk_27),
	.ds80				(1'b0),
	.reset			(areset),

	.vga_rgb			(osd_rgb),
	.vga_hs			(~osd_hs),
	.vga_vs			(~osd_vs),
	.vga_de			(osd_de),

	.audio_en		(~dvi_only_27),
	.audio_l			(16'd0),
	.audio_r			(16'd0),

	.tmds_p			(TMDS_P),
	.tmds_n			(TMDS_N)
);

endmodule
