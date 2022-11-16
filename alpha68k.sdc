derive_pll_clocks
derive_clock_uncertainty

# core specific constraints

set_false_path -from [get_clocks {pll_hdmi|pll_hdmi_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -to [get_clocks {pll_hdmi|pll_hdmi_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}]

set_false_path -from [get_clocks {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

# create_clock -name clk_4M -period "4.0 MHz" [get_nets {emu|clk_4M}]
create_generated_clock -name clk_4M -source [get_nets {emu|pll|pll_inst|altera_pll_i|outclk_wire[0]}] -divide_by 18 [get_nets {emu|clk_4M}]

# create_clock -name clk_6M -period "6.0 MHz" [get_nets {emu|clk_6M}]
create_generated_clock -name clk_6M -source [get_nets {emu|pll|pll_inst|altera_pll_i|outclk_wire[0]}] -divide_by 12 [get_nets {emu|clk_6M}]
