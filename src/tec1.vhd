-- TEC-1 FPGA implementation

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;


entity tec1 is
  generic
    (
      g_sim              : boolean := false;
      g_monitor_filename : string;
      g_util_filename    : string
      );
  port
    (
      clk_in       : in  std_logic;
      reset_in     : in  std_logic := '0';
      clock_locked : in  std_logic := '1';
      -- TM1638 display data
      tm1638_data  : out std_logic;
      tm1638_clk   : out std_logic;
      tm1638_stb   : out std_logic;
      -- MISC io
      speaker_out  : out std_logic;
      keypad_in    : in  std_logic_vector(4 downto 0);
      keypad_dv    : in  std_logic
      );
end entity;

architecture rtl of tec1 is

  component z80_top_direct_n port (
    nM1     : out std_logic;
    nMREQ   : out std_logic;
    nIORQ   : out std_logic;
    nRD     : out std_logic;
    nWR     : out std_logic;
    nRFSH   : out std_logic;
    nHALT   : out std_logic;
    nBUSACK : out std_logic;

    nWAIT  : in std_logic;
    nINT   : in std_logic;
    nNMI   : in std_logic;
    nRESET : in std_logic;
    nBUSRQ : in std_logic;

    CLK : in    std_logic;
    A   : out   std_logic_vector(15 downto 0);
    D   : inout std_logic_vector(7 downto 0)
    );
  end component;

  type t_2kX8_memory is array(0 to 2047) of std_logic_vector(7 downto 0);

  impure function init_from_file (file_name : in string) return t_2kX8_memory is
    file ram_file          : text is in file_name;
    variable ram_file_line : line;
    variable ram           : t_2kX8_memory;
    variable good          : boolean;
  begin
    for ix in ram'range loop
      readline (ram_file, ram_file_line);
      hread(ram_file_line, ram(ix));
    end loop;
    return ram;
  end function;

  constant c_mem_addr_rom0 : std_logic_vector(2 downto 0) := "000";  -- 0x0000
  constant c_mem_addr_ram1 : std_logic_vector(2 downto 0) := "001";  -- 0x0800
  constant c_mem_addr_ram2 : std_logic_vector(2 downto 0) := "010";  -- 0x1000
  constant c_mem_addr_rom3 : std_logic_vector(2 downto 0) := "011";  -- 0x1800

  constant c_io_addr_keypad           : std_logic_vector(2 downto 0) := "000";
  constant c_io_addr_display_digits   : std_logic_vector(2 downto 0) := "001";
  constant c_io_addr_display_segments : std_logic_vector(2 downto 0) := "010";

  signal rom0_mon2 : t_2kX8_memory := init_from_file(g_monitor_filename);
  signal ram1      : t_2kX8_memory;
  signal ram2      : t_2kX8_memory;
  signal rom3      : t_2kX8_memory := init_from_file(g_util_filename);

  signal rom0_rd : std_logic;
  signal ram1_wr : std_logic;
  signal ram1_rd : std_logic;
  signal ram2_wr : std_logic;
  signal ram2_rd : std_logic;
  signal rom3_rd : std_logic;

  signal keypad_rd             : std_logic;
  signal display_segments_wr   : std_logic;
  signal display_segments      : std_logic_vector(7 downto 0) := (others => '0');
  signal display_digits_wr     : std_logic;
  signal display_digits        : std_logic_vector(5 downto 0) := (others => '0');
  type t_display_segments is array(display_digits'range) of std_logic_vector(display_segments'range);
  signal seven_segment_display : t_display_segments           := (others => x"55");
  signal keypad_data           : std_logic_vector(4 downto 0) := (others => '0');

  signal speaker : std_logic;

  signal clk_cpu      : std_logic;
  signal reset        : std_logic := '1';
  signal clock_stable : std_logic := '0';

  signal nM1     : std_logic;
  signal nMREQ   : std_logic;
  signal nIORQ   : std_logic;
  signal nRD     : std_logic;
  signal nWR     : std_logic;
  signal nRFSH   : std_logic;
  signal nHALT   : std_logic;
  signal nBUSACK : std_logic;
  signal nWAIT   : std_logic;
  signal nINT    : std_logic;
  signal nNMI    : std_logic;
  signal nRESET  : std_logic;
  signal nBUSRQ  : std_logic;
  signal CLK     : std_logic;
  signal A       : std_logic_vector(15 downto 0);
  signal D       : std_logic_vector(7 downto 0);
  signal DIN     : std_logic_vector(7 downto 0);
  signal DOUT    : std_logic_vector(7 downto 0);

begin

  reset  <= '1' when clock_stable = '0' or reset_in = '1' else '0';
  nRESET <= not reset;

  reset_b : block
    signal hysteresis : unsigned(7 downto 0) := (others => '0');
  begin
    reset_p : process(clk_cpu)
    begin
      if rising_edge(clk_cpu) then
        -- release reset once clock lock is stable
        if clock_locked = '0' then
          hysteresis   <= (others => '0');
          clock_stable <= '0';
        elsif hysteresis = (hysteresis'range => '1') then
          clock_stable <= '1';
        else
          hysteresis <= hysteresis - 1;
        end if;
      end if;
    end process;
  end block;
  ------------------------------------------------------------------------------------------
  -- misc io
  ------------------------------------------------------------------------------------------
  speaker_out <= speaker;
  nNMI        <= '0' when keypad_dv = '1' else '1';  -- interrupt on keypress

  ------------------------------------------------------------------------------------------
  -- tie off
  ------------------------------------------------------------------------------------------
  nWAIT   <= '1';
  nINT    <= '1';
  nBUSRQ  <= '1';
  clk_cpu <= clk_in;
  CLK     <= clk_cpu;
  ------------------------------------------------------------------------------------------
  -- DATA bus
  ------------------------------------------------------------------------------------------
  D       <= DIN when nRD = '0' and (nMREQ = '0' or nIORQ = '0') else (others => 'Z');
  DOUT    <= D;

  ------------------------------------------------------------------------------------------
  -- Memory
  ------------------------------------------------------------------------------------------
  rom0_rd <= '1' when A(13 downto 11) = c_mem_addr_rom0 and nRD = '0' and nMREQ = '0' else '0';
  ram1_wr <= '1' when A(13 downto 11) = c_mem_addr_ram1 and nWR = '0' and nMREQ = '0' else '0';
  ram1_rd <= '1' when A(13 downto 11) = c_mem_addr_ram1 and nRD = '0' and nMREQ = '0' else '0';
  ram2_wr <= '1' when A(13 downto 11) = c_mem_addr_ram2 and nWR = '0' and nMREQ = '0' else '0';
  ram2_rd <= '1' when A(13 downto 11) = c_mem_addr_ram2 and nRD = '0' and nMREQ = '0' else '0';
  rom3_rd <= '1' when A(13 downto 11) = c_mem_addr_rom3 and nRD = '0' and nMREQ = '0' else '0';

  ------------------------------------------------------------------------------------------
  -- IO
  ------------------------------------------------------------------------------------------
  keypad_rd           <= '1' when A(2 downto 0) = c_io_addr_keypad and nWR = '0' and nIORQ = '0'           else '0';
  display_segments_wr <= '1' when A(2 downto 0) = c_io_addr_display_segments and nWR = '0' and nIORQ = '0' else '0';
  display_digits_wr   <= '1' when A(2 downto 0) = c_io_addr_display_digits and nWR = '0' and nIORQ = '0'   else '0';

  periph_p : process(clk_cpu)
  begin
    if rising_edge(clk_cpu) then
      -- RAM1
      if ram1_wr = '1' then
        ram1(to_integer(unsigned(A(10 downto 0)))) <= DOUT(7 downto 0);
      elsif ram1_rd = '1' then
        DIN(7 downto 0) <= ram1(to_integer(unsigned(A(10 downto 0))));
      end if;
      -- RAM2
      if ram2_wr = '1' then
        ram2(to_integer(unsigned(A(10 downto 0)))) <= DOUT(7 downto 0);
      elsif ram2_rd = '1' then
        DIN(7 downto 0) <= ram2(to_integer(unsigned(A(10 downto 0))));
      end if;
      -- ROM0
      if rom0_rd = '1' then
        DIN(7 downto 0) <= rom0_mon2(to_integer(unsigned(A(10 downto 0))));
      end if;
      -- ROM3
      if rom3_rd = '1' then
        DIN(7 downto 0) <= rom3(to_integer(unsigned(A(10 downto 0))));
      end if;
      -- DISPLAY
      if display_segments_wr = '1' then
        display_segment_loop : for ix in display_digits'range loop
          -- write to all the digits that are enabled
          if display_digits(ix) = '1' then
            seven_segment_display(ix) <= DOUT(7 downto 0);
          end if;
        end loop;
        -- save the segments for the next digit update
        display_segments <= DOUT(7 downto 0);
      elsif display_digits_wr = '1' then
        display_digit_loop : for ix in display_digits'range loop
          if DOUT(ix) = '1' then
            seven_segment_display(ix) <= display_segments;
          end if;
        end loop;
        -- save the digits for the next row update
        display_digits <= DOUT(5 downto 0);
        -- speaker uses same address
        speaker        <= DOUT(7);
      elsif keypad_rd = '1' then
        DIN(4 downto 0) <= keypad_data;
      end if;
    end if;
  end process;

  keypad_p : process(clk_cpu)
  begin
    if rising_edge(clk_cpu) then
      if keypad_dv = '1' then
        keypad_data <= keypad_in;
      end if;
    end if;
  end process;

  -- TM1638 display driver
  -- min clock period is 800ns (1.25MHz)
  -- min strobe pulse width is 1us (1 MHz)
  -- run state machine at clk_cpu/8 = 500 kHz
  -- Command1: set display mode
  -- Command2: set data instruction
  -- Command3: set display address
  -- Data1-n: transmit display data to Command3 address and behind address(up to 14bytes)
  -- Command4: display control instruction 
  -- The bits are displayed by mapping bellow
  --  -- 0 --
  -- |       |
  -- 5       1
  --  -- 6 --
  -- 4       2
  -- |       |
  --  -- 3 --  .7
  -- 
  tm1638_b : block
    -- set display mode
    constant c_command1   : std_logic_vector(7 downto 0) := x"55";
    -- set data instruction 
    constant c_command2   : std_logic_vector(7 downto 0) := b"01_00_0_0_00";
    -- set display address *
    constant c_command3   : std_logic_vector(7 downto 0) := b"11_00_0000";  --address 0
    -- display control instruction *
    constant c_brightness : std_logic_vector(2 downto 0) := "100";  -- 11/16
    constant c_command4   : std_logic_vector(7 downto 0) := b"10_00_1" & c_brightness;


    signal clk_divider   : natural range 15 downto 0                 := 0;
    type t_state is (state_idle, state_command1, state_strobe1, state_command2, state_strobe2, state_command3, state_data, state_strobe4, state_command4);
    signal state         : t_state                                   := state_idle;
    signal next_state    : t_state                                   := state_command1;
    signal current_digit : natural range seven_segment_display'range := seven_segment_display'high;
    signal next_digit    : natural range seven_segment_display'range := seven_segment_display'high;
    signal data          : std_logic_vector(7 downto 0)              := (others => '0');
    signal data_valid    : boolean                                   := false;
    signal current_bit   : natural range data'range                  := data'high;
  begin

    tm1638_data <= data(current_bit);

    process(clk_cpu, reset)
    begin
      if reset = '1' then
        tm1638_clk <= '0';
        tm1638_stb <= '0';
      elsif rising_edge(clk_cpu) then
        -- divide clock
        if clk_divider /= 15 then
          clk_divider <= clk_divider + 1;
        else
          clk_divider <= 0;
        end if;

        -- run clock where data is valid
        if clk_divider > 7 then
          if data_valid then
            tm1638_clk <= '1';
          end if;
        else
          tm1638_clk <= '0';
        end if;

        -- change state on falling edge of tm1638_clk 
        if clk_divider = 15 and not data_valid then
          state <= next_state;
        end if;

        -- shift out data on falling edge where valid
        if clk_divider = 15 and data_valid then
          if current_bit = data'low then
            data_valid  <= false;
            current_bit <= data'high;
            state       <= next_state;
          else
            current_bit <= current_bit - 1;
          end if;
        end if;

        -- state
        case state is
          when state_command1 =>
            next_state <= state_strobe1;
          when state_strobe1 =>
            next_state <= state_command2;
          when state_command2 =>
            next_state <= state_strobe2;
          when state_strobe2 =>
            next_state <= state_command3;
          when state_command3 =>
            next_state <= state_data;
          when state_data =>
            if current_digit = seven_segment_display'low then
              next_digit <= seven_segment_display'high;
              next_state <= state_strobe4;
            elsif not data_valid then
              next_digit <= next_digit - 1;
            end if;
          when state_strobe4 =>
            next_state <= state_command4;
          when state_command4 =>
            next_state <= state_idle;
          when others =>                -- idle
            next_state <= state_command1;
        end case;

        -- data
        if not data_valid then
          tm1638_stb <= '0';
          case state is
            when state_command1 =>
              data       <= c_command1;
              data_valid <= true;
            when state_strobe1|state_strobe2|state_strobe4 =>
              tm1638_stb <= '1';
            when state_command2 =>
              data       <= c_command2;
              data_valid <= true;
            when state_command3 =>
              data       <= c_command3;
              data_valid <= true;
            when state_command4 =>
              data       <= c_command4;
              data_valid <= true;
            when state_data =>
              data          <= seven_segment_display(current_digit);
              current_digit <= next_digit;
              data_valid    <= true;
            when others =>              -- idle
              tm1638_stb <= '1';
          end case;
        end if;

      end if;
    end process;
  end block;

  z80_top_direct_n_1 : z80_top_direct_n
    port map (
      nM1     => nM1,
      nMREQ   => nMREQ,
      nIORQ   => nIORQ,
      nRD     => nRD,
      nWR     => nWR,
      nRFSH   => nRFSH,
      nHALT   => nHALT,
      nBUSACK => nBUSACK,
      nWAIT   => nWAIT,
      nINT    => nINT,
      nNMI    => nNMI,
      nRESET  => nRESET,
      nBUSRQ  => nBUSRQ,
      CLK     => CLK,
      A       => A,
      D       => D);
end architecture;
