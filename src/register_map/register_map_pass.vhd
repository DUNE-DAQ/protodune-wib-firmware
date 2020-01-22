library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity register_map_pass is
  
  generic (
    WIDTH : integer := 16);
  port (
    clkA       : in  std_logic;
    clkB       : in  std_logic;
    inA        : in  std_logic_vector(WIDTH-1 downto 0);
    inA_valid  : in  std_logic;
    outB       : out std_logic_vector(WIDTH-1 downto 0);
    outB_valid : out std_logic);
end entity register_map_pass;


architecture behavioral of register_map_pass is
  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;

  --- clkA
  signal iPulseA : std_logic;
  signal inA_valid_last : std_logic;
  signal captureA : std_logic_vector(WIDTH-1 downto 0);
  
  -- clkB
  type capture_SR_t is array (1 downto 0) of std_logic_vector(WIDTH-1 downto 0);
  signal captureB : capture_SR_t;
  signal oPulseB : std_logic;
  
begin  -- architecture behavioral
  pacd_1: entity work.pacd
    port map (
      iPulseA => iPulseA,
      iClkA   => clkA,
      iRSTAn  => '1',
      iClkB   => clkB,
      iRSTBn  => '1',
      oPulseB => oPulseB);

  capture: process (clkA) is
  begin  -- process capture
    if clkA'event and clkA = '1' then  -- rising clock edge
      --zero pulse
      iPulseA <= '0';

      --make sure valid is force to be a pulse
      inA_valid_last <= inA_valid;
--      if inA_valid_last = '0' and inA_valid = '1' then
      if inA_valid = '1' then
        --capture input
        captureA <= inA;
        iPulseA <= '1';
      end if;
    end if;
  end process capture;

  display: process (clkB) is
  begin  -- process display
    if clkB'event and clkB = '1' then  -- rising clock edge
      --shift register to transfer to clkB domain
      captureB <= captureB(captureB'left -1 downto 0) & captureA;
      --Add an extra clock to iPulseB
--      outB_valid <= oPulseB;
    end if;
  end process display;
  outB_valid <= oPulseB;
  outB <= captureB(captureB'left);
  
end architecture behavioral;
