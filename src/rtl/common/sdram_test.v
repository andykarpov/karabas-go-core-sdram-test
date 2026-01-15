//-----------------------------------------------------------------------------
// History
// Первая версия для TerasicDE1 от lvd 15.09.2008 http://dlcorp.nedopc.com/viewtopic.php?f=21&t=254&start=0
// Вторая версия для Speccy2010 от DDp 08.12.2013 https://zx-pk.ru/threads/12425-speccy2010-sborka-naladka-testing.html?p=650090&viewfull=1#post650090
// Третья версия для MiSTer от Sorgelig и следующие ревизии 2017-2020 гг
// Моя версия для ZXDOS+ 04.04.2021
//-----------------------------------------------------------------------------

//Max
//`define MEM_SIZE_32M                                // uncomment for K4S561632, else (for K4S281632) comment it
`define MEM_SIZE_64M                                // uncomment for K4S561632, else (for K4S281632) comment it

module sdram_test (

 input wire         clock_50,

 output wire [5:0]  vga_r,
 output wire [5:0]  vga_g,
 output wire [5:0]  vga_b,
 output wire        vga_hs,
 output wire        vga_vs,
 
 input  wire [1:0]  keyb,
 // SD-RAM ports
 output wire        DRAM_CLK,                       // SD-RAM Clock
 output wire        DRAM_CKE,                       // SD-RAM Clock enable
 output wire        DRAM_CS_N,                      // SD-RAM Chip select
 output wire        DRAM_RAS_N,                     // SD-RAM Row/RAS
 output wire        DRAM_CAS_N,                     // SD-RAM /CAS
 output wire        DRAM_WE_N,                      // SD-RAM /WE
 output wire        DRAM_UDQM,                      // SD-RAM UDQM
 output wire        DRAM_LDQM,                      // SD-RAM LDQM
 output wire        DRAM_BA_1,                      // SD-RAM Bank select address 1
 output wire        DRAM_BA_0,                      // SD-RAM Bank select address 0
 output wire [12:0] DRAM_ADDR,                      // SD-RAM Address
 inout  wire [15:0] DRAM_DQ );                      // SD-RAM Data

//-----------------------------------------------------------------------------

//Max
`ifdef MEM_SIZE_64M
 parameter DRAM_COL_SIZE = 10;
 parameter DRAM_ROW_SIZE = 13;
`elsif MEM_SIZE_32M
 parameter DRAM_COL_SIZE = 9;
 parameter DRAM_ROW_SIZE = 13;
`else
 assign DRAM_ADDR[12] = 1'b0;
 parameter DRAM_COL_SIZE = 9;
 parameter DRAM_ROW_SIZE = 12;
`endif

//-----------------------------------------------------------------------------

 wire RESET_n;                                      // 090 MHz - 20
 wire clk, sdram_clk, clk_27, locked;               // 100 Mhz - 60
                                                    // 120 MHz - 100
 PLL_clock my_pll (                                 // 140 MHz - 140
        .CLK_IN1        (clock_50   ),              // 150 MHz - 200 phase
        .CLK_OUT1       (clk        ),              // 155 MHz - 220 phase
        .CLK_OUT2       (clk_27     ),              // 160 MHz - 240 phase
        .CLK_OUT3       (sdram_clk  ),              // 166 MHz - 260 phase  - (240 phase - bad)
        .CLK_OUT4       (clk_50     ),              // 175 MHz - 280\300 phase  -  bad
        .LOCKED         (locked     ));             // 110 MHz - 80, 115 MHz - 90

//-----------------------------------------------------------------------------

 assign DRAM_CLK = sdram_clk;
 assign DRAM_CKE = 1'b1;
 assign RESET_n  = 1'b1;

 wire rst_n;
 defparam my_reset.RST_CNT_SIZE = 16;

 resetter my_reset(
        .clk            (clk        ),
        .rst_in_n       (RESET_n & locked ),
        .rst_out_n      (rst_n      ));

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
        .DRAM_DQ        (DRAM_DQ    ),
        .DRAM_ADDR      (DRAM_ADDR[DRAM_ROW_SIZE-1:0]),
        .DRAM_LDQM      (DRAM_LDQM  ),
        .DRAM_UDQM      (DRAM_UDQM  ),
        .DRAM_WE_N      (DRAM_WE_N  ),
        .DRAM_CS_N      (DRAM_CS_N  ),
        .DRAM_RAS_N     (DRAM_RAS_N ),
        .DRAM_CAS_N     (DRAM_CAS_N ),
        .DRAM_BA_0      (DRAM_BA_0  ),
        .DRAM_BA_1      (DRAM_BA_1  ));

//-----------------------------------------------------------------------------

reg  [ 5:0] pos   = 0;
reg  [15:0] mins  = 0;
reg  [15:0] secs  = 0;
reg         auto  = 0;
reg         recfg = 0;
    integer   min = 0, sec = 0;

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

//-----------------------------------------------------------------------------
 wire hs, vs;
 wire [1:0] b, r, g;

 vgaout showrez(
        .clk            (clk_27     ),
        .rez1           (passcount  ),
        .rez2           (failcount  ),
        .rez3           ({2'b00,mmtst_state}),

        .bg             (6'b000010  ),					 // color fon?
        .freq           (16'h0140   ),              // clock memory: 166 MHz (HEX)
        .elapsed        (mins       ),
        .mark           (8'h80 >> {~auto, secs[2:0]}),
        .hs             (hs         ),
        .vs             (vs         ),
        .b              (b          ),
        .r              (r          ),
        .g              (g          ));

 assign vga_hs = ~hs;
 assign vga_vs = ~vs;
 assign vga_r  = {6{r}};
 assign vga_g  = {6{g}};
 assign vga_b  = {6{b}};
 
 //-------------------------------------------------------------------------------------------------

//BUFG Bufg(.I(videoclk), .O(clockmb));

multiboot Multiboot (
        .clock          (clk_27     ),
        .reboot         (keyF11     ));
	 
//-------------------------------------------------------------------------------------------------

keyboard Keyboard (
	     .clock          (clk_27     ),
	     .ce             (1'b1       ),
	     .ps2            (keyb       ),
        .f11            (keyF11     ));

//-------------------------------------------------------------------------------------------------
endmodule

//-----------------------------------------------------------------------------
