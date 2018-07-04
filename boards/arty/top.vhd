-------------------------------------------------------------------------------
-- Title      : Arty tec1 top sheet
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     :   <tom@z400>
-- Company    : 
-- Created    : 2018-07-01
-- Last update: 2018-07-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2018 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-07-01  1.0      tom Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;


entity top is
  generic
    (
      g_sim              : boolean := false;
      g_monitor_filename : string;
      g_util_filename    : string
      );
  port
    (
      CLK100MHZ : in  std_logic;
      jb        : out std_logic_vector(2 downto 0);
      jc        : inout std_logic_vector(7 downto 0)
      );
end entity;



architecture rtl of top is
  signal clk_in        : std_logic;
  signal clk_2m        : std_logic;
  signal clk_4m        : std_logic;
  signal clk_2m_toggle : std_logic := '0';
  signal clk_4m_toggle : std_logic := '0';

  signal reset       : std_logic := '0';
  signal mmcm_locked : std_logic;
  signal tm1638_data : std_logic;
  signal tm1638_clk  : std_logic;
  signal tm1638_stb  : std_logic;

  signal keypad_row    : std_logic_vector(3 downto 0);
  signal keypad_column : std_logic_vector(3 downto 0) := (others => '0');

  signal keypad_data : std_logic_vector(4 downto 0) := (others => '0');
  signal keypad_dv   : std_logic                    := '0';


begin

  keypad_row     <= jc(7 downto 4);
  jc(3 downto 0) <= keypad_column;

  mmcm_b : block
    signal clk_100m_ibuf : std_logic;
    signal clk_8m        : std_logic;
    signal clk_8m_mmcm   : std_logic;
    signal clkfbout      : std_logic;
    signal clkfbout_buf  : std_logic;
  begin
    clk100mhz_ibufg : unisim.vcomponents.ibuf
      generic map(
        iostandard => "default"
        )
      port map (
        I => CLK100MHZ,
        O => clk_100m_ibuf
        );

    mmcm_inst : unisim.vcomponents.mmcme2_base
      generic map(
        bandwidth        => "optimized",
        clkfbout_mult_f  => 10.000000,
        clkfbout_phase   => 0.000000,
        clkin1_period    => 10.000000,
        clkout0_divide_f => 125.000000
        )
      port map (
        clkfbin  => clkfbout_buf,
        clkfbout => clkfbout,
        clkin1   => clk_100m_ibuf,
        clkout0  => clk_8m_mmcm,
        locked   => mmcm_locked,
        pwrdwn   => '0',
        rst      => '0'
        );

    clk_8m_buf : unisim.vcomponents.BUFG
      port map (
        I => clk_8m_mmcm,
        O => clk_8m
        );

    clk_4m_buf : unisim.vcomponents.BUFG
      port map (
        I => clk_4m_toggle,
        O => clk_4m
        );

    clk_2m_buf : unisim.vcomponents.BUFG
      port map (
        I => clk_2m_toggle,
        O => clk_2m
        );

    clkf_buf : unisim.vcomponents.BUFG
      port map (
        I => clkfbout,
        O => clkfbout_buf
        );

    clk_8m_p : process(clk_8m)
    begin
      if rising_edge(clk_8m) then
        clk_4m_toggle <= not clk_4m_toggle;
      end if;
    end process;

    clk_4m_p : process(clk_4m)
    begin
      if rising_edge(clk_4m) then
        clk_2m_toggle <= not clk_2m_toggle;
      end if;
    end process;
  end block;



  tec1_1 : entity work.tec1
    generic map (
      g_monitor_filename => g_monitor_filename,
      g_util_filename    => g_util_filename,
      g_sim              => g_sim)
    port map (
      clk_in       => clk_2m,
      reset_in     => reset,
      clock_locked => mmcm_locked,
      tm1638_data  => tm1638_data,
      tm1638_clk   => tm1638_clk,
      tm1638_stb   => tm1638_stb,
      keypad_in    => keypad_data,
      keypad_dv    => keypad_dv);

  -- PMOD B
  jb(0) <= tm1638_clk;
  jb(1) <= tm1638_data;
  jb(2) <= tm1638_stb;

end architecture;
