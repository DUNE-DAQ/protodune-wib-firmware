library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


entity tb is
  port (
    clk_128Mhz   : in std_logic;
    clk_62_5Mhz   : in std_logic;
    tb_reset : in std_logic);
end entity tb;


architecture behavioral of tb is

  component CD_Stream_Processor is
    generic (
      IS_LINK_A : std_logic);
    port (
      clk_CD          : in  std_logic;
      reset_CD        : in  std_logic;
      COLDATA_stream  : in  std_logic_vector(8 downto 0);
      convert         : in  convert_t;
      clk_EVB         : in  std_logic;
      reset_EVB       : in  std_logic;
      CD_to_EB_stream : out CD_Stream_t;
      EB_rd           : in  std_logic;
      monitor         : out CD_Stream_Monitor_t;
      control         : in  CD_Stream_Control_t);
  end component CD_Stream_Processor;

  signal COLDATA_stream  : std_logic_vector(8 downto 0);
  signal convert         : convert_t;
  signal CD_to_EB_stream : CD_Stream_t;    
  signal EB_rd           : std_logic;
  signal control         : CD_Stream_Control_t;

  
begin  -- architecture behavioral

  clk_CD    <= clk_128Mhz;
  clk_EVB   <= clk_62_5Mhz;

  
  input_128: process (clk_128Mhz,reset_tb) is
  begin  -- process input
    if reset_tb = '1' then
      reset_CD <= '0';
      counter_CDA <= 0;
    elsif clk_128Mhz'event and clk_128Mhz = '1' then
      counter_CDA <= counter_CDA + 1;
      case counter_CDA is
        when 0 to 2 => reset_CD <= '0';
        when 3 => reset_CD <= '1';
                  
        when others => null;
      end case;
    end if;
  end process input;


  CD_Stream_Processor_1: entity work.CD_Stream_Processor
    generic map (
      IS_LINK_A => '1')
    port map (
      clk_CD          => clk_CD,
      reset_CD        => reset_CD,
      COLDATA_stream  => COLDATA_stream,
      convert         => convert,
      clk_EVB         => clk_EVB,
      reset_EVB       => reset_EVB,
      CD_to_EB_stream => CD_to_EB_stream,
      EB_rd           => EB_rd,
      monitor         => open,
      control         => control);
  
end architecture behavioral;
