library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.types.all;

entity TempSensor is
  
  port (
    clk_40Mhz : in  std_logic;
    CS_N      : out std_logic;
    SCLK      : out std_logic;
    SDA       : in  std_logic;
    start     : in  std_logic;
    temp      : out std_logic_vector(31 downto 0);
    busy      : out std_logic
    );

end entity TempSensor;

architecture behavior of TempSensor is
  type TS_state_t is (TS_IDLE,
                      TS_START_0,
                      TS_START_1,
                      TS_START_2,
                      TS_START_3,
                      TS_0,TS_1,TS_2,TS_3,
                      TS_DONE);
  signal TS_STATE : TS_state_t := TS_IDLE;
  signal data : std_logic_vector(31 downto 0) := x"00000000";
  signal iBit : integer range 31 downto 0 := 0;
  signal CS : std_logic := '0';
begin

  CS_N <= not CS;
  
  state_machine: process (clk_40Mhz) is
  begin  -- process state_machine
    if clk_40Mhz'event and clk_40Mhz = '1' then  -- rising clock edge
      --default state is busy, but this is overidden by TS_IDLE
      busy <= '1';
      case TS_STATE is
        when TS_IDLE =>
          busy <= '0';
          if start = '1' then
            TS_STATE <= TS_START_0;
          end if;
        -------------------------------------------
        -- Start sequence
        when TS_START_0 =>
          CS <= '1';  -- start the sequence
          iBit <= 31; -- get ready for bit 31
          TS_state <= TS_START_1;
        when TS_START_1 =>
          TS_state <= TS_START_2;
        when TS_START_2 =>
          TS_state <= TS_START_3;
        when TS_START_3 =>
          TS_state <= TS_0; -- start reading bit 31
        -------------------------------------------
        -- Bit sequence
        when TS_0 =>
          --start clock low
          SCLK <= '0';
          TS_STATE <= TS_1;
        when TS_1 =>
          --bring clock high
          SCLK <= '1';
          TS_STATE <= TS_2;
        when TS_2 =>
          -- sample
          data(iBit) <= SDA;
          TS_STATE <= TS_3;
        when TS_3 =>
          -- drop clock low, check for bit
          SCLK <= '0';
          if iBit = 0 then
            TS_STATE <= TS_DONE;
          else
            TS_STATE <= TS_0;
            iBit <= iBit - 1;
          end if;
        -------------------------------------------
        -- Finish sequence
        when TS_DONE =>
          CS <= '0';
          TS_state <= TS_IDLE;
          temp <= data;
        when others => TS_state <= TS_IDLE;
      end case;
    end if;
  end process state_machine;
end architecture behavior;
