--------------------------------------------------------------------------------
-- Copyright (C) 1999-2008 Easics NV.
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--
-- Purpose : synthesizable CRC function
--   * polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
--   * data width: 8
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:20:34 12/01/2011 
-- Design Name: 
-- Module Name:    EthernetCRC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER  
-- This module is provided only as an example, no correctness or any usefullness is implied.
-- Use of it is at users' own risk. 
-- Do not remove this disclaimer.
-- !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER !!!DISCLAIMER  
-- Description: Ethernet CRC calculation, derived from PCK_CRC32_D8 generated using easics.com tools
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PCK_CRC32_D64.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CRCD64_RCE is
  Port ( clk : in  STD_LOGIC;
         init : in  STD_LOGIC;
         ce : in  STD_LOGIC;
         d : in  STD_LOGIC_VECTOR (63 downto 0);
         crc : out  STD_LOGIC_VECTOR (31 downto 0);
         bad_crc : out  STD_LOGIC
         );
end CRCD64_RCE;

architecture Behavioral of CRCD64_RCE is
  constant crc_R : std_logic_vector(31 downto 0) := x"c704dd7b";
  signal c : std_logic_vector(31 downto 0) := (others => '1');
  signal d_swap : std_logic_vector(63 downto 0) := (others => '0');
begin
  process(c,d)
  begin
    for i in 0 to 31 loop
      crc(i) <= not c(31-i);
    end loop;
    for i in 0 to 63 loop
      d_swap(i) <= d(63-i);
    end loop;  -- i
  end process;
  bad_crc <= '0' when c = crc_R else '1';
  process(clk)
  begin
    if(clk'event and clk = '1')then
      if(init = '1')then
        c <= nextCRC32_D64(d_swap,x"FFFFFFFF");        
      elsif(ce = '1')then
        c <= nextCRC32_D64(d_swap,c);
      end if;
    end if;
  end process;

end Behavioral;

