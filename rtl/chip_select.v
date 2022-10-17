//

module chip_select
(
    input        clk,
    input  [3:0] pcb,

    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_rw,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,
    input        RD_n,
    input        WR_n,
    input        M1_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_rom_2_cs,
    output reg m68k_ram_cs,
    output reg m68k_spr_cs,
    output reg m68k_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg m68k_sp85_cs,
    output reg m68k_coin_cs,

    output reg input_p1_cs,
    output reg input_p2_cs,
    output reg input_dsw1_cs,
    output reg input_dsw2_cs,
    output reg input_coin_cs,
    
    output reg vbl_int_clr_cs,
    output reg cpu_int_clr_cs,
    output reg watchdog_clr_cs,
    
    output reg m68k_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,

    output reg   z80_latch_cs,
    output reg   z80_latch_clr_cs,
    output reg   z80_dac_cs,
    output reg   z80_ym2413_cs, // OPN YM2413
    output reg   z80_ym2203_cs, // OPLL YM2203
    output reg   z80_bank_set_cs,
    output reg   z80_banked_cs
);


function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( m68k_a[23:0] >= start_address && m68k_a[23:0] <= end_address) & !m68k_as_n;
end
endfunction

function z80_mem_cs;
        input [15:0] base_address;
        input  [7:0] width;
begin
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n ;
end
endfunction

localparam SKYADV      = 0;
localparam GANGWARS    = 1;
localparam TIMESOLD    = 2;

always @ (*) begin
    // Memory mapping based on PCB type
    case (pcb)
        SKYADV, GANGWARS, TIMESOLD: begin
            //	map(0x000000, 0x03ffff).rom();
            m68k_rom_cs      <= m68k_cs( 24'h000000, 24'h03ffff ) ;
            
            //	map(0x040000, 0x043fff).ram().share("shared_ram");
            m68k_ram_cs      <= m68k_cs( 24'h040000, 24'h043fff ) ;
            
            //	map(0x080001, 0x080001).w(m_soundlatch, FUNC(generic_latch_8_device::write)); 0x80001  
            m68k_latch_cs    <= m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;
            
            input_p1_cs      <= m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;
            
            input_p2_cs      <= 0 ;

            input_coin_cs    <= m68k_cs( 24'h080004, 24'h080005 ) ;
            
            
//            m68k_spr_flip_cs <= m68k_cs( 24'h0c0000, 24'h0c0001 );
            
//                <= m68k_cs( 24'h0f0000, 24'h0f0001 ) ;
            
            //	map(0x0c0000, 0x0c0001).lr16(NAME([this] () -> u16 { return m_in[3]->read(); })); /* Dip 2 */
            input_dsw1_cs     <= m68k_cs( 24'h0c0000, 24'h0c0001 ) ;
            
            //	map(0x100000, 0x100fff).ram().w(FUNC(alpha68k_III_state::videoram_w)).share("videoram");
            m68k_fg_ram_cs   <= m68k_cs( 24'h100000, 24'h100fff )  ;
            
            //	map(0x200000, 0x207fff).rw(m_sprites, FUNC(snk68_spr_device::spriteram_r), FUNC(snk68_spr_device::spriteram_w)).share("spriteram");
            m68k_spr_cs      <= m68k_cs( 24'h200000, 24'h207fff ) ;
            
            //	map(0x300000, 0x303fff).r(FUNC(alpha68k_III_state::alpha_V_trigger_r));
            input_dsw2_cs    <= 0 ;
            m68k_coin_cs     <= 0 ;
            
            m68k_sp85_cs     <= m68k_cs( 24'h300000, 24'h303fff ) ;
            
            //	map(0x400000, 0x401fff).rw(m_palette, FUNC(alpha68k_palette_device::read), FUNC(alpha68k_palette_device::write));
            m68k_pal_cs      <= m68k_cs( 24'h400000, 24'h401fff ) ;

            //	map(0x800000, 0x83ffff).rom().region("maincpu", 0x40000);
            m68k_rom_2_cs    <= m68k_cs( 24'h800000, 24'h83ffff ) ;
            
            // reset microcontroller interrupt 
            cpu_int_clr_cs    <= m68k_cs( 24'h0d8000, 24'h0dffff ) ; // tst.b $d8000.l
            
            // reset vblank interrupt 
            vbl_int_clr_cs    <= m68k_cs( 24'h0e0000, 24'h0e7fff ) ; // tst.b $e0000.l
            
            // reset watchdog interrupt ( implement? )
            watchdog_clr_cs   <= m68k_cs( 24'h0e8000, 24'h0effff ) ; // tst.b $e8000.l
             
            z80_rom_cs        <= ( MREQ_n == 0 && z80_addr[15:0] <  16'h8000 );
            z80_ram_cs        <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'h8000 && z80_addr[15:0] < 16'h8800 );
            z80_banked_cs     <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hc000 );
            
            // read latch.  latch is active on all i/o reads
            z80_latch_cs      <= (!IORQ_n) && (!RD_n) ; 
            
            z80_latch_clr_cs  <= ( z80_addr[3:1] == 3'b000 ) && ( !IORQ_n ) && (!WR_n);  
            
            // only the lower 4 bits are used to decode port
            // 0x08-0x09
            z80_dac_cs        <= ( z80_addr[3:1] == 3'b100 ) && ( !IORQ_n ) && (!WR_n) ; // 8 bit DAC
            
            // 0x0a-0x0b
            z80_ym2413_cs     <= ( z80_addr[3:1] == 3'b101 ) && ( !IORQ_n ) && (!WR_n); 
            
            // 0x0c-0x0d
            z80_ym2203_cs     <= ( z80_addr[3:1] == 3'b110 ) && ( !IORQ_n ) && (!WR_n); 
            
            // 0x0E-0x0F
            z80_bank_set_cs   <= ( z80_addr[3:1] == 3'b111 ) && ( !IORQ_n ) && (!WR_n); // select latches z80 D[4:0]
        end

        GANGWARS: begin
            //	map(0x000000, 0x03ffff).rom();
            m68k_rom_cs      <= m68k_cs( 24'h000000, 24'h03ffff ) ;

            //	map(0x040000, 0x043fff).ram().share("shared_ram");
            m68k_ram_cs      <= m68k_cs( 24'h040000, 24'h043fff ) ; 

            //	map(0x080001, 0x080001).w(m_soundlatch, FUNC(generic_latch_8_device::write)); 0x80001
            m68k_latch_cs    <= m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;

            input_p1_cs      <= m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;

            input_p2_cs      <= m68k_cs( 24'h080002, 24'h080003 ) ;

            input_coin_cs    <= m68k_cs( 24'h080004, 24'h080005 ) ;

            input_dsw1_cs    <= m68k_cs( 24'h0f0000, 24'h0f0001 ) ;

            input_dsw2_cs     <= m68k_cs( 24'h0c0000, 24'h0c0001 ) ;

            //	map(0x100000, 0x100fff).ram().w(FUNC(alpha68k_III_state::videoram_w)).share("videoram");
            m68k_fg_ram_cs   <= m68k_cs( 24'h100000, 24'h100fff )  ;

            //	map(0x200000, 0x207fff).rw(m_sprites, FUNC(snk68_spr_device::spriteram_r), FUNC(snk68_spr_device::spriteram_w)).share("spriteram");
            m68k_spr_cs      <= m68k_cs( 24'h200000, 24'h207fff ) ;

            //	map(0x300000, 0x303fff).r(FUNC(alpha68k_III_state::alpha_V_trigger_r));
            m68k_sp85_cs     <= m68k_cs( 24'h300000, 24'h303fff ) ;

            //	map(0x400000, 0x401fff).rw(m_palette, FUNC(alpha68k_palette_device::read), FUNC(alpha68k_palette_device::write));
            m68k_pal_cs      <= m68k_cs( 24'h400000, 24'h401fff ) ;

            //	map(0x800000, 0x83ffff).rom().region("maincpu", 0x40000);
            m68k_rom_2_cs    <= m68k_cs( 24'h800000, 24'h83ffff ) ;

            // reset microcontroller interrupt 
            cpu_int_clr_cs    <= m68k_cs( 24'h0d8000, 24'h0dffff ) ; // tst.b $d8000.l

            // reset vblank interrupt 
            vbl_int_clr_cs    <= m68k_cs( 24'h0e0000, 24'h0e7fff ) ; // tst.b $e0000.l

            // reset watchdog interrupt ( implement? )
            watchdog_clr_cs   <= m68k_cs( 24'h0e8000, 24'h0effff ) ; // tst.b $e8000.l

            z80_rom_cs        <= ( MREQ_n == 0 && z80_addr[15:0] <  16'h8000 );
            z80_ram_cs        <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'h8000 && z80_addr[15:0] < 16'h8800 );
            z80_banked_cs     <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hc000 );

            // read latch.  latch is active on all i/o reads
            z80_latch_cs      <= (!IORQ_n) && (!RD_n) ; 

            z80_latch_clr_cs  <= ( z80_addr[3:1] == 3'b000 ) && ( !IORQ_n ) && (!WR_n);  

            // only the lower 4 bits are used to decode port
            // 0x08-0x09
            z80_dac_cs        <= ( z80_addr[3:1] == 3'b100 ) && ( !IORQ_n ) && (!WR_n) ; // 8 bit DAC

            // 0x0a-0x0b
            z80_ym2413_cs     <= ( z80_addr[3:1] == 3'b101 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0c-0x0d
            z80_ym2203_cs     <= ( z80_addr[3:1] == 3'b110 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0E-0x0F
            z80_bank_set_cs   <= ( z80_addr[3:1] == 3'b111 ) && ( !IORQ_n ) && (!WR_n); // select latches z80 D[4:0]
        end

        default:;
    endcase

end

//	map(0x0000, 0x7fff).rom();
//	map(0x8000, 0x87ff).ram();
//	map(0xc000, 0xffff).bankr("audiobank");

//	map(0x00, 0x00).mirror(0x0f).r(m_soundlatch, FUNC(generic_latch_8_device::read));
//	map(0x00, 0x00).mirror(0x01).w(m_soundlatch, FUNC(generic_latch_8_device::clear_w));
//	map(0x08, 0x08).mirror(0x01).w("dac", FUNC(dac_byte_interface::data_w));
//	map(0x0a, 0x0b).w("ym2", FUNC(ym2413_device::write));
//	map(0x0c, 0x0d).w("ym1", FUNC(ym2203_device::write));
//	map(0x0e, 0x0e).mirror(0x01).w(FUNC(alpha68k_II_state::sound_bank_w));

//	map(0x080000, 0x080001).r(FUNC(alpha68k_III_state::control_1_r)); /* Joysticks */

//	map(0x0c0001, 0x0c0001).select(0x78).w(FUNC(alpha68k_III_state::outlatch_w));

//	map(0x300000, 0x303fff).r(FUNC(alpha68k_III_state::alpha_V_trigger_r));
//	map(0x300000, 0x3001ff).w(FUNC(alpha68k_III_state::alpha_microcontroller_w));
//	map(0x303e00, 0x303fff).w(FUNC(alpha68k_III_state::alpha_microcontroller_w)); /* Gang Wars mirror */

endmodule
