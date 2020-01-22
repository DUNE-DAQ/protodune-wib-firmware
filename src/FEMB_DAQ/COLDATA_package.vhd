----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package constants of the COLDATA format
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.WIB_Constants.all;



package COLDATA_IO is
  
  --Special data format characters
  constant IDLE_CHARACTER            : std_logic_vector(8 downto 0) := '1'&x"3C";  --K.28.1
  constant SOF_CHARACTER             : std_logic_vector(8 downto 0) := '1'&x"BC";  --K.28.5
  
  constant ADDR_TIMESTAMP_R   : unsigned(5 downto 0) := "00"&x"3"; 
  constant ADDR_ERRORS_R      : unsigned(5 downto 0) := "00"&x"0"; 
  constant ADDR_RESERVED_R    : unsigned(5 downto 0) := "00"&x"1";
  
  constant ADDR_PADDING       : unsigned(5 downto 0) := "00"&x"4"; --SOF
  constant ADDR_CHECKSUM_1    : unsigned(5 downto 0) := "00"&x"5";
  constant ADDR_CHECKSUM_2    : unsigned(5 downto 0) := "00"&x"6";
  constant ADDR_TIMESTAMP     : unsigned(5 downto 0) := "00"&x"7";
  
  constant ADDR_ERRORS        : unsigned(5 downto 0) := "00"&x"8";
  constant ADDR_RESERVED      : unsigned(5 downto 0) := "00"&x"9";
  constant ADDR_ADC_HEADER_1  : unsigned(5 downto 0) := "00"&x"A";
  constant ADDR_ADC_HEADER_2  : unsigned(5 downto 0) := "00"&x"B";
  
  constant ADDR_DATA_START : unsigned(5 downto 0)    := "00"&x"C";
  constant ADDR_DATA_END   : unsigned(5 downto 0)    := "11"&x"C";
  
    
    
  constant CDA_FRAME_SIZE                : unsigned(5 downto 0) := to_unsigned(55,6);
    
  constant CDA_WORD_COLDATA_CHECKSUM_LSB : unsigned(5 downto 0) := to_unsigned(0,6);
  constant CDA_WORD_COLDATA_CHECKSUM_MSB : unsigned(5 downto 0) := to_unsigned(1,6);
  constant CDA_WORD_COLDATA_TIME         : unsigned(5 downto 0) := to_unsigned(2,6);
  constant CDA_WORD_COLDATA_ERRORS       : unsigned(5 downto 0) := to_unsigned(3,6);
  constant CDA_WORD_COLDATA_RESERVED     : unsigned(5 downto 0) := to_unsigned(4,6);
  constant CDA_WORD_COLDATA_HEADER1      : unsigned(5 downto 0) := to_unsigned(5,6);
  constant CDA_WORD_COLDATA_HEADER2      : unsigned(5 downto 0) := to_unsigned(6,6);


  constant CDF_FRAME_SIZE                : unsigned(5 downto 0) := to_unsigned(58,6);
    
  constant CDF_WORD_COLDATA_CHECKSUM_LSB : unsigned(5 downto 0) := to_unsigned(0,6);
  constant CDF_WORD_COLDATA_CHECKSUM_MSB : unsigned(5 downto 0) := to_unsigned(1,6);
  constant CDF_WORD_COLDATA_TIME_1       : unsigned(5 downto 0) := to_unsigned(2,6);
  constant CDF_WORD_COLDATA_TIME_2       : unsigned(5 downto 0) := to_unsigned(3,6);
  constant CDF_WORD_COLDATA_ERRORS_1     : unsigned(5 downto 0) := to_unsigned(4,6);
  constant CDF_WORD_COLDATA_ERRORS_2     : unsigned(5 downto 0) := to_unsigned(5,6);
  constant CDF_WORD_COLDATA_RESERVED_1   : unsigned(5 downto 0) := to_unsigned(6,6);
  constant CDF_WORD_COLDATA_RESERVED_2   : unsigned(5 downto 0) := to_unsigned(7,6);
  constant CDF_WORD_COLDATA_HEADER1      : unsigned(5 downto 0) := to_unsigned(8,6);
  constant CDF_WORD_COLDATA_HEADER2      : unsigned(5 downto 0) := to_unsigned(9,6);



end COLDATA_IO;
