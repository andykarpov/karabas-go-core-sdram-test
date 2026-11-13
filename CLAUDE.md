# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

An SDRAM test core for the Karabas Go, Mini and Mini G boards: Xilinx Spartan-6 XC6SLX25 (speed grade -2), ISE 14.7 (XST), Verilog with some VHDL. It writes and reads back the SDRAM in a loop and shows the pass / fail counters, the tester state and the elapsed time on screen. The README credits the original project to zebest, sorgelig, DDp and lvd. License: MIT (`LICENSE`).

Three tops: `src/rtl/karabas_go_top.v` (VGA through the video DAC, `VGA_R/G/B` 8 bits each from the 2-bit colors), `karabas_mini_top.v` and `karabas_minig_top.v` (HDMI through `rtl/hdmi/hdmi_top.v`). The ISE projects set the Verilog macro `HW_ID1` / `HW_ID2` / `HW_ID3`.

Mini G is on MCU link v2 (2026-11-13, build 26111321): `kg_mcu2`, `kg_l2_osd_overlay` and `zhdmi_top` of the `modules` submodule (karabas-go-modules, branch link-v2), the clock keys (below). Go and Mini still carry their own MCU link (`rtl/mcu/mcu.vhd`) and HDMI code until their pass.

## Layout

- `src/rtl/karabas_*_top.v`: PLL, `mem_tester`, the elapsed time counter, `vgaout`, `mcu`, HDMI on the Mini / Mini G.
- `src/rtl/common`: `mem_tester.v` (the test loop), `sdram_control.v`, `rnd_vec_gen.v` (the test data), `vgaout.v` (the results screen, 27 MHz in, 720x400@70 like timing), `sdram_test.v`, `resetter.v`.
- `src/rtl/pll/PLL_clock.v`: one PLL from CLK_50MHZ (VCO 700 MHz): clk 100 MHz (the tester), clk_27 (~26.9 MHz, video), sdram_clk 100 MHz (out to `SDR_CLK` through an ODDR2), clk_50.
- `src/rtl/hdmi`: `hdmi_top.v`, `hdmi_pll.v`, `pll_reset.v`, `dvi.vhd`, `dvi_encoder.vhd`, `hdmi_out_xilinx.vhd`.
- `src/rtl/mcu/mcu.vhd`, `src/rtl/spi`: the MCU link.

## Build

- `cd src && make minig` (`go`, `mini`, or all without a target): XST, map / par (Mini G `-t 3`), bitgen and the `.kg`, from `karabas_<board>_top.prj` / `.xst` / `.ut` and `karabas_<board>.ucf`. The `.xise` projects are gone (2026-11-13).
- Mini G clocks: the tester clock is a DCM_CLKGEN on `clk_50` of the PLL, M / D programmed over PROG from clk_50 (table of 8: 100..166 MHz, Up / Down, Enter auto mode as MiSTer MemTest); its timing is analysed at CLKFX_MD_MAX 3.34 (167 MHz). SDR_CLK = CLKFX180 through an ODDR2. The UCF has TIG between the tester clock, clk_27 (video) and clk_50.
- Pack with `make_core.py` (a symlink to `../../karabas-go-tools/make_core/make_core.py`, the sibling repo must be checked out next to this one) from `core.json` (one file for all boards: the common keys, `boards` for what differs; kgo2, karabas-go-tools `docs/kgo2.md`) into `src/sdrtest.kg` (`make_core.py core.json sdrtest.kg`, or `--boards <board>` for one board's bitstream). The `.bin` and `.kg` files are committed; the ISE outputs (`*.ncd`, `*.par`, `xst/`, `_ngo/`, ...) are in `.gitignore`.
- The json: id `sdrtest`, `"visible": false`, `"type": "none"`, no ROMs, `eeprom_bank` 0, OSD items Reset and Global Reset.

## MCU link

- `rtl/mcu/mcu.vhd` is a stripped copy: it decodes only CMD_SWITCHES (05), CMD_HW_SETUP (F9, the `DVI_ONLY` output), CMD_INIT_START / CMD_INIT_DONE (`BUSY`) and NOPE. No keyboard, mouse, joysticks, OSD, ROM loader or CMD_CAPS (no bursts).
- `SOFTSW_COMMAND` is not connected in the tops, so the OSD Reset items do nothing; `kb_reset` is declared but never driven. `DVI_ONLY` is wired out but not used.
- The ucf have only `TS_CLK_MCU` (30 MHz) as a timing constraint.

## Gotchas

- The SDRAM chip select is driven on the `FLASH_CS_N` port (pin T3, `/CONF_CS` in the ucf): see the `DRAM_CS_N` comment in the tops.
- The chip is an MT48LC16M16A2-75; the tops set its geometry (`DRAM_COL_SIZE` 9, `DRAM_ROW_SIZE` 13). The last commits lowered the SDRAM clock to 100 MHz for the slower -75 chips; `vgaout` gets `freq` 16'h0100 to print it.
- The release repos do not carry `sdrtest.kg*` (only `cores/test.kg` of the other test core).

## Memory

The Claude Code memory of this repo is shared with all karabas-go repos: `~/.claude/projects/<this project>/memory` is a symlink to `../karabas-go-notes` (private repo `andykarpov/karabas-go-notes`, `link.sh` there makes the links). Its `MEMORY.md` is split by repo; commit and push it after every memory change.
