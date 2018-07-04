set clk_4m_pin [get_pins -filter {NAME =~ mmcm_b.clk_4m_buf/O}]
set clk_2m_pin [get_pins -filter {NAME =~ mmcm_b.clk_2m_buf/O}]

set clk_8m [get_clocks -filter {NAME=~clk_8m_mmcm}]
set clk_4m [create_generated_clock -name clk_4m -master_clock $clk_8m -divide_by 2 -source $clk_4m_pin -add $clk_4m_pin]
set clk_2m [create_generated_clock -name clk_2m -master_clock $clk_4m -divide_by 2 -source $clk_2m_pin -add $clk_2m_pin]

set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ tec1_1/z80_top_direct_n_1/*}]


