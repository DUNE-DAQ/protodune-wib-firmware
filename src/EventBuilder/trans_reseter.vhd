library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;


entity trans_reseter is
  generic (
    TX_COUNT : integer := 4);
  port (
    sys_clk         : in  std_logic;
    sys_reset       : in  std_logic;
    pll_powerdown   : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_analogreset  : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_digitalreset : out std_logic_vector(TX_COUNT - 1 downto 0);
    pll_locked      : in  std_logic_vector(TX_COUNT - 1 downto 0);
    tx_cal_busy     : in  std_logic_vector(TX_COUNT - 1 downto 0);
    tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0));
end entity trans_reseter;  

architecture behavioral of trans_reseter is

  signal reset_state : integer range 5 downto 0;
  signal reset_counter : unsigned(11 downto 0);
  
begin  -- architecture behavioral

  tx_reseter: process (sys_clk, sys_reset) is
  begin  -- process tx_reseter
    if sys_reset = '1' then            -- asynchronous reset (active high)
      tx_ready <= (others => '0');
      reset_state  <= 0;
    elsif sys_clk'event and sys_clk = '1' then  -- rising clock edge
      case reset_state is
        when 0 => 
          pll_powerdown     <= (others => '1');
          tx_analogreset    <= (others => '1');
          tx_digitalreset   <= (others => '1');
          tx_ready          <= (others => '0');
          reset_state             <= 1;
          reset_counter           <= x"064";
        when 1 =>                 
          pll_powerdown     <= (others => '1');
          tx_analogreset    <= (others => '1');
          tx_digitalreset   <= (others => '1');
          tx_ready          <= (others => '0');
          
          if reset_counter = x"000" then
            reset_state           <= 2;
            reset_counter         <= x"1f4";
            pll_powerdown   <= (others => '0');
            tx_analogreset  <= (others => '0');            
          else
            reset_counter <= reset_counter - 1;
          end if;
        when 2 =>
          pll_powerdown     <= (others => '0');
          tx_analogreset    <= (others => '0');
          tx_digitalreset   <= (others => '1');
          tx_ready          <= (others => '0');

          if reset_counter = 0 then
            reset_state           <= 3;
            reset_counter         <= x"064";
          elsif and_reduce(pll_locked) = '1' then
            reset_counter <= reset_counter - 1;
          else
            reset_counter         <= x"1f4";
          end if;
        when 3 =>
          pll_powerdown     <= (others => '0');
          tx_analogreset    <= (others => '0');
          tx_digitalreset   <= (others => '1');
          tx_ready          <= (others => '0');
          if reset_counter = 0 then
            tx_digitalreset <= (others => '0');
            reset_state           <= 4;
            reset_counter         <= x"064";
          else
            reset_counter <= reset_counter -1;
          end if;
        when 4 =>
          pll_powerdown     <= (others => '0');
          tx_analogreset    <= (others => '0');
          tx_digitalreset   <= (others => '0');
          tx_ready          <= (others => '0');
          if and_reduce(pll_locked) = '0' then
            reset_state           <= 0;
          elsif reset_counter = 0 then
            reset_state           <= 5;
          else
            reset_counter <= reset_counter - 1;
          end if;
        when 5 =>
          pll_powerdown     <= (others => '0');
          tx_analogreset    <= (others => '0');
          tx_digitalreset   <= (others => '0');
          tx_ready          <= (others => '1');
          if and_reduce(pll_locked) = '0' then
            reset_state <= 0;
          end if;
        when others =>
          reset_state <= 0;
      end case;
    end if;
  end process tx_reseter;

end architecture behavioral;
