#!/usr/bin/env python3
"""Makes rtl/karabas_mini_top.v and rtl/karabas_go_top.v from rtl/karabas_minig_top.v (link v2).

The tester, the clock keys (DCM_CLKGEN), kg_mcu2 and the OSD are the same on the three boards; the
header and ports come from the last v1 tops (V1_REF), the pin glue differs:
Mini (before rev.G): MCU_IO of 4 bits (INT on MCU_IO[1]), no I2S DAC (AUDIO_L / AUDIO_R 0), ESP /
  FT_RESET / MIDI pins inactive; HDMI as Mini G.
Go: INT on MCU_SPI_IO[0] (N9), the FT / SD2 selects on MCU_SPI_*_CS_N, VGA 2:2:2 of vgaout (with the
  OSD) and V_CLK instead of HDMI, no FT_CLK_OUT, the floppy outputs and the DAC idle.
Every replacement must match once, else this stops.
"""
import os
import subprocess
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
RTL = os.path.join(SRC, "rtl")
V1_REF = "abba1c6"  # master before link v2


def sub(s, old, new, what):
    if s.count(old) != 1:
        sys.exit("mktops.py: %s: %d matches of %r" % (what, s.count(old), old[:70]))
    return s.replace(old, new)


def v1(board):
    return subprocess.check_output(["git", "show", "%s:src/rtl/karabas_%s_top.v" % (V1_REF, board)],
                                   cwd=SRC).decode()


def head(s):
    i = s.index("module karabas_")
    return s[:s.index("\n);\n", i) + 4]


def body(s):
    i = s.index("module karabas_")
    return s[s.index("\n);\n", i) + 4:]


DAC_G = "assign DAC_BCK = 1'b0;\nassign DAC_WS = 1'b0;\nassign DAC_DAT = 1'b0;\n"
ADC_G = "assign ADC_CLK = 1'b0;\nassign ADC_BCK = 1'b0;\nassign ADC_LRCK = 1'b0;\n"
MCU_IO_G = "assign MCU_IO[1] = mcu_int;\nassign MCU_IO[0] = 1'bz;\nassign MCU_IO[5:2] = 4'bzzzz;"

minig = open(os.path.join(RTL, "karabas_minig_top.v")).read()
b = body(minig)
# MCU_SCK is not on a clock pin before rev.G and on Go: no IBUFG / BUFG
b = sub(b, """// MCU_SCK on a global buffer
wire mcu_sck_ibufg, mcu_sck;
IBUFG ibufg_mcu_sck (.I(MCU_SCK), .O(mcu_sck_ibufg));
BUFG bufg_mcu_sck (.I(mcu_sck_ibufg), .O(mcu_sck));""", """// MCU_SCK is not on a clock pin on this board (CLOCK_DEDICATED_ROUTE = FALSE in the ucf)
wire mcu_sck = MCU_SCK, mcu_sck_ibufg = MCU_SCK;""", "mcu_sck")

# ---------------------------------------------------------------- Mini
m = b
m = sub(m, DAC_G, "assign AUDIO_L = 1'b0;\nassign AUDIO_R = 1'b0;\nassign FT_RESET = 1'b1;\n", "mini dac")
m = sub(m, "assign ESP32_SPI_CS_N = 1'b1;\n", "assign ESP_RESET_N = 1'bZ;\nassign ESP_BOOT_N = 1'bZ;\n"
        "assign MIDI_CLK = 1'b0;\nassign MIDI_RESET_N = 1'b1;\n", "mini esp")
m = sub(m, MCU_IO_G, "assign MCU_IO[1] = mcu_int;\nassign MCU_IO[0] = 1'bz;\nassign MCU_IO[3:2] = 2'bzz;", "mini mcu_io")
h = head(v1("mini"))
h = sub(h, "	input wire [3:0] 		MCU_IO,", "	inout wire [3:0] 		MCU_IO,   // [1] INT of link v2, [2] sd2 cs_n, [3] ft cs_n", "mini port")
mini = h + "// karabas: made by src/tools/mktops.py from karabas_minig_top.v (do not edit it, change Mini G)\n" + m

# ---------------------------------------------------------------- Go
g = b
g = sub(g, DAC_G + ADC_G + "assign ESP32_SPI_CS_N = 1'b1;\n", """assign DAC_BCK = 1'b0;
assign DAC_LRCK = 1'b0;
assign DAC_DAT = 1'b0;
assign DAC_MUTE = 1'b0; // 0 = mute
assign ESP_RESET_N = 1'bZ;
assign ESP_BOOT_N = 1'bZ;
assign BEEPER = 1'b0;
assign UART_CTS = 1'b0;
assign FT_OE_N = 1'b1;
assign MIDI_CLK = 1'b0;
assign MIDI_RESET_N = 1'b1;
assign FDC_DRIVE = 2'b00;
assign FDC_MOTOR = 1'b0;
assign FDC_SIDE_N = 1'b1;
assign FDC_WDATA = 1'b1;
assign FDC_WGATE = 1'b1;
assign FDC_STEP = 1'b1;
assign FDC_DIR = 1'b1;
""", "go pins")
g = sub(g, "assign MWR_N			= 1'b1;\nassign MRD_N			= 1'b1;", "assign MWR_N			= 2'b11;\nassign MRD_N			= 2'b11;", "go sram")
g = sub(g, "assign WCS_N			= 1'b1;", "assign WCS_N			= 2'b11;", "go wcs")
i = g.index("// the clock of the FT812: 50 / 6")
j = g.index("assign FT_CLK_OUT = ft_clk;\n") + len("assign FT_CLK_OUT = ft_clk;\n")
g = g[:i] + "// Go has no FT_CLK_OUT\n" + g[j:]
g = sub(g, MCU_IO_G, "// Go: INT on MCU_SPI_IO[0] (N9, the IO1 line of the firmware)\nassign MCU_SPI_IO[0] = mcu_int;\nassign MCU_SPI_IO[1] = 1'bz;", "go mcu_io")
g = sub(g, ".MCU_SPI_FT_SS(MCU_IO[3]),", ".MCU_SPI_FT_SS(MCU_SPI_FT_CS_N),", "go ft ss")
g = sub(g, ".MCU_SPI_SD2_SS(MCU_IO[2]),", ".MCU_SPI_SD2_SS(MCU_SPI_SD2_CS_N),", "go sd2 ss")
i = g.index("wire dvi_only_27;")
j = g.index(");", g.index("zhdmi_top hdmi_top(")) + 2
g = g[:i] + """// VGA through the video DAC (no HDMI on Go)
assign VGA_R = osd_rgb[23:16];
assign VGA_G = osd_rgb[15:8];
assign VGA_B = osd_rgb[7:0];
assign VGA_HS = osd_hs;
assign VGA_VS = osd_vs;
ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) ODDR2_vclk (
	.Q(V_CLK), .C0(clk_27), .C1(!clk_27), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));""" + g[j:]
go = head(v1("go"))
go += "// karabas: made by src/tools/mktops.py from karabas_minig_top.v (do not edit it, change Mini G)\n" + g

open(os.path.join(RTL, "karabas_mini_top.v"), "w").write(mini)
open(os.path.join(RTL, "karabas_go_top.v"), "w").write(go)
print("mktops.py: karabas_mini_top.v, karabas_go_top.v")
