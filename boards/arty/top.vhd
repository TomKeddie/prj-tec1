-------------------------------------------------------------------------------
-- Title      : Arty tec1 top sheet
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     :   <tom@z400>
-- Company    : 
-- Created    : 2018-07-01
-- Last update: 2018-08-12
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
      g_sim_speedup      : natural := 1;
      g_clk_period_ns    : real    := 10.0;
      g_monitor_filename : string;
      g_util_filename    : string
      );
  port
    (
      CLK100MHZ : in    std_logic;
      jb        : inout std_logic_vector(7 downto 0); -- discrete keys and display
      jc        : inout std_logic_vector(7 downto 0)  -- key matrix
      );
end entity;



architecture rtl of top is
  constant c_clock_freq : natural := 4_000_000;

  signal clk_2m        : std_logic;
  signal clk_4m        : std_logic;
  signal clk_2m_toggle : std_logic := '0';
  signal clk_4m_toggle : std_logic := '0';
  signal clk           : std_logic;
  signal clk_100m      : std_logic;

  signal reset       : std_logic := '0';
  signal mmcm_locked : std_logic;
  signal tm1638_data : std_logic;
  signal tm1638_clk  : std_logic;
  signal tm1638_stb  : std_logic;

  signal keypad_row      : std_logic_vector(3 downto 0);
  signal keypad_column   : std_logic_vector(3 downto 0) := (others => '0');
  signal keypad_discrete : std_logic_vector(3 downto 0) := (others => '0');

  signal keypad_data   : std_logic_vector(4 downto 0) := (others => '0');
  signal keypad_data_v : std_logic                    := '0';


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
        clkin1_period    => g_clk_period_ns,
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

    clk_100m <= clk_100m_ibuf;
  end block;

  keypad_b : block
    -- tec-1 layout
    -- AD  3  7  B  F
    -- GO  2  6  A  E
    --  -  1  5  9  D
    --  +  0  4  8  C

    -- key codes
    -- 0-F 0b00000-0b01111 (00-15)
    -- +   0b10000 (16)
    -- -   0b10001 (17)
    -- GO  0b10010 (18)
    -- AD  0b10011 (19)
    
    -- keypad layout
    --    *L1  L2  L3  L4**
    -- S1  K13 K9  K5  K1 *R1*
    -- S2  K14 K10 K6  K2 *R2*
    -- S3  K15 K11 K7  K3 *R3*
    -- S4  K16 K12 K8  K4 *R4*

    -- JC(0) => L1
    -- JC(1) => L2
    -- JC(2) => L3
    -- JC(3) => L4
    -- JC(4) <= R1
    -- JC(5) <= R2
    -- JC(6) <= R3
    -- JC(7) <= R4

    type t_keys is array (19 downto 0) of natural range 19 downto 0;
    constant c_key_translate : t_keys  := (19 => 16, -- +
                                           18 => 17, -- -
                                           17 => 18, -- GO
                                           16 => 19, -- AD
                                           03 => 12, -- C (K4/L4R4)
                                           02 => 13, -- D (K3/L4R3)
                                           01 => 14, -- E (K2/L4R2)
                                           00 => 15, -- F (K1/L4R1)
                                           07 => 08, -- 8 (K8/L3R4)    
                                           06 => 09, -- 9 (K7/L3R3)    
                                           05 => 10, -- A (K6/L3R2)    
                                           04 => 11, -- B (K5/L3R1)    
                                           11 => 04, -- 4 (K12/L2R4) 
                                           10 => 05, -- 5 (K11/L2R3) 
                                           09 => 06, -- 6 (K10/L2R2) 
                                           08 => 07, -- 7 (K9/L2R1)  
                                           15 => 00, -- 0 (K16/L1R4)
                                           14 => 01, -- 1 (K15/L1R3)
                                           13 => 02, -- 2 (K14/L1R2)
                                           12 => 03  -- 3 (K13/L1R1)
                                           );






    constant c_2_5_ms_divider : natural := integer((0.0025 * real(c_clock_freq) / real(g_sim_speedup)) - 1.0);

    signal divider    : natural range 0 to c_2_5_ms_divider                                                        := 0;
    signal allkeys    : std_logic_vector(keypad_discrete'length+keypad_column'length*keypad_row'length-1 downto 0) := (others => '0');
    signal allkeys_1d : std_logic_vector(allkeys'range)                                                            := (others => '0');
    signal allkeys_2d : std_logic_vector(allkeys'range)                                                            := (others => '0');
    signal column     : natural range keypad_column'length-1 downto 0                                              := 0;
  begin
    keypad_column <= "1110" when column = 0 else "1101" when column = 1 else "1011" when column = 2 else "0111";

    keypad_p : process(clk)
    begin
      if rising_edge(clk) then
        keypad_data_v <= '0';
        if divider = 0 then
          divider <= c_2_5_ms_divider;
          -- column scanning
          if column = 0 then
            -- sample discretes
            allkeys(allkeys'high downto allkeys'high-keypad_discrete'length+1) <= not keypad_discrete;
            -- update column
            column                                                             <= keypad_column'length-1;
            -- look for keypress 
            allkeys_1d                                                         <= allkeys;
            allkeys_2d                                                         <= allkeys_1d;
            for ix in allkeys'range loop
              if allkeys_2d(ix) = '0' and allkeys_1d(ix) = '1' and allkeys(ix) = '1' then
                keypad_data   <= std_logic_vector(to_unsigned(c_key_translate(ix), keypad_data'length));
                keypad_data_v <= '1';
              end if;
            end loop;
          else
            column <= column - 1;
          end if;
          -- sample each row, pipeline previous data
          allkeys(column*keypad_column'length+3 downto column*keypad_column'length) <= not keypad_row;
        else
          divider <= divider - 1;
        end if;
      end if;
    end process;

    dbg_b : block
      component ila_0 is
        port (
          clk          : IN  STD_LOGIC;
          trig_out     : OUT STD_LOGIC;
          trig_out_ack : IN  STD_LOGIC;
          trig_in      : IN  STD_LOGIC;
          trig_in_ack  : OUT STD_LOGIC;
          probe0       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0));
      end component ila_0;
      signal probe0       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    begin
      ila_0_1: ila_0
        port map (
          clk          => clk_100m,
          trig_out     => open,
          trig_out_ack => '0',
          trig_in      => '0',
          trig_in_ack  => open,
          probe0       => probe0);

      probe0(3 downto 0) <= keypad_column;
      probe0(7 downto 4) <= keypad_row;
      probe0(12 downto 8) <=  keypad_data;
      probe0(13) <= keypad_data_v;
      probe0(31 downto 16) <= allkeys(15 downto 0);
    end block;
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
  keypad_discrete <= jb(7 downto 4);
  jb(0)           <= tm1638_clk;
  jb(1)           <= tm1638_data;
  jb(2)           <= tm1638_stb;
  jb(7 downto 3)  <= (others => 'Z');

  -- PMOD C
  keypad_row     <= jc(7 downto 4);
  jc(3 downto 0) <= keypad_column;
  jc(7 downto 4) <= (others => 'Z');


end architecture;
