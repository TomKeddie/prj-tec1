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
  constant c_clock_freq : natural := 4_000_000;

  signal clk_in        : std_logic;
  signal clk_2m        : std_logic;
  signal clk_4m        : std_logic;
  signal clk_2m_toggle : std_logic := '0';
  signal clk_4m_toggle : std_logic := '0';
  signal clk           : std_logic;

  signal reset       : std_logic := '0';
  signal mmcm_locked : std_logic;
  signal tm1638_data : std_logic;
  signal tm1638_clk  : std_logic;
  signal tm1638_stb  : std_logic;

  signal keypad_row    : std_logic_vector(3 downto 0);
  signal keypad_column : std_logic_vector(3 downto 0) := (others => '0');

  signal keypad_data : std_logic_vector(4 downto 0) := (others => '0');
  signal keypad_data_v   : std_logic                    := '0';


begin

  -- 2MHz or 4MHz clock
  clock_4mhz_gen : if c_clock_freq = 4_000_000 generate
    clk <= clk_4m;
  end generate;

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

  keypad_b : block
    constant c_2_5_ms_divider : natural := integer((0.0025 * real(c_clock_freq)) - 1.0);

    signal divider : natural range 0 to c_2_5_ms_divider := 0;
    signal allkeys : std_logic_vector(keypad_column'length*keypad_row'length-1 downto 0) := (others => '0');
    signal allkeys_1d : std_logic_vector(allkeys'range) := (others => '0'); 
    signal allkeys_2d : std_logic_vector(allkeys'range) := (others => '0'); 
    signal column : natural range keypad_column'length-1 downto 0 := 0;
  begin
    keypad_column <= "0001" when column = 0 else "0010" when column = 1 else "0100" when column = 2 else "1000";

    keypad_p : process(clk)
    begin
      if rising_edge(clk) then
        keypad_data_v <= '0';
        if divider = 0 then
          divider <= c_2_5_ms_divider;
          -- column scanning
          if column = 0 then
            column <= keypad_column'length-1;
            -- look for keypress 
            allkeys_1d <= allkeys;
            allkeys_2d <= allkeys_1d;
            for ix in allkeys'range loop
              if allkeys_2d(ix) = '0' and allkeys_1d(ix) = '1' and allkeys(ix) = '1' then
                keypad_data <= std_logic_vector(to_unsigned(ix, keypad_data'length));
                keypad_data_v <= '1';
              end if;
            end loop;
          else
            column <= column - 1;
          end if;
          -- sample each row, pipeline previous data
          allkeys(column*keypad_column'length+3 downto column*keypad_column'length) <= keypad_row;
        else
          divider <= divider - 1;
        end if;
      end if;
    end process;
  end block;

  tec1_1 : entity work.tec1
    generic map (
      g_monitor_filename => g_monitor_filename,
      g_util_filename    => g_util_filename,
      g_sim              => g_sim)
    port map (
      clk_in       => clk,
      reset_in     => reset,
      clock_locked => mmcm_locked,
      tm1638_data  => tm1638_data,
      tm1638_clk   => tm1638_clk,
      tm1638_stb   => tm1638_stb,
      keypad_in    => keypad_data,
      keypad_dv    => keypad_data_v);

  -- PMOD B
  jb(0) <= tm1638_clk;
  jb(1) <= tm1638_data;
  jb(2) <= tm1638_stb;
  -- PMOD C
  keypad_row     <= jc(7 downto 4);
  jc(3 downto 0) <= keypad_column;


end architecture;
