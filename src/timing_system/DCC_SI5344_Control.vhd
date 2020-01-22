library ieee;
use ieee.std_logic_1164.all;
use work.DCC_IO.all;

entity DCC_SI5344_Control is
  
  port (
    clk_sys_50Mhz : in std_logic;
    reset         : in    std_logic;
    clk_DTS       : in std_logic;
    reset_DTS     : in std_logic; -- clk_DTS
    SI5344_RST_N  : out std_logic;
    SI5344_IN_SEL : out std_logic_vector(1 downto 0);
    SI5344_OE_N   : out std_logic;
    SI5344_LOL_N  : in std_logic;
    SI5344_LOS_N  : in std_logic;
    SI5344_INT_N  : in std_logic;
    DTS_SI5344_SCL      : inout std_logic;
    DTS_SI5344_SDA      : inout std_logic;
    monitor       : out DTS_SI5344_Monitor_t;
    control       : in  DTS_SI5344_Control_t);

end entity DCC_SI5344_Control;

architecture behavioral of DCC_SI5344_Control is

  component I2c_master is
    generic (
      ACK_DISABLE : STD_LOGIC;
      SCL_WIDTH   : integer;
      USE_RESTART_FOR_READ_SEQUENCE : std_logic);
    port (
      rst           : IN    STD_LOGIC;
      sys_clk       : IN    STD_LOGIC;
      SCL_O         : INOUT STD_LOGIC;
      SDA           : INOUT STD_LOGIC;
      I2C_WR_STRB   : IN    STD_LOGIC;
      I2C_RD_STRB   : IN    STD_LOGIC;
      I2C_DEV_ADDR  : IN    STD_LOGIC_VECTOR(6 downto 0);
      I2C_NUM_BYTES : IN    STD_LOGIC_VECTOR(3 downto 0);
      I2C_ADDRESS   : IN    STD_LOGIC_VECTOR(7 downto 0);
      I2C_DOUT      : OUT   STD_LOGIC_VECTOR(31 downto 0);
      I2C_DIN       : IN    STD_LOGIC_VECTOR(31 downto 0);
      I2C_BUSY      : OUT   STD_LOGIC;
      I2C_DEV_AVL   : OUT   STD_LOGIC);
  end component I2c_master;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;

  signal reset_request_pulse : std_logic := '0';
  signal queued_reset_request : std_logic := '0';

  signal queued_user_request : std_logic := '0';
  signal I2C_run         :   std_logic;
  signal I2C_rw          :   std_logic;
  signal I2C_reg_addr    :   std_logic_vector(7 downto 0);
  signal I2C_rd_data     :   std_logic_vector(31 downto 0);
  signal I2C_wr_data     :   std_logic_vector(31 downto 0);
  signal I2C_byte_count  :   std_logic_vector(2 downto 0);
  signal I2C_done        :   std_logic;
  signal I2C_error       :   std_logic;

  signal cached_page : std_logic_vector(7 downto 0) := x"00";
  
  type state_t is (SI5344_IDLE,
                   SI5344_RESET_GET_PAGE,
                   SI5344_RESET_GET_PAGE_START_WAIT,
                   SI5344_RESET_GET_PAGE_WAIT,
                   SI5344_RESET_GET_PAGE_FINISH,
                   SI5344_RESET_SET_PAGE_START_WAIT,
                   SI5344_RESET_SET_PAGE_WAIT,
                   SI5344_RESET_SET_RESET_START_WAIT,
                   SI5344_RESET_SET_RESET_WAIT,
                   SI5344_RESET_RESTORE_PAGE_START_WAIT,
                   SI5344_USER_START,
                   SI5344_USER_START_WAIT,
                   SI5344_USER_WAIT,
                   SI5344_USER_FINISH,
                   SI5344_RESET_START
                   );
  signal state : state_t := SI5344_IDLE;
  
begin  -- architecture behavioral

  SI5344_RST_N  <= not control.reset;
  SI5344_IN_SEL <= control.in_sel;


  pacd_1: entity work.pacd
    port map (
      iPulseA => reset_DTS,
      iClkA   => clk_DTS,
      iRSTAn  => '1',
      iClkB   => clk_sys_50Mhz,
      iRSTBn  => '1',
      oPulseB => reset_request_pulse);

  
  --Monitoring
  monitor.LOL <= not SI5344_LOL_N;
  monitor.LOS <= not SI5344_LOS_N;
  monitor.interrupt <= not SI5344_INT_N;     
  monitor.reset  <= control.reset;
  monitor.in_sel <= control.in_sel;

  monitor.I2C.byte_count <= control.I2C.byte_count;
  monitor.I2C.rw         <= control.I2C.rw;
  monitor.I2C.address    <= control.I2C.address;
  monitor.I2C.wr_data    <= control.I2C.wr_data;
  monitor.I2C.rd_data    <= I2C_rd_data;
  
  SI5344_Control: process (clk_sys_50Mhz) is
  begin  -- process SI5344_Control
    if clk_sys_50Mhz'event and clk_sys_50Mhz = '1' then  -- rising clock edge
      
      ---------------------------------------------------------------------------
      --Control the SI5344 output enable
      ---------------------------------------------------------------------------
      if reset_request_pulse = '1' then
        --override the user control for a request from the PDTS
        SI5344_OE_N <= '1';
        monitor.enable <= '0';
        queued_reset_request <= '1';
      else
        if state = SI5344_IDLE then
          monitor.enable <= control.enable;
          SI5344_OE_N  <= not control.enable;
        end if;
      end if;

      if control.I2C.run = '1' then
        queued_user_request <= '1';
      end if;
      
      ---------------------------------------------------------------------------
      -- SI5344 I2C control state machine
      ---------------------------------------------------------------------------
      case state is
        when  SI5344_IDLE =>
          monitor.I2C.done <= I2C_done;
          monitor.I2C.error <= I2C_error;
          ---------------------------------------------------
          -- IDLE
          ---------------------------------------------------
          --Wait for a request from the timing system
          if reset_request_pulse = '1' or queued_reset_request = '1' then
            state <= SI5344_RESET_GET_PAGE;
            --block transactions
            monitor.I2C.done <= '0';
          elsif control.I2C.run = '1' or queued_user_request = '1' then
            state <= SI5344_USER_START;            
          end if;




        when SI5344_RESET_GET_PAGE =>
          ---------------------------------------------------
          -- RESET GET PAGE WAIT
          ---------------------------------------------------
          --get current page
          I2C_rw <= '1'; -- read
          I2C_reg_addr <= x"01";
          I2C_byte_count <= "001";
          I2C_run <= '1'; -- start transaction
          state <= SI5344_RESET_GET_PAGE_START_WAIT;
        when SI5344_RESET_GET_PAGE_START_WAIT =>
          ---------------------------------------------------
          -- RESET GET PAGE START WAIT
          ---------------------------------------------------
          I2C_run <= '0';
          --wait one clock tick for done to now be invalid          
          state <= SI5344_RESET_GET_PAGE_WAIT;
        when SI5344_RESET_GET_PAGE_WAIT =>
          ---------------------------------------------------
          -- RESET GET PAGE WAIT
          ---------------------------------------------------
          -- wait for transaction to finish
          if I2C_done = '1' then
            state <= SI5344_RESET_GET_PAGE_FINISH;
          end if;
        when SI5344_RESET_GET_PAGE_FINISH =>
          ---------------------------------------------------
          -- USER FINISH & SET PAGE
          ---------------------------------------------------
          cached_page <= I2C_rd_data(7 downto 0);
          I2C_rw <= '0'; -- write
          I2C_wr_data <= x"00000000";
          I2C_reg_addr <= x"01";
          I2C_byte_count <= "001";
          I2C_run <= '1'; -- start transaction
          state <= SI5344_RESET_SET_PAGE_START_WAIT;
        when SI5344_RESET_SET_PAGE_START_WAIT =>
          ---------------------------------------------------
          -- RESET SET PAGE START WAIT
          ---------------------------------------------------
          I2C_run <= '0';
          --wait one clock tick for done to now be invalid
          state <= SI5344_RESET_SET_PAGE_WAIT;
        when SI5344_RESET_SET_PAGE_WAIT =>
          ---------------------------------------------------
          -- RESET SET PAGE WAIT
          ---------------------------------------------------
          -- wait for transaction to finish
          if I2C_done = '1' then
            I2C_rw <= '0'; -- write
            I2C_wr_data <= x"00000001";
            I2C_reg_addr <= x"1C";
            I2C_byte_count <= "001";
            I2C_run <= '1'; -- start transaction  
            state <= SI5344_RESET_SET_RESET_START_WAIT;
          end if;
        when SI5344_RESET_SET_RESET_START_WAIT =>
          ---------------------------------------------------
          -- RESET SET RESET START WAIT
          ---------------------------------------------------
          I2C_run <= '0';
          --wait one clock tick for done to now be invalid
          state <= SI5344_RESET_SET_RESET_WAIT;
        when SI5344_RESET_SET_RESET_WAIT =>
          ---------------------------------------------------
          -- RESET SET RESET WAIT
          ---------------------------------------------------
          -- wait for transaction to finish
          if I2C_done = '1' then
            --reload the original page
            I2C_rw <= '0'; -- write
            I2C_wr_data <= x"000000" & cached_page;
            I2C_reg_addr <= x"01";
            I2C_byte_count <= "001";
            I2C_run <= '1'; -- start transaction  
            state <= SI5344_RESET_RESTORE_PAGE_START_WAIT;
          end if;
        when SI5344_RESET_RESTORE_PAGE_START_WAIT =>
          ---------------------------------------------------
          -- reset restore page start wait
          ---------------------------------------------------
          I2C_run <= '0';
          --wait one clock tick for done to now be invalid
          --Go back to idle
          state <= SI5344_IDLE;
          SI5344_OE_N <= '0';
          queued_reset_request <= '0';
          
          
          
        when SI5344_USER_START =>
          ---------------------------------------------------
          -- USER START 
          ---------------------------------------------------
          --buffer values for user
          I2C_rw <= control.I2C.rw;
          I2C_reg_addr <= control.I2C.address;
          I2C_wr_data <= control.I2C.wr_data;
          I2C_byte_count <= control.I2C.byte_count;
          I2C_run <= '1'; -- start transaction
          monitor.I2C.done <= '0'; -- tell the user this isn't done yet
          state <= SI5344_USER_START_WAIT;
        when SI5344_USER_START_WAIT =>
          ---------------------------------------------------
          -- USER START WAIT
          ---------------------------------------------------
          I2C_run <= '0';     
          --wait one clock tick for done to now be invalid
          state <= SI5344_USER_WAIT;
        when SI5344_USER_WAIT =>
          ---------------------------------------------------
          -- USER START WAIT
          ---------------------------------------------------
          -- wait for transaction to finish
          if I2C_done = '1' then
            state <= SI5344_USER_FINISH;
          end if;
        when SI5344_USER_FINISH =>
          ---------------------------------------------------
          -- USER FINISH
          ---------------------------------------------------
          --output any values that need to be outputted
          monitor.I2C.done <= I2C_done;
          monitor.I2C.error <= I2C_error;
          --Remote any queued transfers
          queued_user_request <= '0';
          state <= SI5344_IDLE;
--        when SI5344_RESET_START =>
--          I2C_reg_address <= x"1C";
        when others => null;
      end case;
      
    end if;
  end process SI5344_Control;

    DTS_SI5344_I2C: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 124,
      IGNORE_ACK                     => '0',
      USE_RESTART_FOR_READ_SEQUENCE  => '0')
    port map (
      clk_sys     => clk_sys_50Mhz,
      reset       => reset,
      I2C_Address => "1101011",
      run         => I2C_run,
      rw          => I2C_rw,
      reg_addr    => I2C_reg_addr,
      rd_data     => I2C_rd_data,
      wr_data     => I2C_wr_data,
      byte_count  => I2C_byte_count,
      done        => I2C_done,
      error       => I2C_error,
      SDA         => DTS_SI5344_SDA,
      SCLK        => DTS_SI5344_SCL);


end architecture behavioral;

