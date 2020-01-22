----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the WIB top level
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


package WIB_IO is

  type WIB_ID_t is record
    slot  : std_logic_vector(3 downto 0);
    crate : std_logic_vector(3 downto 0);    
  end record WIB_ID_t;
  constant DEFAULT_WIB_ID : WIB_ID_t := (slot => x"f",crate => x"f");

  type TempSensor_Monitor_t is record
    temp : std_logic_vector(31 downto 0);
    busy : std_logic;
  end record TempSensor_Monitor_t;
  
  type Power_Monitor_t is record
    EN_3V6  : std_logic_vector(3 downto 0);  
    EN_2V8  : std_logic_vector(3 downto 0);  
    EN_2V5  : std_logic_vector(3 downto 0);  
    EN_1V5  : std_logic_vector(3 downto 0);  
    EN_BIAS : std_logic_vector(3 downto 0);
    EN_BIAS_MASTER : std_logic;
    measurement_valid : std_logic;
    measurement_select : std_logic_vector(7 downto 0);
    measurement : std_logic_vector(31 downto 0);
  end record Power_Monitor_t;

  type WIB_Monitor_t is record
    GLB_i_Reset : std_logic;
    REG_RESET   : std_logic;
    UDP_RESET   : std_logic;
    ALG_RESET   : std_logic;
    DAQ_PATH_RESET : std_logic;
    EVB_reset   : std_logic;
    sys_locked  : std_logic;
    FEMB_locked : std_logic;
    EB_locked : std_logic;    
    DCC_locked  : std_logic;
    reset_FEMB_PLL : std_logic;
    ID          : WIB_ID_t;
    real_ID     : WIB_ID_t;
    fake_ID     : WIB_ID_t;
    use_fake_ID : std_logic;
    Power       : Power_Monitor_t;
    FEMB_COUNT  : std_logic_vector(3 downto 0);
    DAQ_LINK_COUNT : std_logic_vector(3 downto 0);
    TempSensor  : TempSensor_Monitor_t;
    dts_bp_out_dsbl : std_logic_vector(5 downto 0);
    dts_fp_clk_out_dsbl : std_logic;
  end record WIB_Monitor_t;

  type Power_Control_t is record
    EN_3V6  : std_logic_vector(3 downto 0);  
    EN_2V8  : std_logic_vector(3 downto 0);  
    EN_2V5  : std_logic_vector(3 downto 0);  
    EN_1V5  : std_logic_vector(3 downto 0);  
    EN_BIAS : std_logic_vector(3 downto 0);
    EN_BIAS_MASTER : std_logic;
    measurement_start : std_logic;
    measurement_select : std_logic_vector(7 downto 0);
  end record Power_Control_t;
  constant DEFAULT_Power_control_t : Power_control_t := (EN_3V6 => x"0",
                                                         EN_2V8 => x"0",
                                                         EN_2V5 => x"0",
                                                         EN_1V5 => x"0",
                                                         EN_BIAS => x"0",
                                                         EN_BIAS_MASTER => '0',
                                                         measurement_start => '0',
                                                         measurement_select => x"00");

  type TempSensor_Control_t is record
    start : std_logic;
  end record TempSensor_Control_t;
  constant DEFAULT_TempSensor_control_t : TempSensor_Control_t := (start => '0');
  
  type WIB_Control_t is record
    GLB_i_Reset : std_logic;
    REG_RESET   : std_logic;
    UDP_RESET   : std_logic;
    ALG_RESET   : std_logic;
    DAQ_PATH_RESET : std_logic;
    EVB_reset   : std_logic;
    reset_FEMB_PLL : std_logic;
    use_fake_ID : std_logic;
    fake_ID     : WIB_ID_t;
    Power       : Power_Control_t;
    TempSensor  : TempSensor_Control_t;
  end record WIB_Control_t;

  --constant used for default settings of the FEControl record
  constant DEFAULT_WIB_control : WIB_Control_t := (GLB_i_Reset => '0',
                                                   REG_RESET   => '0',
                                                   UDP_RESET   => '0',
                                                   ALG_RESET   => '0',
                                                   DAQ_PATH_RESET => '0',
                                                   EVB_reset   => '0',
                                                   reset_FEMB_PLL => '0',
                                                   use_fake_ID => '0',
                                                   fake_id     => DEFAULT_WIB_ID,
                                                   Power       => DEFAULT_Power_control_t,
                                                   TempSensor  => DEFAULT_TempSensor_control_t);   
end WIB_IO;
