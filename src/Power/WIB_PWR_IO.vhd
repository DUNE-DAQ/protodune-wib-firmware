----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the LocalFlash
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;


package WIB_PWR_IO is

--  type PWR_I2C_Monitor_t is record
--    rw         : std_logic;
--    addr       : std_logic_vector(7 downto 0);
--    rd_data    : std_logic_vector(31 downto 0);
--    wr_data    : std_logic_vector(31 downto 0);
--    byte_count : std_logic_vector(2 downto 0);
--    done       : std_logic;
--    error      : std_logic;
--  end record PWR_I2C_Monitor_t;
  
  type WIB_PWR_FEMB_Monitor_t is record
    Vcc       : std_logic_vector(15 downto 0);
    Temp      : std_logic_vector(15 downto 0);
    V_3V6     : std_logic_vector(15 downto 0);
    I_3V6     : std_logic_vector(15 downto 0);
    V_2V8     : std_logic_vector(15 downto 0);
    I_2V8     : std_logic_vector(15 downto 0);
    V_2V5     : std_logic_vector(15 downto 0);
    I_2V5     : std_logic_vector(15 downto 0);
    V_1V5     : std_logic_vector(15 downto 0);
    I_1V5     : std_logic_vector(15 downto 0);
    V_Bias    : std_logic_vector(15 downto 0);
    I_Bias    : std_logic_vector(15 downto 0);
    V_FE_2V5  : std_logic_vector(15 downto 0);
    I_FE_2V5  : std_logic_vector(15 downto 0);
  end record WIB_PWR_FEMB_Monitor_t;
  type WIB_PWR_FEMBS_Monitor_t is array (4 downto 1) of WIB_PWR_FEMB_Monitor_t;

  type WIB_PWR_WIB_Monitor_t is record
    Vcc       : std_logic_vector(15 downto 0);
    Temp      : std_logic_vector(15 downto 0);
    V_5V     : std_logic_vector(15 downto 0);
    I_5V     : std_logic_vector(15 downto 0);
    V_1V8     : std_logic_vector(15 downto 0);
    I_1V8     : std_logic_vector(15 downto 0);
    V_3V6     : std_logic_vector(15 downto 0);
    I_3V6     : std_logic_vector(15 downto 0);
    V_2V8     : std_logic_vector(15 downto 0);
    I_2V8     : std_logic_vector(15 downto 0);
  end record WIB_PWR_WIB_Monitor_t;

  
  type WIB_PWR_Monitor_t is record
    bias_Vcc   : std_logic_vector(15 downto 0);
    bias_temp  : std_logic_vector(15 downto 0);
    FE_Vcc     : std_logic_vector(15 downto 0);
    FE_temp    : std_logic_vector(15 downto 0);
    reset      : std_logic;
    FEMB  : WIB_PWR_FEMBS_Monitor_t;
    WIB   : WIB_PWR_WIB_Monitor_t;
  end record WIB_PWR_Monitor_t;


  
--  type PWR_I2C_Control_t is record
--    reset      : std_logic;
--    run        : std_logic;
--    rw         : std_logic;
--    addr       : std_logic_vector(7 downto 0);
--    wr_data    : std_logic_vector(31 downto 0);
--    byte_count : std_logic_vector(2 downto 0);
--  end record PWR_I2C_Control_t;
--  constant DEFAULT_PWR_I2C_Control : PWR_I2C_Control_t := (reset => '0',
--                                                           run => '0',
--                                                           rw => '0',
--                                                           addr => (others => '0'),
--                                                           wr_data => (others => '0'),
--                                                           byte_count => (others => '0'));
  
  
  type WIB_PWR_Control_t is record
--    convert : std_logic;
--    poll    : std_logic;
--    WIB_I2C : PWR_I2C_Control_t;
    reset : std_logic;
  end record WIB_PWR_Control_t;
  constant DEFAULT_WIB_PWR_Control : WIB_PWR_Control_t := (reset => '0');
                                                           --convert => '0',
                                                           --poll => '0',
                                                           --WIB_I2C => DEFAULT_PWR_I2C_Control);
  
end package WIB_PWR_IO;
