library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;




use work.WIB_PWR_IO.all;
use work.types.all;

--  Entity Declaration

ENTITY WIB_PWR_MON IS
  
  PORT
    (
      rst	      : in    STD_LOGIC;				
      clk	      : IN    STD_LOGIC;        -- 40MHZ ONLY
      
      monitor         : out   WIB_PWR_Monitor_t;
      control         : in    WIB_PWR_Control_t;

      PWR_SCL_BRD    : inout std_logic_vector(3 downto 0);	--	2.5V, LTC2991 clk control
      PWR_SDA_BRD    : inout std_logic_vector(3 downto 0);	--	2.5V, LTC2991 SDA control
      
      PWR_SCL_BIAS    : inout STD_LOGIC;	--	2.5V, LTC2991 clk control
      PWR_SDA_BIAS    : inout STD_LOGIC;	--	2.5V, LTC2991 SDA control		
                      
      PWR_SCL_WIB     : inout STD_LOGIC;	--	2.5V, LTC2991 clk control
      PWR_SDA_WIB     : inout STD_LOGIC	        --	2.5V, LTC2991 SDA control		
      

      );

end entity WIB_PWR_MON;

architecture behavioral of WIB_PWR_MON is

  component WIB_PWR_POLL_MON is
    generic (
      DEVICE_COUNT : integer);
    port (
      clk         : in    std_logic;
      reset_sync  : in    std_logic;
      I2C_Address : in    uint7_array_t(DEVICE_COUNT-1 downto 0);
      PWR_SCL     : inout std_logic;
      PWR_SDA     : inout std_logic;
      data        : out   uint16_array_t(9 downto 0));
  end component WIB_PWR_POLL_MON;
  
  signal I2C_Address : uint7_array_t(6 downto 0)    :=  ("1001100", -- 6 FE
                                                         "1001000", -- 5 WIB
                                                         "1001000", -- 4 FEMB 1
                                                         "1001000", -- 3 FEMB 2
                                                         "1001000", -- 2 FEMB 3
                                                         "1001000", -- 1 FEMB 4
                                                         "1001000"  -- 0 Bias
                                                         );

begin  -- architecture behavioral

  monitor.reset <= control.reset;

  
  FEMB_PWR: for iFEMB in 3 downto 0 generate   
    FEMB_PWR_POLL_MON_1: entity work.WIB_PWR_POLL_MON
      port map (
        clk         => clk,
        reset_sync  => control.reset,
        I2C_Address(0) => I2C_Address(1+iFEMB),
        PWR_SCL     => PWR_SCL_BRD(iFEMB),
        PWR_SDA     => PWR_SDA_BRD(iFEMB),
        data(0)     => monitor.FEMB(1+iFEMB).V_3V6,
        data(1)     => monitor.FEMB(1+iFEMB).I_3V6,
        data(2)     => monitor.FEMB(1+iFEMB).V_2V8,
        data(3)     => monitor.FEMB(1+iFEMB).I_2V8,
        data(4)     => monitor.FEMB(1+iFEMB).V_2V5,
        data(5)     => monitor.FEMB(1+iFEMB).I_2V5,
        data(6)     => monitor.FEMB(1+iFEMB).V_1V5,
        data(7)     => monitor.FEMB(1+iFEMB).I_1V5,
        data(8)     => monitor.FEMB(1+iFEMB).Temp,
        data(9)     => monitor.FEMB(1+iFEMB).VCC
        );
  end generate FEMB_PWR;

  BIAS_PWR_POLL_MON_1: entity work.WIB_PWR_POLL_MON
    generic map (
      DEVICE_COUNT => 2)
    port map (
      clk         => clk,
      reset_sync  => control.reset,
      I2C_Address(0) => I2C_Address(0),
      I2C_Address(1) => I2C_Address(6),
      PWR_SCL     => PWR_SCL_BIAS,
      PWR_SDA     => PWR_SDA_BIAS,
      data(0)     => monitor.FEMB(1).V_Bias,
      data(1)     => monitor.FEMB(1).I_Bias,
      data(2)     => monitor.FEMB(2).V_Bias,
      data(3)     => monitor.FEMB(2).I_Bias,
      data(4)     => monitor.FEMB(3).V_Bias,
      data(5)     => monitor.FEMB(3).I_Bias,
      data(6)     => monitor.FEMB(4).V_Bias,
      data(7)     => monitor.FEMB(4).I_Bias,
      data(8)     => monitor.Bias_Temp,
      data(9)     => monitor.Bias_VCC,
      data(10)     => monitor.FEMB(1).V_FE_2V5,
      data(11)     => monitor.FEMB(1).I_FE_2V5,
      data(12)     => monitor.FEMB(2).V_FE_2V5,
      data(13)     => monitor.FEMB(2).I_FE_2V5,
      data(14)     => monitor.FEMB(3).V_FE_2V5,
      data(15)     => monitor.FEMB(3).I_FE_2V5,
      data(16)     => monitor.FEMB(4).V_FE_2V5,
      data(17)     => monitor.FEMB(4).I_FE_2V5,
      data(18)     => monitor.FE_Temp,
      data(19)     => monitor.FE_VCC
      );

  WIB_PWR_POLL_MON_1: entity work.WIB_PWR_POLL_MON
    port map (
      clk         => clk,
      reset_sync  => control.reset,
      I2C_Address(0) => I2C_Address(5),
      PWR_SCL     => PWR_SCL_WIB,
      PWR_SDA     => PWR_SDA_WIB,
      data(0)     => monitor.WIB.V_5V,
      data(1)     => monitor.WIB.I_5V,
      data(2)     => monitor.WIB.V_1V8,
      data(3)     => monitor.WIB.I_1V8,
      data(4)     => monitor.WIB.V_3V6,
      data(5)     => monitor.WIB.I_3V6,
      data(6)     => monitor.WIB.V_2V8,
      data(7)     => monitor.WIB.I_2V8,
      data(8)     => monitor.WIB.Temp,
      data(9)     => monitor.WIB.VCC
      );

  

end architecture behavioral;
