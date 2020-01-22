library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity fake_FEMB is
  
  port (
    clk            : in  std_logic;
    start          : in  std_logic;
    data_out       : out std_logic_vector(8 downto 0));

end entity fake_FEMB;

architecture behavioral of fake_FEMB is
  signal counter : integer := 61;
begin  -- architecture behavioral

  data_gen: process (clk) is
  begin  -- process data_gen
    if clk'event and clk = '1' then  -- rising clock edge
      if (counter >= 0) and (counter <= 60) then
        case counter is
          when  0 => data_out <= "1"&x"BC"
          when  1 => data_out <= "1"&x"BC";
          when  2 => data_out <= "1"&x"3C";
          when  3 => data_out <= "0"&x"5D";
          when  4 => data_out <= "0"&x"76";
          when  5 => data_out <= "0"&x"B2";
          when  6 => data_out <= "0"&x"CA";
          when  7 => data_out <= "0"&x"FF";
          when  8 => data_out <= "0"&x"00";
          when  9 => data_out <= "0"&x"01";
          when 10 => data_out <= "0"&x"00";
          when 11 => data_out <= "0"&x"AA";
          when 12 => data_out <= "0"&x"AA";
          when 13 => data_out <= "0"&x"E1";
          when 14 => data_out <= "0"&x"1F";
          when 15 => data_out <= "0"&x"FE";
          when 16 => data_out <= "0"&x"E1";
          when 17 => data_out <= "0"&x"1F";
          when 18 => data_out <= "0"&x"FE";
          when 19 => data_out <= "0"&x"E1";
          when 20 => data_out <= "0"&x"1F";
          when 21 => data_out <= "0"&x"FE";
          when 22 => data_out <= "0"&x"E1";
          when 23 => data_out <= "0"&x"1F";
          when 24 => data_out <= "0"&x"FE";
          when 25 => data_out <= "0"&x"E1";
          when 26 => data_out <= "0"&x"1F";
          when 27 => data_out <= "0"&x"FE";
          when 28 => data_out <= "0"&x"E1";
          when 29 => data_out <= "0"&x"1F";
          when 30 => data_out <= "0"&x"FE";
          when 31 => data_out <= "0"&x"E1";
          when 32 => data_out <= "0"&x"1F";
          when 33 => data_out <= "0"&x"FE";
          when 34 => data_out <= "0"&x"E1";
          when 35 => data_out <= "0"&x"1F";
          when 36 => data_out <= "0"&x"FE";
          when 37 => data_out <= "0"&x"E1";
          when 38 => data_out <= "0"&x"1F";
          when 39 => data_out <= "0"&x"FE";
          when 40 => data_out <= "0"&x"E1";
          when 41 => data_out <= "0"&x"1F";
          when 42 => data_out <= "0"&x"FE";
          when 43 => data_out <= "0"&x"E1";
          when 44 => data_out <= "0"&x"1F";
          when 45 => data_out <= "0"&x"FE";
          when 46 => data_out <= "0"&x"E1";
          when 47 => data_out <= "0"&x"1F";
          when 48 => data_out <= "0"&x"FE";
          when 49 => data_out <= "0"&x"E1";
          when 50 => data_out <= "0"&x"1F";
          when 51 => data_out <= "0"&x"FE";
          when 52 => data_out <= "0"&x"E1";
          when 53 => data_out <= "0"&x"1F";
          when 54 => data_out <= "0"&x"FE";
          when 55 => data_out <= "0"&x"E1";
          when 56 => data_out <= "0"&x"1F";
          when 57 => data_out <= "0"&x"FE";
          when 58 => data_out <= "0"&x"E1";
          when 59 => data_out <= "0"&x"1F";
          when 60 => data_out <= "0"&x"FE";
          when others => data_out <= "1"&x"3C";
        end case;
      elsif start = '1' then        
        data_out <= "1"&x"3C";
        if asdf then
          
        end if;
        counter <= 
      else
        data_out <= "1"&x"3C";
      end if;
    end if;
  end process data_gen;

end architecture behavioral;
