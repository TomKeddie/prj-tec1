-------------------------------------------------------------------------------
-- Title      : Arty tec1 top sheet
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_top.vhd
-- Author     :   <tom@z400>
-- Company    : 
-- Created    : 2018-07-01
-- Last update: 2018-07-17
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


entity tb_top is
end entity;



architecture rtl of tb_top is
  constant c_monitor_filename : string := "../../../../../../common/mon2.hex";
  constant c_util_filename    : string := "../../../../../../common/util.hex";

  constant c_clk_freq      : natural := 1_000_000_000;
  constant c_clk_period_ns : real    := 1.0**9/c_clk_freq;
  constant c_sim_speedup   : natural := 1000;
  constant c_one_hz_count  : natural := c_clk_freq/c_sim_speedup;

  signal CLK100MHZ : std_logic                    := '0';
  signal jb        : std_logic_vector(7 downto 0) := (others => '0');
  signal jc        : std_logic_vector(7 downto 0) := (others => '0');

  signal one_hz  : unsigned(31 downto 0) := to_unsigned(c_one_hz_count, 32);
  signal pressed : boolean               := false;

  signal keypad_row    : std_logic_vector(3 downto 0) := (others => '0');
  signal keypad_column : std_logic_vector(3 downto 0);

begin

  CLK100MHZ <= not CLK100MHZ after 1 sec * 0.5/c_clk_freq;

  top_1 : entity work.top
    generic map (
      g_sim              => true,
      g_sim_speedup      => c_sim_speedup,
      g_clk_period_ns    => c_clk_period_ns,
      g_monitor_filename => c_monitor_filename,
      g_util_filename    => c_util_filename)
    port map (
      CLK100MHZ => CLK100MHZ,
      jb        => jb,
      jc        => jc);

  jc(7 downto 4) <= keypad_row;
  keypad_column  <= jc(3 downto 0);

  divider_p : process(CLK100MHZ)
  begin
    if rising_edge(CLK100MHZ) then
      keypad_row     <= "0000";
      jb(7 downto 4) <= "0000";
      if one_hz = (one_hz'range => '0') then
        one_hz  <= to_unsigned(c_one_hz_count, 32);
        pressed <= not pressed;
      else
        one_hz <= one_hz - 1;
      end if;

      if pressed and keypad_column = "0001" then
        keypad_row <= "1000";
      end if;
    end if;
  end process;

end architecture;
