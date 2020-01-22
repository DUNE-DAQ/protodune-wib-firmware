library ieee;
use ieee.std_logic_1164.all;
-- Constants for this WIB design
package WIB_Constants is
  constant FEMB_COUNT     : integer := 4;  -- number of Front-End MotherBoards   
  constant CDAS_PER_FEMB  : integer := 2;  -- Number of COLDATA ASICS per FEMB
  constant LINKS_PER_CDA  : integer := 2;  -- Number of links per COLDATA ASIC
  constant LINKS_PER_FEMB : integer := CDAS_PER_FEMB * LINKS_PER_CDA;
  constant LINK_COUNT     : integer := FEMB_COUNT*LINKS_PER_FEMB;
  constant LINK_GROUPS    : integer := 4;


  constant FW_VERSION     : std_logic_vector(31 downto 0) := x"19011701";


  constant CDA_SWITCH     : std_logic := '1'; -- Type of COLDATA.  '0' means
                                              -- real CD ASICS, '1' means CD FPGAs
  --CHange me for RCE/FELIX (also change which refclk is commented out on line
  --122 of WIB.qsf
  constant CDAS_PER_DAQ_LINK : integer := 2;  -- 2 => RCE, 4 => FELIX
  constant GEARBOX_EXTRA_WORD_COUNT : integer := 1; -- 1 => RCE, 1 => FELIX --
                                                    -- old 0 => FELIX

  constant LINKS_PER_DAQ_LINK : integer := CDAS_PER_DAQ_LINK*LINKS_PER_CDA;
  constant DAQ_LINK_VERSION_NUMBER : std_logic_vector(4 downto 0) := "00001";
  constant DAQ_LINK_COUNT : integer := LINK_COUNT/(CDAS_PER_DAQ_LINK*LINKS_PER_CDA);

  constant ENABLE_DTS_OUTPUT : integer := 0;
end package WIB_Constants;
