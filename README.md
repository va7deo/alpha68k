
# Alpha Denshi 68K (Sky Adventure) FPGA Implementation

FPGA compatible core of Alpha Denshi M68000 (ALPHA68K96V based) arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). FPGA implementation has been verified against schematics for Sky Adventure. PCB measurements taken from Gang Wars (ALPHA-68K96V) and Sky Soldiers (ALPHA-96KII).

Sky Adventure (bootleg) PCB purchased by [**Darren Olafson**](https://twitter.com/Darren__O) / [**atrac17**](https://github.com/atrac17). Gang Wars, Sky Soldiers, and The Next Space (authentic) PCBs purchased by [**atrac17**](https://github.com/atrac17).  The intent is for this core to be a 1:1 playable implementation of Alpha Denshi M68000 arcade hardware. Currently in **beta state**, this core is in active development with assistance from [**atrac17**](https://github.com/atrac17).

<br>
<p align="center">
<img width="" height="" src="FILLME">
</p>

## Supported Games

| Title | PCB<br>Number | Status  | Released | ROM Set  |
|-------|---------------|---------|----------|----------|
| [**Gang Wars**](https://en.wikipedia.org/wiki/Gang_Wars_(video_game))              | ALPHA-68K96V (GW)  | Implemented | Yes | .249 merged           |
| [**Super Champion Baseball**](https://snk.fandom.com/wiki/Super_Champion_Baseball) | ALPHA-68K96V (GW)  | Implemented | Yes | .249 (sbasebalj only) |
| [**Sky Adventure**](https://snk.fandom.com/wiki/Sky_Adventure)                     | ALPHA-68K96V (GW)  | Implemented | Yes | .249 merged           |

| Title | PCB<br>Number | Status  | Released | ROM Set  |
|-------|---------------|---------|----------|----------|
| [**Battle Field (バトル フィールド)**](https://en.wikipedia.org/wiki/Time_Soldiers) <br> Time Soldiers | ALPHA-68K96II (SS) | W.I.P | No  | N/A |
| [**Sky Soldiers*](https://en.wikipedia.org/wiki/Sky_Soldiers)                                       | ALPHA-68K96II (SS) | W.I.P | No | N/A |
| [**Gold Medalist**](https://snk.fandom.com/wiki/Gold_Medalist)                                      | ALPHA-68K96II (SS) | W.I.P | No | N/A |

| Title | PCB<br>Number | Status  | Released | ROM Set  |
|-------|---------------|---------|----------|----------|
| [**Paddle Mania**](https://snk.fandom.com/wiki/Paddle_Mania)     | ALPHA-68K96I | W.I.P | No | N/A |
| [**The Next Space**](https://snk.fandom.com/wiki/The_Next_Space) | A8004-1      | W.I.P | No | N/A |

| Title | PCB<br>Number | Status  | Released | ROM Set  |
|-------|---------------|---------|----------|----------|
| [**Super Stingray**](https://segaretro.org/Super_Stingray)               | N/A          | W.I.P | No | N/A |
| [**Kyros no Yakata**](http://www.hardcoregaming101.net/kyros-desolator/) | N/A          | W.I.P | No | N/A |
| [**Mahjong Block Jongbou**](https://snk.fandom.com/wiki/Jongbou)         | ALPHA-68K96N | W.I.P | No | N/A |

## External Modules

|Name| Purpose | Author |
|----|---------|--------|
| [**fx68k**](https://github.com/ijor/fx68k)     | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000)   | Jorge Cwik     |
| [**t80**](https://opencores.org/projects/t80)  | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)        | Daniel Wallner |
| [**jt2413**](https://github.com/jotego/jtopl)  | [**Yamaha OPL-L**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)  | Jose Tejada    |
| [**jt03**](https://github.com/jotego/jt12)     | [**Yamaha OPN**](https://en.wikipedia.org/wiki/Yamaha_YM2203)    | Jose Tejada    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)  | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone    |

# Known Issues / Tasks

- 

# PCB Check List

<br>

FPGA implementation has been verified against [**schematics**](FILLME) for Sky Adventure. PCB measurements taken from Gang Wars (ALPHA-68K96V).

### Clock Information

H-Sync      | V-Sync      | Source   | PCB<br>Number  |
------------|-------------|----------|----------------|
15.625kHz   | 59.185606Hz | [**DSLogic+**](FILLME) | ALPHA-68K96V (GW) |

### Crystal Oscillators

Location               | PCB<br>Number     | Freq (MHz) | Use                                 |
-----------------------|-------------------|------------|-------------------------------------|
X-1  (24MHZ)           | ALPHA-68K96V (GW) | 24.000     | Z80 / YM2203 / Sprite / Pixel Clock |
X-2  (20MHZ)           | ALPHA-68K96V (GW) | 20.000     | M68000                              |
X-3  (3.579545MHz)     | ALPHA-68K96V (GW) | 3.579545   | YM2413 Clock                        |

**Pixel clock:** 6.00 MHz

**Estimated geometry:**

    383 pixels/line
  
    263 pixels/line

### Main Components

Location | PCB<br>Number | Chip | Use |
---------|---------------|------|-----|
68000D  | ALPHA-68K96V (GW) | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000)   | Main CPU      |
Z80B    | ALPHA-68K96V (GW) | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)             | Sound CPU     |
YM2203   | ALPHA-68K96V (GW) | [**Yamaha YM2203**](https://en.wikipedia.org/wiki/Yamaha_YM2203)        | OPN           |
YM2413   | ALPHA-68K96V (GW) | [**Yamaha YM2413**](https://en.wikipedia.org/wiki/Yamaha_YM2413)        | OPL-L         |

### Custom Components

Location | PCB<br>Number | Chip | Use |
---------|---------------|------|-----|
SP85 / ALPHA-8511 / M68705 | ALPHA-68K96V (GW) / ALPHA-68K96II (SS) | [**SP85N**](FILLME)          | Coin / Dipswitch / Screen Inversion Handling    |
SNKCLK                     | ALPHA-68K96V (GW)                      | [**SNK CLK**](FILLME)        | Counter           |
INPUT 84                   | ALPHA-68K96II                          | [**ALPHA-INPUT 84**](FILLME) | Rotary Handling   |
INPUT 87                   | ALPHA-68K96V (GW)                      | [**ALPHA-INPUT 87**](FILLME) | Input Handling    |
ALPHA-8921                 | ALPHA-68K96V (GW)                      | [**ALPHA-8921**](FILLME)     | GFX Muxing        |

# Core Features

### Rotary Joystick Support

- Rotary control is supported via gamepad or firmware written by [**atrac17**](https://github.com/atrac17) / [**DJ Hard Rich**](https://twitter.com/djhardrich) for [**LS-30 functionality using an RP2040**](FILLME). Latency verification done by [**misteraddons**](https://github.com/misteraddons), for more information click [**here**](https://rpubs.com/misteraddons/inputlatency).

<br>

Model | Device | Connection | USB Polling<br>Interval | Sample<br>Number | Frame<br>Probability | Average<br>Latency | Joystick ID |
------|--------|------------|-------------------------|------------------|----------------------|--------------------|-------------|
LS-30 Rotary Encoder | RP2040 | Wired USB | 1ms | 2241 | 95.52% | 0.747 ms | 2e8a:000a |

<br>

### Native Y/C Output

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments

- There are two H/V toggles, H/V-sync positioning adjust and H/V-sync width adjust. Positioning will move the display for centering on CRT display. The sync width adjust can be used to for sync issues (rolling) without modifying the video timings.

### Scandoubler Options

- Additional toggle to enable the scandoubler without changing ini settings and new scanline option for 100% is available, this draws a black line every other frame. Below is an example.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="128" height="112" src="FILL ME"></td><td><br> <p align="center"><img width="128" height="112" src="FILL ME"></td><td><br> <p align="center"><img width="128" height="112" src="FILL ME"></td><td><br> <p align="center"><img width="128" height="112" src="FILL ME"></td><td><br> <p align="center"><img width="128" height="112" src="FILL ME"></td></tr></table>

# Controls

<br>

- Service menu is accessed by holding the F2 key on boot. The core may need to be reset by pressing F3 while holding F2 to access the service menu.

<br>

<table><tr><th>Game</th><th>Joystick</th><th>Service Menu</th><th>Control Type</th></tr><tr><td><p align="center">Gang Wars</p></td><td><p align="center">8-Way</p></td><td><p align="center"><br><img width="128" height="112" src="FILL ME"></td><td><p align="center">Co-Op</td><tr><td><p align="center">Sky Adventure</p></td><td><p align="center">8-Way</p></td><td><p align="center"><br><img width="128" height="112" src="FILL ME"></td><td><p align="center">Co-Op</td><tr><td><p align="center">Super Champion<br>Baseball</p></td><td><p align="center">8-Way</p></td><td><p align="center"><br><img width="128" height="112" src="FILL ME"></td><td><p align="center">Co-Op</td> </table>

<br>

### Rotary Joystick Support

- Rotary control is supported via gamepad or firmware written by [**atrac17**](https://github.com/atrac17) / [**DJ Hard Rich**](https://twitter.com/djhardrich) for LS-30 functionality using an RP2040. There are toggles in the OSD under Debug Settings to select the rotary controller type per player. <br><br> When using a gamepad, enabling autofire and setting to 160ms for Rotate CW/CCW in the MiSTer framework allows for smooth rotation; adjust the rate to fit your preference. LS-30 firmware requires no mapping and is plug and play; it is player dependent and connected over USB to the DE10-Nano.

<br>

### Keyboard Handler

- Keyboard inputs mapped to mame defaults for the following functions.

<br>

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-Ctrl</td></tr><tr><td>P1 Bttn 2</td><td>L-Alt</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>|

<br>

- Custom keyboard inputs mapped for LS-30 RP2040 firmware functionality. The mapping is player dependent for the RP2040 firmware.

<br>

|LS-30 Player 1|LS-30 Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Rotary 1</td><td>Y</td></tr><tr><td>P1 Rotary 2</td><td>U</td></tr><tr><td>P1 Rotary 3</td><td>I</td></tr><tr><td>P1 Rotary 4</td><td>O</td></tr><tr><td>P1 Rotary 5</td><td>H</td></tr><tr><td>P1 Rotary 6</td><td>J</td></tr><tr><td>P1 Rotary 7</td><td>K</td></tr><tr><td>P1 Rotary 8</td><td>L</td></tr><tr><td>P1 Rotary 9</td><td>N</td></tr><tr><td>P1 Rotary 10</td><td>M</td></tr><tr><td>P1 Rotary 11</td><td>,</td></tr><tr><td>P1 Rotary 12</td><td>.</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Rotary 1</td><td>Z</td></tr><tr><td>P2 Rotary 2</td><td>X</td></tr><tr><td>P2 Rotary 3</td><td>C</td></tr><tr><td>P2 Rotary 4</td><td>V</td></tr><tr><td>P2 Rotary 5</td><td>B</td></tr><tr><td>P2 Rotary 6</td><td>W</td></tr><tr><td>P2 Rotary 7</td><td>E</td></tr><tr><td>P2 Rotary 8</td><td>T</td></tr><tr><td>P2 Rotary 9</td><td>3</td></tr><tr><td>P2 Rotary 10</td><td>4</td></tr><tr><td>P2 Rotary 11</td><td>7</td></tr><tr><td>P2 Rotary 12</td><td>8</td></tr> </table>|

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
