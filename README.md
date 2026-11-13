# SDRAM test core for Karabas Go / Mini / Mini G

[Русская версия](README.ru.md)

A test of the SDRAM of the Karabas Go family boards (Xilinx Spartan-6 XC6SLX25, the SDRAM chip
MT48LC16M16A2-75, 32 MB). The core writes the whole chip with pseudo-random data, reads it back and
compares, in a loop, and shows the result on the screen. One core file `sdrtest.kg` for all three
boards; it is hidden in the boot menu (`"visible": false`), load it by name (`sdrtest`).

Original project by zebest, sorgelig, DDp and lvd (the MemTest of MiSTer); the frequency keys follow
that MemTest.

## The screen

- Top line (yellow): the elapsed time in minutes and the SDRAM clock in MHz.
- Middle line (green): the passes, hexadecimal. A pass is one write and read of the whole chip.
- Bottom line (red): the errors, hexadecimal. Any value other than 0 means the memory failed at this
  clock.
- The marker that moves once a second shows the auto mode (below).

## The keys

| Key | What it does |
|---|---|
| Up / Down | The next / previous SDRAM clock: 100, 110, 120, 130, 140, 150, 160, 166 MHz |
| Enter | Auto mode on / off: after each minute with no errors the clock goes one step up; an error takes it one step down and ends auto mode |
| OSD Reset | Starts the test again |
| OSD Global Reset | Back to the boot core |

A change of the clock starts the test again: the passes, the errors and the time go to 0.

The SDRAM chip is rated for 133 MHz: errors at 150 MHz and up are normal and show the margin of a
board, not a fault. A board with errors at 100 MHz has a problem (the chip, its soldering, the power).

## Boards

- All three boards: MCU link v2 (`kg_mcu2`, firmware 26111315 or later), the OSD of
  [karabas-go-modules](https://github.com/andykarpov/karabas-go-modules) and the clock keys. The
  tester clock comes from a DCM_CLKGEN of the FPGA, programmed at run time (CLKFX = 50 MHz x M / D);
  the SDRAM gets it inverted, as with the PLL before. Mini G and Mini: HDMI; Go: VGA.
- Builds: Mini G 26111321 (checked on the board), Mini and Go 26111327 (not run on a board yet).

## Build

ISE 14.7: `cd src && make minig` (or `go`, `mini`, or `make` for all three). The result: the
`karabas_<board>_top.bin` bitstreams and `sdrtest.kg` (packed by `make_core.py` from `core.json`).
The shared modules are the `modules` submodule (karabas-go-modules): `git submodule update --init`.

## License

MIT, see [LICENSE](LICENSE).
