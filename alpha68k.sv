//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

`default_nettype none

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output        CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,    // = ~(VBlank | HBlank)
    output        VGA_F1,
    output [2:0]  VGA_SL,
    output        VGA_SCALER, // Force VGA scaler

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef MISTER_FB
    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output  [4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output  [7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output  [1:0] BUTTONS,

    input         CLK_AUDIO, // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout   [3:0] ADC_BUS,

    //SD-SPI
    output        SD_SCK,
    output        SD_MOSI,
    input         SD_MISO,
    output        SD_CS,
    input         SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output  [1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input         UART_CTS,
    output        UART_RTS,
    input         UART_RXD,
    output        UART_TXD,
    output        UART_DTR,
    input         UART_DSR,

`ifdef MISTER_ENABLE_YC
	output [39:0] CHROMA_PHASE_INC,
	output        YC_EN,
	output        PALFLAG,
`endif
    
    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT,

    input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_MIX = 0;
assign LED_USER =  0 ;// | { frame_count, global_count, rom_count, rom_2_count, sprite_count, sound_count, sprite_overrun, sp_count } ;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

assign m68k_a[0] = 0;

// Status Bit Map:
//              Upper Case                     Lower Case           
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X   XXXXXX        XXXXX XXXXXXXX      XX                         

wire [1:0]  aspect_ratio = status[9:8];
wire        orientation = ~status[3];
wire [2:0]  scan_lines = status[6:4];

wire [3:0]  hs_offset = status[27:24];
wire [3:0]  vs_offset = status[31:28];
wire [3:0]  hs_width  = status[59:56];
wire [3:0]  vs_width  = status[63:60];

wire kill_laugh = status[37];

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd8 : 8'd7) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd7 : 8'd8) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
    "Alpha68k;;",
    "-;",
    "P1,Video Settings;",
    "P1-;",
    "P1O89,Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
    "P1O3,Orientation,Horz,Vert;",
    "P1-;",
    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%,CRT 100%;",
    "P1OA,Force Scandoubler,Off,On;",
    "P1-;",
    "P1O7,Video Mode,NTSC,PAL;",
    "P1OM,Video Signal,RGBS/YPbPr,Y/C;",
    "P1-;",
    "P1OOR,H-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1OSV,V-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P1oOR,H-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1oSV,V-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P2,Pause Options;",
    "P2-;",
    "P2OK,Pause when OSD is open,Off,On;",
    "P2OL,Dim video after 10s,Off,On;",
    "-;",
    "P3,Debug Settings;",
    "P3-;",
    "P3o6,Swap P1/P2 Joystick,Off,On;",
    "P3OI,P1 Rotary Type,Gamepad,LS-30;",
    "P3OJ,P2 Rotary Type,Gamepad,LS-30;",
    "P3o5,GangWars Enemy Laugh,On,Off;",
    "P3-;",
    "DIP;",
    "-;",
    "R0,Reset;",
    "J1,Button 1,Button 2,Button 3,Start,Coin,Pause;",
    "jn,A,B,X,R,L,Start;",           // name mapping
    "V,v",`BUILD_DATE
};


wire hps_forced_scandoubler;
wire forced_scandoubler = hps_forced_scandoubler | status[10];

wire  [1:0] buttons;
wire [63:0] status;
wire [10:0] ps2_key;
wire [15:0] joy0, joy1, joy2, joy3;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .buttons(buttons),
    .ps2_key(ps2_key),
    .status(status),
    .status_menumask(direct_video),
    .forced_scandoubler(hps_forced_scandoubler),
    .gamma_bus(gamma_bus),
    .direct_video(direct_video),
    .video_rotated(video_rotated),
    
    .ioctl_download(ioctl_download),
    .ioctl_upload(ioctl_upload),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_din(ioctl_din),
    .ioctl_index(ioctl_index),
    .ioctl_wait(ioctl_wait),

    .joystick_0(joy0),
    .joystick_1(joy1),
    .joystick_2(joy2),
    .joystick_3(joy3)
);

// INPUT

// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end

wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

reg   [3:0]   pcb;

always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==1)) begin
        pcb <= ioctl_dout;
    end
end

wire [21:0] gamma_bus;

//<buttons names="Fire,Jump,Start,Coin,Pause" default="A,B,R,L,Start" />
reg [7:0] p1;
reg [7:0] p2;
reg [3:0] p3;
reg [3:0] p4;
reg [15:0] dsw1;
reg [15:0] dsw2;
reg [15:0] coin;
reg flip_dip ;

//reg invert_input;
//wire [7:0] invert_mask = { 8 {invert_input} } ;

always @ (posedge clk_sys ) begin 
    p1   <=  ~{ start1, p1_buttons[2:0], p1_right, p1_left, p1_down, p1_up} ;
    
    p2   <=  ~{ start2, p2_buttons[2:0], p2_right, p2_left, p2_down, p2_up} ;
    
    coin <=  ~{ 2'b0, coin_b, coin_a, 2'b0, ~key_test, ~key_service } ;
    
    dsw1 <=  {8'h00, sw[0][7:2], ~key_test,~key_service };  // 
    dsw2 <=  {8'h00, sw[1][7:0] };  // sw[1][1:0] not used? debugging
    
    flip_dip <= ~dsw2[4] ;

end

wire        p1_right;
wire        p1_left;
wire        p1_down;
wire        p1_up;
wire [2:0]  p1_buttons;

wire        p2_right;
wire        p2_left;
wire        p2_down;
wire        p2_up;
wire [2:0]  p2_buttons;

wire [2:0]  p3_buttons;

wire [2:0]  p4_buttons;

reg         p1_swap;

always @ * begin
    p1_right   <= joy0[0] | key_p1_right;
    p1_left    <= joy0[1] | key_p1_left;
    p1_down    <= joy0[2] | key_p1_down;
    p1_up      <= joy0[3] | key_p1_up;
    p1_buttons <= joy0[6:4] | {key_p1_c, key_p1_b, key_p1_a};

    p2_right   <= joy1[0] | key_p2_right;
    p2_left    <= joy1[1] | key_p2_left;
    p2_down    <= joy1[2] | key_p2_down;
    p2_up      <= joy1[3] | key_p2_up;
    p2_buttons <= joy1[6:4] | {key_p2_c, key_p2_b, key_p2_a};

    p3_buttons <= joy2[6:4];

    p4_buttons <= joy3[6:4];
end

wire        start1  = joy0[7]  | joy1[7]  | key_start_1p;
wire        start2  = joy0[8]  | joy1[8]  | key_start_2p;
wire        start3  = joy2[7]  | key_start_3p;
wire        start4  = joy3[8]  | key_start_4p;
wire        coin_a  = joy0[9]  | joy1[9]  | key_coin_a;
wire        coin_b  = joy0[10] | joy1[10] | key_coin_b;
wire        b_pause = joy0[11] | key_pause;
wire        service = joy0[12] | key_test;

// Keyboard handler

wire key_start_1p, key_start_2p, key_start_3p, key_start_4p, key_coin_a, key_coin_b;
wire key_tilt, key_test, key_reset, key_service, key_pause;
//wire key_fg_enable, key_spr_enable;

wire key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c, key_p1_d;
wire key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c, key_p2_d;

wire pressed = ps2_key[9];

reg [11:0] key_ls30_p1;
reg [11:0] key_ls30_p2;

always @(posedge clk_sys) begin 
    reg old_state;

    old_state <= ps2_key[10];
    if(old_state ^ ps2_key[10]) begin
        casex(ps2_key[8:0])
            'h016: key_start_1p   <= pressed; // 1
            'h01e: key_start_2p   <= pressed; // 2
            'h02E: key_coin_a     <= pressed; // 5
            'h036: key_coin_b     <= pressed; // 6
            'h006: key_test       <= pressed; // f2
            'h004: key_reset      <= pressed; // f3
            'h046: key_service    <= pressed; // 9
            'h02c: key_tilt       <= pressed; // t
            'h04D: key_pause      <= pressed; // p

            'hX75: key_p1_up      <= pressed; // up
            'hX72: key_p1_down    <= pressed; // down
            'hX6b: key_p1_left    <= pressed; // left
            'hX74: key_p1_right   <= pressed; // right
            'h014: key_p1_a       <= pressed; // lctrl
            'h011: key_p1_b       <= pressed; // lalt
            'h029: key_p1_c       <= pressed; // spacebar
            'h012: key_p1_d       <= pressed; // lshift

            'h02d: key_p2_up      <= pressed; // r
            'h02b: key_p2_down    <= pressed; // f
            'h023: key_p2_left    <= pressed; // d
            'h034: key_p2_right   <= pressed; // g
            'h01c: key_p2_a       <= pressed; // a
            'h01b: key_p2_b       <= pressed; // s
            'h015: key_p2_c       <= pressed; // q
            'h01d: key_p2_d       <= pressed; // w

            'h026: key_start_3p   <= pressed; // 3
            'h025: key_start_4p   <= pressed; // 4

            // Rotary1 LS-30 P1 Scancodes
            'h035: key_ls30_p1[0]  <= pressed; // y
            'h03c: key_ls30_p1[1]  <= pressed; // u
            'h043: key_ls30_p1[2]  <= pressed; // i
            'h044: key_ls30_p1[3]  <= pressed; // o
            'h033: key_ls30_p1[4]  <= pressed; // h
            'h03b: key_ls30_p1[5]  <= pressed; // j
            'h042: key_ls30_p1[6]  <= pressed; // k
            'h04b: key_ls30_p1[7]  <= pressed; // l
            'h031: key_ls30_p1[8]  <= pressed; // n
            'h03a: key_ls30_p1[9]  <= pressed; // m
            'h041: key_ls30_p1[10] <= pressed; // ,
            'h049: key_ls30_p1[11] <= pressed; // .

            // Rotary1 LS-30 P2 Scancodes
            'h01z: key_ls30_p2[0]  <= pressed; // z
            'h022: key_ls30_p2[1]  <= pressed; // x
            'h021: key_ls30_p2[2]  <= pressed; // c
            'h02a: key_ls30_p2[3]  <= pressed; // v
            'h032: key_ls30_p2[4]  <= pressed; // b
            'h058: key_ls30_p2[5]  <= pressed; // caps lock
            'h024: key_ls30_p2[6]  <= pressed; // e
            'h02c: key_ls30_p2[7]  <= pressed; // t
            'h026: key_ls30_p2[8]  <= pressed; // 3
            'h025: key_ls30_p2[9]  <= pressed; // 4
            'h03d: key_ls30_p2[10] <= pressed; // 7
            'h03e: key_ls30_p2[11] <= pressed; // 8

            //'h001: key_fg_enable  <= key_fg_enable  ^ pressed; // f9
            //'h009: key_spr_enable <= key_spr_enable ^ pressed; // f10
        endcase
    end
end

// Rotary controls

reg [11:0] rotary1 ;  // this needs to be set using status or keyboard
reg [11:0] rotary2 ;  // the active bit is low

reg last_rot1_cw ;
reg last_rot1_ccw ;
reg last_rot2_cw ;
reg last_rot2_ccw ;

wire p1_rotary_controller_type = status[18];
wire p2_rotary_controller_type = status[19];

wire rot1_cw  = joy0[12] | key_ls30_p1[0];
wire rot1_ccw = joy0[13] | key_ls30_p1[1];
wire rot2_cw  = joy1[12] | key_ls30_p2[0];
wire rot2_ccw = joy1[13] | key_ls30_p2[1];

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        rotary1 <= 12'h1 ;
        rotary2 <= 12'h1 ;
    end else begin
        if ( p1_rotary_controller_type == 0 ) begin
            // did the button state change?
            if ( rot1_cw != last_rot1_cw ) begin 
                last_rot1_cw <= rot1_cw;
                // rotate right
                if ( rot1_cw == 1 ) begin
                    rotary1 <= { rotary1[0], rotary1[11:1] };
                end
            end

            if ( rot1_ccw != last_rot1_ccw ) begin
                last_rot1_ccw <= rot1_ccw;
                // rotate left
                if ( rot1_ccw == 1 ) begin
                    rotary1 <= { rotary1[10:0], rotary1[11] };
                end
            end
        end else begin
            rotary1 <= key_ls30_p1;
        end

        if ( p2_rotary_controller_type == 0 ) begin
            if ( rot2_cw != last_rot2_cw ) begin
                last_rot2_cw <= rot2_cw;
                if ( rot2_cw == 1 ) begin
                    rotary2 <= { rotary2[0], rotary2[11:1] };
                end
            end

            if ( rot2_ccw != last_rot2_ccw ) begin
                last_rot2_ccw <= rot2_ccw;
                if ( rot2_ccw == 1 ) begin
                    rotary2 <= { rotary2[10:0], rotary2[11] };
                end
            end
        end else begin
            rotary2 <= key_ls30_p2;
        end
    end
end

reg user_flip;

wire pll_locked;

wire clk_sys;
reg  clk_3M,clk_4M,clk_6M,clk_20M,clk_io;

wire clk_72M;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_sys),
    .outclk_1(clk_72M),
    .locked(pll_locked)
);

assign    SDRAM_CLK = clk_72M;

localparam  CLKSYS=72;

reg [15:0] clk20_count;
reg  [5:0] clk6_count;
reg  [7:0] clk4_count;
reg  [5:0] clk3_count;
reg [15:0] clk_upd_count;

reg [16:0] clk_io_count;

reg [15:0] frame_count;


always @ (posedge clk_sys) begin

    clk_3M <= ( clk3_count == 0 );

    if ( clk3_count == 23 ) begin // 17
        clk3_count <= 0;
    end else begin
        clk3_count <= clk3_count + 1;
    end
    
    // M=9 / N=181 
    clk_4M <= 0;
    if ( clk4_count > 180 ) begin
        clk_4M <= 1;
        clk4_count <= clk4_count - 171;
    end else begin
        clk4_count <= clk4_count + 9;
    end
    
    clk_6M <= ( clk6_count == 0 );

    if ( clk6_count == 11 ) begin // 11
        clk6_count <= 0;
    end else begin
        clk6_count <= clk6_count + 1;
    end

    // fractional divider 20MHz from 72
    clk_20M <= 0;
    if ( clk20_count > 17 ) begin
        clk_20M <= 1 ;
        clk20_count <= clk20_count - 12;
    end else if ( pause_cpu == 0 )  begin
        clk20_count <= clk20_count + 5;
    end
    
    clk_io <= ( clk_io_count == 0 ) ;

    if ( clk_io_count == 4_666_234 ) begin // 15.4 Hz
        clk_io_count <= 0;
    end else begin
        clk_io_count <= clk_io_count + 1;
    end    
    
end

wire    reset;
assign  reset = RESET | key_reset | status[0] ; 

//////////////////////////////////////////////////////////////////
wire rotate_ccw = 0;
wire no_rotate = orientation | direct_video;
wire video_rotated ;
wire flip = 0;

reg [23:0]     rgb;

wire hbl;
wire vbl;

wire [8:0] hc;
wire [8:0] vc;

wire hsync;
wire vsync;

reg hbl_delay, vbl_delay;

always @ ( posedge clk_6M ) begin
    hbl_delay <= hbl ;
    vbl_delay <= vbl ;
end

video_timing video_timing (
    .clk(clk_6M),
    .clk_pix(1'b1),
    .pcb(pcb),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

// PAUSE SYSTEM
wire    pause_cpu;
wire    hs_pause;

// 8 bits per colour, 72MHz sys clk
pause #(8,8,8,72) pause 
(
    .clk_sys(clk_sys),
    .reset(reset),
    .user_button(b_pause),
    .pause_request(hs_pause),
    .options(status[21:20]),
    .pause_cpu(pause_cpu),
    .dim_video(dim_video),
    .OSD_STATUS(OSD_STATUS),
    .r(rgb[23:16]),
    .g(rgb[15:8]),
    .b(rgb[7:0]),
    .rgb_out(rgb_pause_out)
);

wire [23:0] rgb_pause_out;
wire dim_video;

arcade_video #(256,24) arcade_video
(
        .*,

        .clk_video(clk_sys),
        .ce_pix(clk_6M),

        .RGB_in(rgb_pause_out),

        .HBlank(hbl_delay),
        .VBlank(vbl_delay),
        .HSync(hsync),
        .VSync(vsync),

        .fx(scan_lines)
);

/*     Phase Accumulator Increments (Fractional Size 32, look up size 8 bit, total 40 bits)
    Increment Calculation - (Output Clock * 2 ^ Word Size) / Reference Clock
    Example
    NTSC = 3.579545
    PAL =  4.43361875
    W = 40 ( 32 bit fraction, 8 bit look up reference)
    Ref CLK = 42.954544 (This could us any clock)
    NTSC_Inc = 3.579545333 * 2 ^ 40 / 96 = 40997413706
    
*/


// SET PAL and NTSC TIMING
`ifdef MISTER_ENABLE_YC
    assign CHROMA_PHASE_INC = PALFLAG ? 40'd67705769163: 40'd54663218274 ;
    assign YC_EN =  status[22];
    assign PALFLAG = status[7];
`endif

screen_rotate screen_rotate (.*);

reg [7:0] hc_del;

reg [4:0] tile_state;
reg [4:0] sprite_state;
reg [8:0] sprite_num;

reg   [2:0] pri_buf[0:255];
 
reg  [31:0] pix_data;
reg  [31:0] spr_pix_data;
reg  [31:0] spr_pix_data_fifo;

reg   [8:0] x;

//wire  [8:0] sp_x    = x ;
//wire  [8:0] sp_y    = vc ^ { 8 { flip_dip } };
//wire  [8:0] sp_y    = vc;

wire  [8:0] sp_x    = x ;
wire  [8:0] sp_y    = vc ^ { 8 { flip_dip } };
//wire  [8:0] sp_y    = vc ;

wire  [9:0] fg_tile = { sp_x[7:3], sp_y[7:3] };

reg   [7:0] fg_colour;

reg   [7:0] sprite_colour;
reg  [14:0] sprite_tile_num;
reg         sprite_flip_x;
reg         sprite_flip_y;
reg   [1:0] sprite_group;
reg   [4:0] sprite_col;
reg  [15:0] sprite_col_x;
reg  [15:0] sprite_col_y;
//reg   [1:0] sprite_col_adj;
reg   [8:0] sprite_col_idx;
reg   [8:0] spr_x_pos;
reg   [3:0] spr_x_ofs;

reg   [1:0] sprite_layer;
wire  [1:0] layer_order [3:0] = '{2'd2,2'd3,2'd1,2'd0};

wire  [3:0] spr_pen = { spr_pix_data[24 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[16 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[ 8 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[ 0 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]] }  ;

//reg [3:0] sprite_col_idx_flipped ;

reg   [11:0] sp_count ;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        tile_state   <= 0;
        sprite_state <= 0;
        sprite_overrun <= 0;
        sprite_rom_cs <= 0;
        fg_colour <= 0;
    end else begin

        // tiles
        if ( tile_state == 0 && hc == 0 ) begin
            tile_state <= 1;
            sp_count <= 0;
            x <= 0;
        end else if ( tile_state == 1) begin
            line_buf_fg_w <= 0;
            fg_ram_addr <= { fg_tile, 1'b0 } ; 
            tile_state <= 2;
        end else if ( tile_state == 2) begin  
            // address is valid - need more more cycle to read 
            fg_ram_addr <= fg_ram_addr + 1;
            tile_state <= 3;
        end else if ( tile_state == 3) begin  
            if ( pcb < 5 ) begin
                fg_rom_addr <= { tile_bank[2:0], fg_ram_dout[7:0], ~sp_x[2], sp_x[1]  , sp_y[2:0] } ;
            end else begin
                fg_rom_addr <= { tile_bank[6:4], fg_ram_dout[7:0], ~sp_x[2], sp_y[2:0], 1'b0 } ;
            end
            tile_state <= 4;
        end else if ( tile_state == 4) begin             
            // address is valid - need more more cycle to read 
            fg_rom_addr <= fg_rom_addr + 1;
            // the colour in the second tile attribute byte
            fg_colour <= fg_ram_dout[4:0] ; // [4] == opaque
            tile_state <= 5;
        end else if ( tile_state == 5) begin 
            // version II boards need 16 bits.  
            pix_data[7:0] <= fg_rom_data;
            tile_state <= 6 ;
        end else if ( tile_state == 6) begin 
            pix_data[15:8] <= fg_rom_data;
            tile_state <= 7 ;
        end else if ( tile_state == 7) begin 
            line_buf_addr_w <= { vc[0], x[8:0] };
            line_buf_fg_w <= 1;
            if ( pcb < 5 ) begin
                case ( sp_x[0] )
                    0: line_buf_fg_din <= { fg_colour, pix_data[3:0] } ; 
                    1: line_buf_fg_din <= { fg_colour, pix_data[7:4] } ; 
                endcase
            end else begin
                case ( sp_x[1:0] )
                    0: line_buf_fg_din <= { fg_colour, pix_data[4], pix_data[0], pix_data[12], pix_data[8]  } ; 
                    1: line_buf_fg_din <= { fg_colour, pix_data[5], pix_data[1], pix_data[13], pix_data[9]  } ; 
                    2: line_buf_fg_din <= { fg_colour, pix_data[6], pix_data[2], pix_data[14], pix_data[10] } ; 
                    3: line_buf_fg_din <= { fg_colour, pix_data[7], pix_data[3], pix_data[15], pix_data[11] } ; 
                endcase
            end
            if ( x < 256 ) begin
                if ( sp_x[0] == 1'b1 ) begin
                    tile_state <= 1;
                end
                x <= x + 1;
            end else begin
                tile_state <= 8;
                line_buf_fg_w <= 0;
            end
        end else if ( tile_state == 8) begin
            x <= 0;
            tile_state <= 0;  
        end
        
        // sprites. -- need 3 sprite layers - 1 layer is split
        if ( sprite_state == 0 && hc == 0 ) begin
            // init
            sprite_state <= 21; // 21 = clear buffer, 22 = don't   ***********
            sprite_num <= 0;
            sprite_layer <= 0;
            // setup clearing line buffer
            spr_buf_din <= 0 ;
            spr_x_pos <= 0;
        end else if ( sprite_state == 21 )  begin  
            spr_buf_w <= 1 ;
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            if ( spr_x_pos > 256 ) begin
                spr_buf_w <= 0 ;
                sprite_state <= 22;
            end
            spr_x_pos <= spr_x_pos + 1;
        end else if ( sprite_state == 22 ) begin  
            // start 
            case ( sprite_layer )
                0: begin
                        sprite_group <= 1;
                        sprite_col   <= 31;
                   end
                1: begin
                        sprite_group <= 2;
                        sprite_col   <= 0;
                   end
                2: begin
                        sprite_group <= 3;
                        sprite_col   <= 0;
                   end
                3: begin
                        sprite_group <= 1;
                        sprite_col   <= 0;
                   end
            endcase
            sprite_state <= 1;
        end else if ( sprite_state == 1 )  begin
            sp_count <= sp_count + 1;
            spr_buf_w <= 0 ;

            // setup x read
            sprite_ram_addr <= { sprite_col, 3'b0, sprite_group, 1'b0 } ; 
            sprite_state <= 2;
        end else if ( sprite_state == 2 )  begin
            // setup y read
            sprite_ram_addr <= sprite_ram_addr + 1 ; 
            sprite_state <= 3;
        end else if ( sprite_state == 3 )  begin
            // x valid
            sprite_col_x <= sprite_ram_dout;
            sprite_state <= 4;
        end else if ( sprite_state == 4 )  begin
            if ( sprite_col_x[7:0] > 128 ) begin
                sprite_state <= 17;
            end
            // y valid
            
            sprite_col_y <= sprite_ram_dout ; // + sprite_col_adj
            sprite_state <= 18;
        end else if ( sprite_state == 18 )  begin   
            if ( sprite_layer == 0 ) begin
                if ( flip_dip == 0 ) begin
                    sprite_col_y <= sprite_col_y - 1 ;
                end else begin
                    sprite_col_y <= sprite_col_y + 1 ;
                end
            end
            sprite_state <= 5;
        end else if ( sprite_state == 5 )  begin
            // tile ofset from the top of the column
            sprite_col_idx <= sp_y + sprite_col_y[8:0] ;
            sprite_state <= 6;
        end else if ( sprite_state == 6 )  begin
            // setup sprite tile colour read
            sprite_ram_addr <= { sprite_group[1:0], sprite_col[4:0], sprite_col_idx[8:4], 1'b0 };
            sprite_state <= 7;
            
        end else if ( sprite_state == 7 ) begin
            // setup sprite tile index read
            sprite_ram_addr <= sprite_ram_addr + 1 ;
            sprite_state <= 8;
        end else if ( sprite_state == 8 ) begin
            // tile colour ready
            if ( pcb < 5 ) begin
                sprite_colour <= sprite_ram_dout[7:0] ; // 0xff
            end else begin
                sprite_colour <= sprite_ram_dout[6:0] ; // 0x7f
            end
            sprite_state <= 9;
        end else if ( sprite_state == 9 ) begin
            // tile index ready
            if ( pcb == 0 || pcb == 4 ) begin
                sprite_flip_x   <= 1'b0;  
                sprite_flip_y   <= sprite_ram_dout[15] ;
                sprite_tile_num <= sprite_ram_dout[14:0] ; 
            end else if ( pcb == 1 ) begin
                sprite_flip_x   <= sprite_ram_dout[15] ;
                sprite_flip_y   <= 1'b0;  // 0x8000
                sprite_tile_num <= sprite_ram_dout[14:0] ;
            end else if ( pcb == 2 || pcb == 5 ) begin                
                sprite_flip_x   <= sprite_ram_dout[14] ;
                sprite_flip_y   <= sprite_ram_dout[15] ;
                sprite_tile_num <= sprite_ram_dout[13:0] ;  
            end
            spr_x_ofs <= 0;
            spr_x_pos <= { sprite_col_x[7:0], sprite_col_y[15] } ;
            sprite_state <= 10;
        end else if ( sprite_state == 10 )  begin    
            //long addr = (t << 7) + (((dx & 0x8) != 0) ? 0 : 64) + (dy * 4);
            // sprite_rom_addr <= { tile[10:0], ~dx[3], dy[3:0] } ;
            case ( sprite_flip_y )
                1'b0: sprite_rom_addr <= { sprite_tile_num, ~sprite_flip_x,  sprite_col_idx[3:0] } ; // ~(sprite_flip_x^spr_x_ofs[3])
                1'b1: sprite_rom_addr <= { sprite_tile_num, ~sprite_flip_x, ~sprite_col_idx[3:0] } ;
            endcase 
            
            sprite_rom_cs <= 1;
            sprite_state <= 11;
        end else if ( sprite_state == 11 ) begin
            // wait for sprite bitmap data
            if ( sprite_rom_valid == 1 ) begin
                sprite_rom_cs <= 0;
                spr_pix_data <= sprite_rom_data;
                spr_pix_data_fifo <= 0;             // debugging
                sprite_state <= 12 ;
            end
        end else if ( sprite_state == 12 ) begin
            case ( sprite_flip_y )
                1'b0: sprite_rom_addr <= { sprite_tile_num, sprite_flip_x,  sprite_col_idx[3:0] } ; // ~(sprite_flip_x^spr_x_ofs[3])
                1'b1: sprite_rom_addr <= { sprite_tile_num, sprite_flip_x, ~sprite_col_idx[3:0] } ;
            endcase 

            sprite_rom_cs <= 1;
            
            sprite_state <= 13;
        end else if ( sprite_state == 13 ) begin
            // if the second read is ready queue the result and release sdram
            if ( sprite_rom_cs == 1 && sprite_rom_valid == 1 ) begin
                sprite_rom_cs <= 0;
                spr_pix_data_fifo <= sprite_rom_data;
                
//                if ( spr_x_ofs >= 7 ) begin
//                    spr_pix_data      <= sprite_rom_data ;
//                    //sprite_state <= 10;
//                end
            end else if ( sprite_rom_cs == 0 || spr_x_ofs < 7 ) begin
                //
                spr_buf_addr_w <= { vc[0], spr_x_pos };
                
                spr_buf_w <= (| spr_pen ) ; // | ~( | sprite_layer )  ; // don't write if 0 - transparent

                spr_buf_din <= { sprite_colour, spr_pen };

                if ( spr_x_ofs < 15 ) begin
                    spr_x_ofs <= spr_x_ofs + 1;
                    spr_x_pos <= spr_x_pos + 1;
                    
                    // the second 8 pixel needs another rom read
                    if ( spr_x_ofs == 7 ) begin
                        spr_pix_data <= spr_pix_data_fifo ;
                        //sprite_state <= 10;
                    end
                    
                end else begin
                    sprite_state <= 17;
                end
            end
       
        end else if ( sprite_state == 17) begin             
            spr_buf_w <= 0 ;
            if ( hc < 340 ) begin
                if ( sprite_col < 30 || (sprite_col < 31 && sprite_layer < 3) ) begin
                    sprite_col <= sprite_col + 1;
                    sprite_state <= 1; 
                end else begin
                    if ( sprite_layer < 3 ) begin
                        sprite_layer <= sprite_layer + 1;
                        sprite_state <= 22;  
                    end else begin
                        sprite_state <= 0;  
                    end
                end
            end else begin
                sprite_state <= 0;
            end
        end

    end
end
        
reg sprite_overrun;

reg [11:0] fg;
reg [11:0] sp;

reg [23:0] rgb_fg;
reg [23:0] rgb_sp;

reg [11:0] pen;
reg pen_valid;


// resistor dac 220, 470, 1k, 2.2k, 3.9k / has 8.2k pulldown for dimming (2nd block of 16)
wire [7:0] dac_weight[0:63] = '{8'd0,8'd13,8'd22,8'd34,8'd46,8'd57,8'd65,8'd75,8'd91,8'd100,8'd107,8'd116,8'd126,8'd134,8'd140,8'd148,
                                8'd168,8'd175,8'd180,8'd187,8'd194,8'd200,8'd205,8'd211,8'd220,8'd226,8'd230,8'd235,8'd241,8'd246,8'd250,8'd255,
                                // dim
                                8'd0, 8'd7,8'd17,8'd28,8'd41,8'd52,8'd60,8'd71,8'd87,8'd96,8'd103,8'd112,8'd122,8'd130,8'd136,8'd144,
                                8'd165,8'd172,8'd177,8'd184,8'd191,8'd197,8'd202,8'd208,8'd218,8'd223,8'd227,8'd233,8'd239,8'd244,8'd248,8'd253};

                 
reg [5:0] r_pal ;
reg [5:0] g_pal ;
reg [5:0] b_pal ;

always @ (posedge clk_sys) begin

    tile_pal_wr <= 0;

    if ( hc < 257 ) begin
        if ( clk6_count == 1 ) begin
            line_buf_addr_r <= { ~vc[0], 1'b0, hc[7:0] ^ { 8 { flip_dip } } } ; //( flip_dip == 0 ) ? hc[7:0] : ~hc[7:0] };
        end else if ( clk6_count == 2 ) begin
            fg <= line_buf_fg_out[11:0] ;
            sp <= spr_buf_dout[11:0] ;
        end else if ( clk6_count == 3 ) begin
            pen <= ( { fg[8], fg[3:0] } == 0 ) ? sp[11:0] : { 3'b0, fg[7:0] };  //   fg[8] == 1 means tile is opaque 
            //pen <= sp[11:0] ;
        end else if ( clk6_count == 4 ) begin
            if ( pen[3:0] == 0 ) begin
                if ( pcb < 5 ) begin
                    tile_pal_addr <= 12'hfff ; // background pen
                end else begin
                    tile_pal_addr <= 12'h7ff ; // background pen
                end
            end else begin
                tile_pal_addr <= pen[11:0] ;
            end
        end else if ( clk6_count == 6 ) begin
            r_pal <= { tile_pal_dout[15], tile_pal_dout[11:8] , tile_pal_dout[14] };
            g_pal <= { tile_pal_dout[15], tile_pal_dout[7:4]  , tile_pal_dout[13] };
            b_pal <= { tile_pal_dout[15], tile_pal_dout[3:0]  , tile_pal_dout[12] };
        end else if ( clk6_count == 7 ) begin
            rgb <= {dac_weight[r_pal], dac_weight[g_pal], dac_weight[b_pal] };
        end
    end
end

reg spr_flip_orientation ;
reg [7:0] tile_bank;
reg [1:0] vbl_sr;
reg [1:0] hbl_sr;

reg [7:0] credits;
reg [3:0] coin_count;
reg [1:0] coin_latch;


reg [7:0] coin_ratio_a [0:7] = '{ 8'h01, 8'h05, 8'h03, 8'h13, 8'h02, 8'h06, 8'h04, 8'h22 };  // (#coins-1) / credits
reg [7:0] coin_ratio_b [0:7] = '{ 8'h01, 8'h41, 8'h21, 8'h61, 8'h11, 8'h51, 8'h31, 8'h71 };

reg [12:0]  mcu_addr;
reg  [7:0]  mcu_din;
reg  [7:0]  mcu_dout;
reg         mcu_wh;
reg         mcu_wl;

reg         mcu_busy;
reg         mcu_2nd_write;
reg [12:0]  mcu_2nd_addr;
reg  [7:0]  mcu_2nd_din;
reg         mcu_2nd_wh;
reg         mcu_2nd_wl;

/// 68k cpu
always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        m68k_dtack_n <= 1;
        
        m68k_ipl0_n <= 1 ;
        m68k_ipl1_n <= 1 ;
        
        z80_irq_n <= 1 ;
        m68k_latch <= 0;
        spr_flip_orientation <= 0;
        tile_bank <= 0;
        frame_count <= 0;
        
        mcu_addr <= 0;
        mcu_din <= 0 ;
        mcu_wh <= 0;
        mcu_wl <= 0;
                
        z80_latch <= 0;        
        z80_nmi_n <= 1 ;
        z80_bank <= 0;
        z80_nmi_suppress <= 1; // ym2203 port high impedance on reset?
        
        credits <= 0;
        coin_latch <= 0;
        mcu_2nd_write <= 0;
        mcu_2nd_wl <= 0;
        mcu_2nd_wh <= 0;
        mcu_busy <= 0;
    end else begin
    
        // vblank handling 
        vbl_sr <= { vbl_sr[0], vbl };
        if ( vbl_sr == 2'b01 ) begin // rising edge
            //  68k vbl interrupt
            m68k_ipl0_n <= 0;
            frame_count <= frame_count + 1;
        end 

        // mcu interrupt handling 
        hbl_sr <= { hbl_sr[0], clk_io };  // ????
        if ( hbl_sr == 2'b01 ) begin // rising edge
            //  68k vbl interrupt
            m68k_ipl1_n <= 0;
        end 

        if ( clk_20M == 1 ) begin
            // cpu acknowledged the interrupt
            // TODO - this should be enable lines set by reading memory locations d8000 & e0000
            if ( ( m68k_as_n == 0 ) && ( m68k_fc == 3'b111 ) ) begin
                m68k_ipl0_n <= 1;
                m68k_ipl1_n <= 1;
            end
            
            mcu_wh <= 0;
            mcu_wl <= 0;

            // tell 68k to wait for valid data. 0=ready 1=wait
            // always ack when it's not program rom
            m68k_dtack_n <= m68k_rom_cs ? !m68k_rom_valid : 
                            m68k_rom_2_cs ? !m68k_rom_2_valid : 
                            0; 
                        
            if ( m68k_rw == 1 ) begin                          
                // reads
                m68k_din <=  m68k_rom_cs ? m68k_rom_data :
                             m68k_ram_cs  ? m68k_ram_dout :
                             m68k_rom_2_cs ? m68k_rom_2_data :
                             // high byte of even addressed sprite ram not connected.  pull high.
                             m68k_spr_cs  ? m68k_sprite_dout : // 0xff000000
                             m68k_fg_ram_cs ? m68k_fg_ram_dout :
                             m68k_pal_cs ? m68k_pal_dout :
                             input_p1_cs ? { p2, p1 } :
                             input_dsw1_cs ? dsw1 :
                             m68k_sp85_cs ? 0 : 
                             m68k_rotary1_cs ? ~{ rotary1[11:4], 8'h0 } :
                             m68k_rotary2_cs ? ~{ rotary2[11:4], 8'h0 } :
                             16'h0000;

                // mcu addresses are word 
                if ( m68k_sp85_cs == 1 ) begin
                    if (  mcu_busy == 0 ) begin
                        mcu_busy <= 1;
                        if ( m68k_a[8:1] == 8'h00 ) begin
                            
                            if ( pcb == 0 || pcb == 2 || pcb == 4 ) begin
                                // sky adv / baseball
                                mcu_addr <= 13'h0000;
                            end else begin
                                // gang wars
                                mcu_addr <= 13'h1f00;
                            end
                            mcu_din <= dsw2 ;
                            mcu_wl <= 1;
                        end else if ( m68k_a[8:1] == 8'h22 ) begin
                            mcu_addr <= 13'h0022;
                            mcu_din <= credits ;
                            credits <= 0;
                            mcu_wl <= 1;
                        end else if ( m68k_a[8:1] == 8'h29 ) begin
                            // coins
                            if ( { coin_b, coin_a } == 0 ) begin
                                coin_latch <= 0;
                                
                                mcu_addr <= m68k_a[13:1];
                                mcu_din <= 8'h00 ;
                                mcu_wl <= 1;
                            end else if ( coin_latch == 0 ) begin
                                coin_latch <= { coin_b, coin_a };

                                // set coin id
                                if ( pcb == 0 || pcb == 4 || pcb == 5 ) begin
                                    if ( pcb == 4 ) begin
                                        if ( coin_a == 1 ) begin
                                            mcu_din <= 8'h23 ;
                                        end else begin
                                            mcu_din <= 8'h24 ;
                                        end
                                    end else begin
                                        mcu_din <= 8'h22 ;
                                    end
                                    
                                    if ( coin_a == 1 ) begin
                                        if ( coin_ratio_a[ ~dsw2[3:1] ][7:4] == coin_count ) begin
                                            credits <= coin_ratio_a[ ~dsw2[3:1] ][3:0];
                                            coin_count <= 0;
                                        end else begin
                                            coin_count <= coin_count + 1;
                                        end
                                    end if ( coin_b == 1 ) begin 
                                        if ( coin_ratio_b[ ~dsw2[3:1] ][7:4] == coin_count ) begin
                                            credits <= coin_ratio_b[ ~dsw2[3:1] ][3:0];
                                            coin_count <= 0;
                                        end else begin
                                            coin_count <= coin_count + 1;
                                        end
                                    end
                                    
                                    // clear for sky adv
                                    mcu_2nd_write <= 1;
                                    mcu_2nd_addr  <= 13'h0022 ;
                                    mcu_2nd_din   <= 0 ;
                                    mcu_2nd_wl    <= 1;

                                end else if ( pcb == 1 || pcb == 2 ) begin
                                    // slot a/b values
                                    if ( coin_a == 1 ) begin
                                        mcu_din <= 8'h23 ;
                                    end else begin
                                        mcu_din <= 8'h24 ;
                                    end
                                end
                                mcu_addr <= m68k_a[13:1];
                                mcu_wl <= 1;
                            end else begin
                                mcu_addr <= m68k_a[13:1];
                                mcu_din <= 8'h00 ;
                                mcu_wl <= 1;
                            end
                            
                            // if gang wars trigger writing the dip value to ram
                            if ( pcb == 1 ) begin
                                mcu_2nd_write <= 1;
                                mcu_2nd_addr  <= 13'h0163 ;
                                mcu_2nd_din   <= dsw2 ;
                                mcu_2nd_wh    <= 1;
                            end
                        end else if ( m68k_a[8:1] == 8'hfe ) begin
                            // mcu id hign - gang wars 8512
                            if ( pcb == 0 ) begin
                                mcu_addr <= 13'h00fe;
                                mcu_din <= 8'h88 ;
                                mcu_wl <= 1;
                            end else if ( pcb == 1 ) begin
                                mcu_addr <= 13'h1ffe;
                                mcu_din <= 8'h85 ;
                                mcu_wl <= 1;
                            end else if ( pcb == 2 ) begin
                                mcu_addr <= 13'h00fe;
                                mcu_din <= 8'h85 ;
                                mcu_wl <= 1;
                            end else if ( pcb > 4 ) begin
                                mcu_addr <= 13'h00fe;
                                mcu_din <= 8'h87 ;
                                mcu_wl <= 1;
                            end
                        end else if ( m68k_a[8:1] == 8'hff ) begin
                            // mcu id low
                            if ( pcb == 0 ) begin
                                mcu_addr <= 13'h00ff;
                                mcu_din <= 8'h14 ;
                                mcu_wl <= 1;
                            end else if ( pcb == 1 ) begin
                                mcu_addr <= 13'h1fff;
                                mcu_din <= 8'h12 ;
                                mcu_wl <= 1;
                            end else if ( pcb == 2 ) begin
                                mcu_addr <= 13'h00ff;
                                mcu_din <= 8'h12 ;
                                mcu_wl <= 1;
                            end else if ( pcb > 4 ) begin
                                mcu_addr <= 13'h00ff;
                                mcu_din <= 8'h13 ;
                                mcu_wl <= 1;
                            end
                        end
                    end
                end else begin
                    mcu_busy <= 0;
                end
                
                if ( mcu_wl == 1 && mcu_2nd_write == 1 ) begin
                    mcu_addr <= mcu_2nd_addr; 
                    mcu_din <= mcu_2nd_din ;
                    mcu_wl <= mcu_2nd_wl;
                    mcu_wh <= mcu_2nd_wh;

                    mcu_2nd_write <= 0;
                    mcu_2nd_wl <= 0;
                    mcu_2nd_wh <= 0;
                end

                if ( vbl_int_clr_cs == 1 ) begin
                    m68k_ipl0_n <= 1;
                end 
                
                if ( cpu_int_clr_cs == 1 ) begin
                    m68k_ipl1_n <= 1;
                end 
                
            end else begin        
                // writes
            
                if ( m68k_latch_cs == 1 ) begin
                    // text tile banking
                    if ( m68k_uds_n == 0 ) begin // UDS 0x80000
                        tile_bank <= m68k_dout[11:8] ;
                    end 
                    if ( m68k_lds_n == 0 ) begin // LDS 0x80001
                        m68k_latch <= m68k_dout[7:0]; 
                    end
                end
                
                if ( m68k_spr_flip_cs == 1 ) begin
                    spr_flip_orientation <= m68k_dout[2] ;
                end
 
                if ( pcb > 4 && m68k_lds_n == 0 && input_dsw1_cs == 1 ) begin // LDS 0xc00xx
                    tile_bank[m68k_a[5:3]] <= m68k_a[6] ;  // 
                end

            end 
        end
        
        if ( clk_6M == 1 ) begin

            z80_wait_n <= 1;
            
            if ( z80_rd_n == 0 ) begin
                // Z80 READ

                if ( z80_banked_cs == 1 ) begin
                    // testing -- most of attract runs from bank 2
//                    if ( z80_bank == 2 ) begin
//                        z80_din <= z80_rom_2_data;
//                    end else begin
                        if ( z80_banked_valid ) begin
                            z80_din <= z80_banked_data;
                        end else begin
                            z80_wait_n <= 0;
                        end
//                    end
                end else if ( z80_ram_cs == 1 ) begin
                    z80_din <= z80_ram_data ;
                end else if ( z80_rom_cs == 1 ) begin
                    z80_din <= z80_rom_data ;
                end else if ( z80_latch_cs == 1 ) begin
                    // z80_din <= ( pcb == 1 && m68k_latch == 8'h81 ) ? 8'h7e : m68k_latch ;
                    // z80_din <= m68k_latch ;
                    z80_din <= ( kill_laugh == 1 && m68k_latch == 8'h81 ) ? 8'h00 : m68k_latch ;
                end  
            end
           
            // WRITE

            opn_wr <= 0 ;
//            opll_wr <= 0 ;
            
            // DAC
            if ( z80_dac_cs == 1 ) begin
                dac <= z80_dout ;
            end
                
            // OPLL YM2413
            if ( z80_ym2413_cs == 1 ) begin    
                opll_data  <= z80_dout;

                opll_addr <= z80_addr[0] ;
//                opll_wr <= 1;
            end 

            // OPN YM2203
            if ( z80_ym2203_cs == 1 ) begin   
                // write to io port A
                if ( z80_addr[0] == 0 ) begin
                    io_port_a_wr <= ( z80_dout == 8'h0e );
                end else begin
                    if ( io_port_a_wr == 1 ) begin
                        z80_nmi_suppress <= z80_dout[0];
                        io_port_a_wr <= 0;
                    end
                end
            end 
            
            if ( z80_latch_clr_cs == 1 ) begin
                m68k_latch <= 0 ;
            end  
            
            if ( z80_bank_set_cs == 1 ) begin
                 z80_bank <= z80_dout[4:0];
            end
       
        end

        // ym2203 can disable z80 nmi by writting 1 to bit 0 of portA
        // if enabled, nmi is triggered by falling edge of bit 0 vertical line count
        // /NMI is negative edge triggered 
        z80_nmi_n <= (~vc[0]) | z80_nmi_suppress ;        
        
    end
end 

 
wire    m68k_rom_cs;
wire    m68k_rom_2_cs;
wire    m68k_ram_cs;
wire    m68k_pal_cs;
wire    m68k_spr_cs;
wire    m68k_fg_ram_cs;
wire    m68k_spr_flip_cs;
wire    input_p1_cs;
wire    input_p2_cs;
wire    m68k_rotary1_cs;
wire    m68k_rotary2_cs;
wire    input_coin_cs;
wire    input_dsw1_cs;
wire    input_dsw2_cs;
wire    irq_z80_cs;
wire    m_invert_ctrl_cs;
wire    m68k_latch_cs;
wire    z80_latch_read_cs;
wire    vbl_int_clr_cs;
wire    cpu_int_clr_cs;
wire    watchdog_clr_cs;
wire    m68k_sp85_cs;
wire    m68k_coin_cs;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_banked_cs;
    
wire    z80_latch_cs;
wire    z80_latch_clr_cs;
wire    z80_dac_cs;
wire    z80_ym2413_cs;
wire    z80_ym2203_cs;
wire    z80_bank_set_cs;
  
chip_select cs (
    .clk(clk_sys),
    .pcb(pcb),

    // 68k bus
    .m68k_a,
    .m68k_as_n,
    .m68k_rw,

    .z80_addr,
    .MREQ_n,
    .IORQ_n,
    .RD_n( z80_rd_n ),
    .WR_n( z80_wr_n ),
    
    .M1_n,
    
    // 68k chip selects
    .m68k_rom_cs,
    .m68k_rom_2_cs,
    .m68k_ram_cs,
    .m68k_spr_cs,
    .m68k_sp85_cs,
    .m68k_fg_ram_cs,
    .m68k_pal_cs,

    .m68k_rotary1_cs,
    .m68k_rotary2_cs,

    .input_p2_cs,
    .input_coin_cs,
    .input_p1_cs,
    .input_dsw1_cs,
    .input_dsw2_cs,
    .m68k_coin_cs,

    // interrupt clear & watchdog
    .vbl_int_clr_cs,
    .cpu_int_clr_cs,
    .watchdog_clr_cs,

    .m68k_latch_cs, // write commands to z80 from 68k
    
    // z80 

    .z80_rom_cs,
    .z80_ram_cs,
    .z80_banked_cs, 
    
    .z80_latch_cs,
    .z80_latch_clr_cs,
    .z80_dac_cs,
    .z80_ym2413_cs,
    .z80_ym2203_cs,
    .z80_bank_set_cs 

);
 
reg [7:0]  z80_latch;
reg [7:0]  m68k_latch;

// CPU outputs
wire m68k_rw         ;    // Read = 1, Write = 0
wire m68k_as_n       ;    // Address strobe
wire m68k_lds_n      ;    // Lower byte strobe
wire m68k_uds_n      ;    // Upper byte strobe
wire m68k_E;         
wire [2:0] m68k_fc    ;   // Processor state
wire m68k_reset_n_o  ;    // Reset output signal
wire m68k_halted_n   ;    // Halt output

// CPU busses
wire [15:0] m68k_dout       ;
wire [23:0] m68k_a   /* synthesis keep */       ;
reg  [15:0] m68k_din        ;   
//assign m68k_a[0] = 1'b0;

// CPU inputs
reg  m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl0_n ;
reg  m68k_ipl1_n ;

wire m68k_vpa_n = ~(m68k_a[22] & ~(m68k_uds_n & m68k_lds_n)) ;   //~int_ack
wire m68k_e ;

reg int_ack ;

wire reset_n;

reg fg_enable;
reg sp_enable;

// fx68k clock generation
reg fx68_phi1;

always @(posedge clk_sys) begin
    if ( clk_20M == 1 ) begin
        fx68_phi1 <= ~fx68_phi1;
    end
end

fx68k fx68k (
    // input
    .clk( clk_20M ),
    .enPhi1(fx68_phi1),
    .enPhi2(~fx68_phi1),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68k_rw),
    .ASn(m68k_as_n),
    .LDSn(m68k_lds_n),
    .UDSn(m68k_uds_n),
    .E(m68k_e),
    .VMAn(),
    .FC0(m68k_fc[0]),
    .FC1(m68k_fc[1]),
    .FC2(m68k_fc[2]),
    .BGn(),
    .oRESETn(m68k_reset_n_o),
    .oHALTEDn(m68k_halted_n),

    // input
    .VPAn( m68k_vpa_n ),  
    .DTACKn( m68k_dtack_n ),     
    .BERRn(1'b1), 
    .BRn(1'b1),  
    .BGACKn(1'b1),
    
    .IPL0n(m68k_ipl0_n),
    .IPL1n(m68k_ipl1_n),
    .IPL2n(1'b1),

    // busses
    .iEdb(m68k_din),
    .oEdb(m68k_dout),
    .eab(m68k_a[23:1])
);


// z80 audio 
wire    [7:0] z80_rom_data;
wire    [7:0] z80_rom_2_data;
wire    [7:0] z80_banked_data;
wire    [7:0] z80_ram_data;

wire   [15:0] z80_addr;
reg     [7:0] z80_din;
wire    [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
//wire z80_wait_n = ~(z80_banked_cs & ~z80_banked_valid ) ;
reg z80_wait_n;
reg  z80_irq_n;
reg  z80_nmi_n;

wire IORQ_n;
wire MREQ_n;
wire M1_n;

T80pa z80 (
    .RESET_n    ( ~reset ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk_6M ),
    .CEN_n      ( ~clk_6M ),
    .WAIT_n     ( z80_wait_n ), // z80_wait_n
    .INT_n      ( 1'b1 ),  
    .NMI_n      ( z80_nmi_n ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     (),
    .IORQ_n     ( IORQ_n ),
    .M1_n       ( M1_n ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);

reg opl_wait ;
reg z80_nmi_suppress;

reg     io_port_a_wr ;

reg        opn_wr;
reg        opn_addr ;
reg  [7:0] opn_data ;

reg        opll_wr;
reg        opll_addr ;
reg  [7:0] opll_data ;

// sound ic write enable

reg signed [15:0] opll_sample;
reg signed [15:0] opn_sample;

assign AUDIO_S = 1'b1 ;

wire opll_sample_clk;
wire opn_sample_clk;

// OPLL (3.578 MHZ)
jt2413 ym2413 (
    .rst(reset),
    .clk(clk_sys),
    .cen(clk_4M), 
    .din( z80_dout ),
    .addr( z80_addr[0] ),
    .cs_n(~z80_ym2413_cs),
    .wr_n(0), //~opll_wr

    .snd(opll_sample),
    .sample(opll_sample_clk)
);

reg ym2203we ;
reg [7:0] ym2203_din;
reg ym2203addr;

always @ (posedge clk_sys) begin
    ym2203we <= ~z80_ym2203_cs ;
    ym2203_din <= z80_dout ;
    ym2203addr <= z80_addr[0] ;
end

// OPN (3 MHZ)
jt03 ym2203 (
    .rst(reset),
    .clk(clk_sys), // clock in is signal 1H (6MHz/2)
    .cen(clk_3M),
    .din( ym2203_din ),
    .addr( ym2203addr ),
    .cs_n( ym2203we ),
    .wr_n( ym2203we ), 

    .snd(opn_sample)
);

reg  signed  [7:0] dac ;
wire signed [15:0] dac_sample = { ~dac[7], dac[6:0], 8'h0 } ;

always @ * begin
    // mix audio
    AUDIO_L <= ( ( opn_sample + opll_sample + dac_sample  ) * 5 ) >>> 4;  // ( 3*5 ) / 16th
    AUDIO_R <= ( ( opn_sample + opll_sample + dac_sample  ) * 5 ) >>> 4;  // ( 3*5 ) / 16th
end

reg [16:0] gfx1_addr;
reg [17:0] gfx2_addr;

reg [7:0] gfx1_dout;
reg [7:0] gfx2_dout;

wire [15:0] m68k_ram_dout;
wire [15:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;

// ioctl download addressing    
wire rom_download = ioctl_download && (ioctl_index==0);

wire fg_ioctl_wr    = rom_download & ioctl_wr & (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h110000) ;
wire z80_ioctl_wr   = rom_download & ioctl_wr & (ioctl_addr >= 24'h080000) & (ioctl_addr < 24'h088000) ;
wire z80_ioctl_2_wr = rom_download & ioctl_wr & (ioctl_addr >= 24'h088000) & (ioctl_addr < 24'h090000) ;

// main 68k ram high    
dual_port_ram #(.LEN(8192)) ram8kx8_H (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_ram_dout[15:8] ),
    
    .clock_b ( clk_sys ),
    .address_b ( mcu_addr ),  
    .wren_b ( mcu_wh ),
    .data_b ( mcu_din ),
    .q_b( mcu_dout )

    );

// main 68k ram low     
dual_port_ram #(.LEN(8192)) ram8kx8_L (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_ram_dout[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( mcu_addr ),  
    .wren_b ( mcu_wl ),
    .data_b ( mcu_din ),
    .q_b( mcu_dout )
    );

reg  [13:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout /* synthesis keep */;

// main 68k sprite ram high  
// 2kx16
dual_port_ram #(.LEN(16384)) sprite_ram_H (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[14:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_sprite_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[15:8] )
    );

// main 68k sprite ram low     
dual_port_ram #(.LEN(16384)) sprite_ram_L (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[14:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_sprite_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );

   
wire [10:0] fg_ram_addr /* synthesis keep */;
wire [15:0] fg_ram_dout /* synthesis keep */;

wire [15:0] m68k_fg_ram_dout;

wire fg_u_w = !m68k_rw & m68k_fg_ram_cs & !m68k_uds_n ;
wire fg_l_w = !m68k_rw & m68k_fg_ram_cs & !m68k_lds_n ;

//// foreground high   
//dual_port_ram #(.LEN(2048)) ram_fg_h (
//    .clock_a ( clk_20M ),
//    .address_a ( m68k_a[11:1] ),
//    .wren_a ( fg_u_w ), 
//    .data_a ( m68k_dout[15:8]  ),
//    .q_a ( m68k_fg_ram_dout[15:8] ),
//
//    .clock_b ( clk_sys ),
//    .address_b ( fg_ram_addr ),  
//    .wren_b ( 1'b0 ),
//    .data_b ( ),
//    .q_b( fg_ram_dout[15:8] )
//    
//    );

// foreground low
dual_port_ram #(.LEN(2048)) ram_fg_l (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( fg_l_w | fg_u_w ),
    .data_a ( m68k_dout[7:0] ),
    .q_a ( m68k_fg_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );
    
    
reg tile_pal_wr;
reg  [11:0] tile_pal_addr;
wire [15:0] tile_pal_dout;
wire [15:0] tile_pal_din;

    
// tile palette high   
dual_port_ram #(.LEN(4096)) tile_pal_h (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_pal_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( tile_pal_wr ),
    .data_b ( tile_pal_din ),
    .q_b( tile_pal_dout[15:8] )
    );

//  tile palette low
dual_port_ram #(.LEN(4096)) tile_pal_l (
    .clock_a ( clk_20M ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_pal_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( tile_pal_wr ),
    .data_b ( ),
    .q_b( tile_pal_dout[7:0] )
    );    
    
//z80 program rom
reg   [4:0] z80_bank;
wire [18:0] z80_rom_addr = { z80_bank[4:0], z80_addr[13:0] }; // ( z80_rom_cs == 1 )    ? { 4'b0, z80_addr[14], z80_addr[13:0] } : 
//                            ( z80_banked_cs == 1 ) ? {      z80_bank[4:0], z80_addr[13:0] } : 
//                            0;

//always @ * begin
//    case (1)
//        z80_rom_cs:     z80_rom_addr = { 3'b0, z80_addr[14], z80_addr[13:0] };
//        z80_banked_cs:  z80_rom_addr = { z80_bank[4:0], z80_addr[13:0] };
//    endcase
//end

// sky adventure 
dual_port_ram #(.LEN(32768)) z80_rom (
    .clock_a ( clk_6M ),
    .address_a ( z80_addr[14:0] ),   
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( z80_rom_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[14:0] ),
    .wren_b ( z80_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
    
dual_port_ram #(.LEN(32768)) z80_rom_bank2 (
    .clock_a ( clk_6M ),
    .address_a ( z80_addr[14:0] ),   
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( z80_rom_2_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[14:0] ),
    .wren_b ( z80_ioctl_2_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
    
// z80 ram 
dual_port_ram #(.LEN(2048)) z80_ram (
    .clock_b ( clk_6M ), 
    .address_b ( z80_addr[10:0] ),
    .wren_b ( z80_ram_cs & ~z80_wr_n ),
    .data_b ( z80_dout ),
    .q_b ( z80_ram_data )
    );
    
//reg [16:0] upd_addr ;
//wire [7:0] upd_dout ;

//adpcm sample rom    
//dual_port_ram #(.LEN(131072)) upd_rom (
//    .clock_a ( clk_sys ),
//    .address_a ( upd_addr[16:0] ),
//    .wren_a ( 1'b0 ),
//    .data_a ( ),
//    .q_a ( upd_dout[7:0] ),
//    
//    .clock_b ( clk_sys ),
//    .address_b ( ioctl_addr[16:0] ),
//    .wren_b ( upd_ioctl_wr ),
//    .data_b ( ioctl_dout  ),
//    .q_b( )
//    );
    
wire [15:0] spr_pal_dout ;
wire [15:0] m68k_spr_pal_dout ;

reg  [8:0]  sprite_buffer_addr;  // 128 sprites
reg  [63:0] sprite_buffer_din;
wire [63:0] sprite_buffer_dout;
reg  sprite_buffer_w;

dual_port_ram #(.LEN(512), .DATA_WIDTH(64)) sprite_buffer (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buffer_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( sprite_buffer_dout ),
    
    .clock_b ( clk_sys ),
    .address_b ( sprite_buffer_addr ),
    .wren_b ( sprite_buffer_w ),
    .data_b ( sprite_buffer_din  ),
    .q_b( )

    );
    
reg          line_buf_fg_w;
reg   [9:0]  line_buf_addr_w;
reg   [9:0]  line_buf_addr_r ; 

reg  [15:0]  line_buf_fg_din;
wire [15:0]  line_buf_fg_out;

reg   [9:0]  spr_buf_addr_w;
reg          spr_buf_w;
reg  [15:0]  spr_buf_din;
wire [15:0]  spr_buf_dout;
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) spr_buffer_ram (
    .clock_a ( clk_sys ),
    .address_a ( spr_buf_addr_w ),
    .wren_a ( spr_buf_w ),
    .data_a ( spr_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ), 
    .wren_b ( 0 ),
    .q_b ( spr_buf_dout )
    ); 
    
// two line buffer
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) line_buffer_ram_fg (
    .clock_a ( clk_sys ),
    .address_a ( line_buf_addr_w ),
    .wren_a ( line_buf_fg_w ),
    .data_a ( line_buf_fg_din ),
    .q_a ( ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),  
    .wren_b ( 0 ),
    .q_b ( line_buf_fg_out )
    );    


wire z80_banked_valid;
   
wire [15:0] m68k_rom_data;
wire        m68k_rom_valid;

wire [15:0] m68k_rom_2_data;
wire        m68k_rom_2_valid;

reg         sprite_rom_cs;
reg  [19:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
wire        sprite_rom_valid;

reg         sprite_cache_cs;
reg  [19:0] sprite_cache_addr;
wire [31:0] sprite_cache_data;
wire        sprite_cache_valid;

//reg  [16:0] upd_rom_addr;
//wire  [7:0] upd_rom_data;
//wire        upd_rom_cs;
//wire        upd_rom_valid;

reg [15:0] fg_rom_addr;
reg  [7:0] fg_rom_data;

//10000,11000,00000,01000, 10001,11001,00001,01001
//00000,00001,00010,00011, 00100,00101,00110,00111

// ( a[15:5], a[2:0], ~a[4], a[3] )

// ( t[15:5], ~t[1], t[0], t[4:2] )

// swizzle the tile bitmap loading so each 4 pixels is one 16 bit read
//wire [15:0] fg_ioctl_addr = { ioctl_addr[15:5], ioctl_addr[2:0], ~ioctl_addr[4], ioctl_addr[3] } ;

dual_port_ram #(.LEN(65536)) fg_rom (
    .clock_a ( clk_sys ),
    .address_a ( fg_rom_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( fg_rom_data ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[15:0] ),
    .wren_b ( fg_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );   
   
wire        prog_cache_rom_cs;    
wire [15:0] prog_cache_data;
wire        prog_cache_valid;    
wire [23:1] prog_cache_addr;

wire        sound_cache_rom_cs;    
wire [7:0]  sound_cache_data;
wire        sound_cache_valid;    
wire [23:1] sound_cache_addr;

reg  [39:0] global_count;
reg  [23:0] rom_count;
reg  [23:0] rom_2_count;
reg  [23:0] sprite_count;
reg  [23:0] sound_count;

reg  rom_count_en;
reg  rom_2_count_en;
reg  sprite_count_en;
reg  sound_count_en;

always @ (posedge clk_sys) begin
    if ( reset ) begin
        global_count <= 0;
        rom_count <= 0;
        rom_2_count <= 0;
        sprite_count <= 0;
        sound_count <= 0;
        
        rom_count_en <= 0;
        rom_2_count_en <= 0;
        sprite_count_en <= 0;
        sound_count_en <= 0;        
    end else begin
        if ( vbl == 1 ) begin
            global_count <= 0;
            rom_count <= 0;
            rom_2_count <= 0;
            sprite_count <= 0;
            sound_count <= 0;
        end else begin
            global_count <= global_count + 1;

            rom_count_en <= ( rom_count_en | prog_cache_rom_cs ) & ~prog_cache_valid;
            if ( rom_count_en == 1 ) begin
                rom_count <= rom_count + 1;
            end

            rom_2_count_en <= ( rom_2_count_en | m68k_rom_2_cs ) & ~m68k_rom_2_valid;
            if ( rom_2_count_en == 1 ) begin
                rom_2_count <= rom_2_count + 1;
            end

            sprite_count_en <= ( sprite_count_en | sprite_cache_cs ) & ~sprite_cache_valid;
            if ( sprite_count_en == 1 ) begin
                sprite_count <= sprite_count + 1;
            end

            sound_count_en <= ( sound_count_en | z80_banked_cs ) & ~z80_banked_valid;
            if ( sound_count_en == 1 ) begin
                sound_count <= sound_count + 1;
            end        
        end
    end
end

rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
//    .prog_rom_cs(m68k_rom_cs),
//    .prog_rom_oe(1),
//    .prog_rom_addr(m68k_a[23:1]),
//    .prog_rom_data(m68k_rom_data),
//    .prog_rom_data_valid(m68k_rom_valid),

    .prog_rom_cs(prog_cache_rom_cs),
    .prog_rom_oe(1),
    .prog_rom_addr(prog_cache_addr),
    .prog_rom_data(prog_cache_data),
    .prog_rom_data_valid(prog_cache_valid),

    .prog_rom_2_cs(m68k_rom_2_cs),
    .prog_rom_2_oe(1),
    .prog_rom_2_addr(m68k_a[23:1]),
    .prog_rom_2_data(m68k_rom_2_data),
    .prog_rom_2_data_valid(m68k_rom_2_valid),

    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_data),
    .sprite_rom_data_valid(sprite_rom_valid),
    
//    .sprite_rom_cs(sprite_cache_cs),
//    .sprite_rom_oe(1),
//    .sprite_rom_addr(sprite_cache_addr),
//    .sprite_rom_data(sprite_cache_data),
//    .sprite_rom_data_valid(sprite_cache_valid),
    
    // sound ROM interface
//    .sound_rom_cs(z80_banked_cs),
//    .sound_rom_oe(1),
//    .sound_rom_addr(z80_rom_addr),
//    .sound_rom_data(z80_banked_data),
//    .sound_rom_data_valid(z80_banked_valid),   

    // to rom controller
    .sound_rom_cs(sound_cache_rom_cs),
    .sound_rom_oe(1),
    .sound_rom_addr(sound_cache_addr),
    .sound_rom_data(sound_cache_data),
    .sound_rom_data_valid(sound_cache_valid),

    // IOCTL interface
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_dout),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_download(ioctl_download),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_q(sdram_q)
  );

cache prog_cache
(
    .reset(reset),
    .clk(clk_sys),

    // client
    .cache_req(m68k_rom_cs),
    .cache_addr(m68k_a[17:1]),
    .cache_valid(m68k_rom_valid),
    .cache_data(m68k_rom_data),

    // to rom controller
    .rom_req(prog_cache_rom_cs),
    .rom_addr(prog_cache_addr),
    .rom_valid(prog_cache_valid),
    .rom_data(prog_cache_data)
); 

//tile_cache tile_cache
//(
//    .clk(clk_sys),
//    .reset(reset),
//
//    // client
//    .cache_req(sprite_rom_cs),
//    .cache_addr(sprite_rom_addr),
//    .cache_data(sprite_rom_data),
//    .cache_valid(sprite_rom_valid),
//
//    // to rom controller
//    .rom_req(sprite_cache_cs),
//    .rom_addr(sprite_cache_addr),
//    .rom_data(sprite_cache_data),
//    .rom_valid(sprite_cache_valid)
//
//); 

sound_cache sound_cache
(
    .clk(clk_sys),
    .reset(reset),

    // client
    .cache_req(z80_banked_cs),
    .cache_addr(z80_rom_addr),
    .cache_data(z80_banked_data),
    .cache_valid(z80_banked_valid),

    // to rom controller
    .rom_req(sound_cache_rom_cs),
    .rom_addr(sound_cache_addr),
    .rom_data(sound_cache_data),
    .rom_valid(sound_cache_valid)

); 


reg  [22:0] sdram_addr;
reg  [31:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

sdram #(.CLK_FREQ( (CLKSYS+0.0))) sdram
(
  .reset(~pll_locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  
  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);    

endmodule

module delay
(
    input clk,
    input clk_en,
    input i,
    output o
);

reg [5:0] r;

assign o = r[0]; 

always @(posedge clk) begin
    if ( clk_en == 1 ) begin
        r <= { r[4:0], i };
    end
end

endmodule

//// N > M, N > 1
//module clock_divider
//#(parameter N=2, parameter M=1)
//(
//    input reset,
//    input clk_in,
//    output clk_out
//);
//
//reg [15:0] count;
//
//always @ (posedge clk_in) begin
//    if ( reset == 1 ) begin
//        clk_out <= 0;
//        count <= 0;
//    end else begin
//        clk_out <= 0;
//        if ( count > (N-1) ) begin // N ( divider - 1 )
//            clk_20M <= 1 ;
//            count <= count - (N-M-1);
//        end else begin
//            count <= count + M; // M ( muliplier )
//        end
//    end
//end

// endmodule

