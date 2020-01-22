----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for COLDATA clock and command protocol
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package COLDATA_CnC_package is
  constant FRAME_WORD_LENGTH : integer := 5;
  constant FRAME_WORD_COUNT  : integer := 5;
  constant FRAME_LENGTH : integer := FRAME_WORD_LENGTH*FRAME_WORD_COUNT;
  
  type COLDATA_balanced_pair_t is array (1 downto 0) of std_logic_vector(FRAME_WORD_LENGTH -1 downto 0);
  -- element 1 is DC+ element 0 is DC-
  constant CD_IDLE      : COLDATA_balanced_pair_t := ("10101","01010");
  constant CD_CONVERT   : COLDATA_balanced_pair_t := ("11100","00011");
  constant CD_CALIBRATE : COLDATA_balanced_pair_t := ("11110","00001");
  constant CD_SYNC      : COLDATA_balanced_pair_t := ("11101","00010");
  constant CD_RESET     : COLDATA_balanced_pair_t := ("11111","00000");
  
end COLDATA_CnC_package;
