library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.localFlash_IO.all;
use ieee.std_logic_misc.all;
use work.types.all;

entity localFlash is
  
  port (
    clk_40Mhz : in    std_logic;
    SCL       : inout std_logic;
    SDA       : inout std_logic;
    monitor   : out localFlash_monitor_t;
    control   : in  localFlash_control_t);

end entity localFlash;

architecture behavior of localFlash is

  component I2C_reg_master is
    generic (
      I2C_QUARTER_PERIOD_CLOCK_COUNT : integer;
      IGNORE_ACK                     : std_logic;
      REG_ADDR_BYTE_COUNT            : integer;
      USE_RESTART_FOR_READ_SEQUENCE  : std_logic);
    port (
      clk_sys     : in    std_logic;
      reset       : in    std_logic;
      I2C_Address : in    std_logic_vector(6 downto 0);
      run         : in    std_logic;
      rw          : in    std_logic;
      reg_addr    : in    std_logic_vector((REG_ADDR_BYTE_COUNT*8) -1 downto 0);
      rd_data     : out   std_logic_vector(31 downto 0);
      wr_data     : in    std_logic_vector(31 downto 0);
      byte_count  : in    std_logic_vector(2 downto 0);
      done        : out   std_logic := '0';
      error       : out   std_logic;
      SDA         : inout std_logic;
      SCLK        : inout std_logic);
  end component I2C_reg_master;

begin

  monitor.addr <= control.addr;
  monitor.wr_data <= control.wr_data;
  monitor.reset <= control.reset;
  monitor.rw    <= control.rw;  
  I2C_reg_master_1: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 20,
      REG_ADDR_BYTE_COUNT            => 2)
    port map (
      clk_sys     => clk_40Mhz,
      reset       => control.reset,
      I2C_Address => "1010000",
      run         => control.run,
      rw          => control.rw,
      reg_addr    => control.addr,
      rd_data     => monitor.rd_data,
      wr_data     => control.wr_data,
      byte_count  => "100",
      done        => monitor.done,
      error       => monitor.error,
      SDA         => SDA,
      SCLK        => SCL);
  
end architecture behavior;
