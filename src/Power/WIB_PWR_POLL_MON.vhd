library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;




use work.WIB_PWR_IO.all;
use work.types.all;

entity WIB_PWR_POLL_MON is
  generic (
    DEVICE_COUNT : integer := 1);
  port (
    clk     : in  std_logic;
    reset_sync : in std_logic;
        
    I2C_Address: in uint7_array_t(DEVICE_COUNT -1 downto 0);
    PWR_SCL : inout std_logic;       -- 2.5V, LTC2991 clk control
    PWR_SDA : inout std_logic;       -- 2.5V, LTC2991 SDA control

    data       : out uint16_array_t((DEVICE_COUNT*10) -1 downto 0)
    
    );

end entity WIB_PWR_POLL_MON;

architecture behavioral of WIB_PWR_POLL_MON is

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

  --sensor interface
  signal reset             : std_logic := '0';
  signal run               : std_logic := '0';
  signal rw                : std_logic := '0';
  signal reg_addr          : std_logic_vector(7 downto 0) := x"00";
  signal rd_data           : std_logic_vector(31 downto 0);
  signal wr_data           : std_logic_vector(31 downto 0) := x"00000000";
  signal byte_count        : std_logic_vector(2 downto 0) := "000";
  signal transaction_done  : std_logic := '0';
  signal transaction_error : std_logic := '0';

  
  --IDLE wait
  constant IDLE_COUNT_END   : unsigned(31 downto 0) := x"00061A80";--x"02625a00";
  constant IDLE_COUNT_START : unsigned(31 downto 0) := x"00000000";
  signal idle_count         : unsigned(31 downto 0) := IDLE_COUNT_START;
  signal idle_count_done : std_logic := '0';

  --CONVERT delay
  constant CONVERT_COUNT_END   : unsigned(19 downto 0) := x"13880";
  constant CONVERT_COUNT_START : unsigned(19 downto 0) := x"00000";
  signal convert_count         : unsigned(19 downto 0) := CONVERT_COUNT_START;
  signal convert_count_done : std_logic := '0';
  
  
  -- State machine
  type PWR_state_t is (PS_RESET,
                       PS_INIT,
                       PS_INIT_DELAY,
                       PS_INIT_OK,
                       PS_IDLE_WAIT,
                       PS_START,
                       PS_CONVERT_CMD,
                       PS_CONVERT_DELAY,
                       PS_CONVERT_CMD_OK,
                       PS_CONVERT_WAIT,
                       PS_STATUS_CMD,
                       PS_STATUS_DELAY,
                       PS_STATUS_CMD_OK,
                       PS_READOUT_CMD,
                       PS_READOUT_DELAY,
                       PS_READOUT_CMD_OK,
                       PS_READOUT_SAVE
                       );    
  signal state : PWR_state_t := PS_RESET;
  signal readout_done : std_logic := '0';
  
  -- Sensors
  signal iDevice : integer range DEVICE_COUNT-1 downto 0 := 0;  
  signal ENABLED_SENSORS : std_logic_vector(7 downto 0) := x"F8";
  constant CONVERT_RUNNING_BIT : integer := 2;
  constant SENSOR_PAIR_COUNT : integer := 5;
  signal   sensor_pair_number     : integer range SENSOR_PAIR_COUNT -1 downto 0 := 0;
  constant sensor_pair_number_end : integer range SENSOR_PAIR_COUNT -1 downto 0 := SENSOR_PAIR_COUNT-1;
  constant sensor_address : uint8_array_t(SENSOR_PAIR_COUNT-1 downto 0) := (x"1a",
                                                                            x"16",
                                                                            x"12",
                                                                            x"0e",
                                                                            x"0a");
 
begin  -- architecture behavioral

  I2C_PWR_MON: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 25,
      IGNORE_ACK                     => '0',
      REG_ADDR_BYTE_COUNT            => 1,
      USE_RESTART_FOR_READ_SEQUENCE  => '1')
    port map (
      clk_sys     => clk,
      reset       => reset,
      I2C_Address => I2c_address(iDevice),
      run         => run,
      rw          => rw,
      reg_addr    => reg_addr,
      rd_data     => rd_data,
      wr_data     => wr_data,
      byte_count  => byte_count,
      done        => transaction_done,
      error       => transaction_error,
      SDA         => PWR_SDA,
      SCLK        => PWR_SCL);    

  idle_counter: process (clk) is
  begin  -- process idle_counter
    if clk'event and clk = '1' then  -- rising clock edge
      
      -- keep track of the time we are waiting
      if idle_count < IDLE_COUNT_END then
        idle_count <= idle_count + 1;
      elsif state = PS_IDLE_WAIT then        
        -- we are done idling and are in the PD_IDLE_WAIT state, so
        -- we should reset our idle and tell the state machine to get to work.
        idle_count_done <= '1';
      elsif state = PS_START then
        idle_count_done <= '0';
        idle_count <= IDLE_COUNT_START;
      end if;        
    end if;
  end process idle_counter;

  convert_counter: process (clk) is
  begin  -- process convert_counter
    if clk'event and clk = '1' then  -- rising clock edge
      convert_count_done <= '0';
      if state = PS_CONVERT_WAIT then
        if convert_count < CONVERT_COUNT_END then
          convert_count <= convert_count + 1;
        else
          convert_count_done <= '1';
        end if;
      else
        convert_count <= CONVERT_COUNT_START;
      end if;
    end if;
  end process convert_counter;

  
  state_machine_transitions: process (clk) is
  begin  -- process state_machine_transitions
    if clk'event and clk = '1' then  -- rising clock edge
      if reset_sync = '1' then
        state <= PS_RESET;
      else
        case state is
          when PS_RESET =>
            state <= PS_INIT;
          ---------------------------------------------------
          when PS_INIT =>
            state <= PS_INIT_DELAY;
          ---------------------------------------------------
          when PS_INIT_DELAY =>
            state <= PS_INIT_OK;
          ---------------------------------------------------
          when PS_INIT_OK =>
            if transaction_done = '1' then
              if transaction_error = '1' then
                --There was an error, re-try transaction
                state <= PS_RESET;
              else
                -- Command was ok, move on
                state <= PS_IDLE_WAIT;
              end if;
            end if;                        
          ---------------------------------------------------
          when PS_IDLE_WAIT =>
            if idle_count_done = '1' then
              state <= PS_START;
            end if;
          ---------------------------------------------------
          when PS_START =>
            state <= PS_CONVERT_CMD;
          ---------------------------------------------------
          when PS_CONVERT_CMD =>
            state <= PS_CONVERT_DELAY;
          ---------------------------------------------------
          when PS_CONVERT_DELAY =>
            state <= PS_CONVERT_CMD_OK;
          ---------------------------------------------------
          when PS_CONVERT_CMD_OK =>
            if transaction_done = '1' then
              if transaction_error = '1' then
                --There was an error, re-try transaction
                state <= PS_RESET;
              else
                -- COmmand was ok, move on
                state <= PS_CONVERT_WAIT;
              end if;
            end if;            
          ---------------------------------------------------
          when PS_CONVERT_WAIT =>
            if convert_count_done = '1' then
              state <= PS_STATUS_CMD;  
            end if;            
          ---------------------------------------------------
          when PS_STATUS_CMD =>
            state <= PS_STATUS_DELAY;
          ---------------------------------------------------
          when PS_STATUS_DELAY =>
            state <= PS_STATUS_CMD_OK;
          ---------------------------------------------------
          when PS_STATUS_CMD_OK =>
            if transaction_done = '1' then
              if transaction_error = '1' then
                --There was an error, re-try transaction
                state <= PS_RESET;
              elsif rd_data(CONVERT_RUNNING_BIT) = '0' then
                -- read worked and sensors read to be read
                state <= PS_READOUT_CMD;
              else
                -- read worked, but sensors not ready yet.
                state <= PS_STATUS_CMD;
              end if;
            end if;            
          ---------------------------------------------------
          when PS_READOUT_CMD =>
            state <= PS_READOUT_DELAY;
          ---------------------------------------------------
          when PS_READOUT_DELAY =>
            state <= PS_READOUT_CMD_OK;
          ---------------------------------------------------
          when PS_READOUT_CMD_OK =>
            if transaction_done = '1' then
              if transaction_error = '1' then
                --There was an error, re-try transaction
                state <= PS_RESET;
              else
                --Command was ok, move to save state
                state <= PS_READOUT_SAVE;
              end if;
            end if;
          ---------------------------------------------------
          when PS_READOUT_SAVE =>
            if readout_done = '1' then
              state <= PS_IDLE_WAIT;
              -- switch device
              iDevice <= iDevice + 1;
              if iDEVICE = DEVICE_COUNT - 1 then
                iDevice <= 0;
              end if;
            else
              state <= PS_READOUT_CMD;
            end if;
          ---------------------------------------------------
          when others =>
            state <= PS_RESET;
        end case;
      end if;
    end if;
  end process state_machine_transitions;

  --Update the sensor readout as done when we are on the last sensor
  readout_done <= '1' when sensor_pair_number = sensor_pair_number_end else '0';
  reset <= '1' when state = PS_RESET else '0';
  state_machine: process (clk) is
  begin  -- process SM_init
    if clk'event and clk = '1' then  -- rising clock edge
      run <= '0';
      
      case state is
        -----------------------------------------------------
        when PS_RESET => NULL;
        -----------------------------------------------------
        when PS_INIT =>          
          reg_addr <= x"06"; -- 0x06 and 0x07  control regs
          wr_data  <= x"0000" & x"11" & x"11"; -- Set up for V1-V2,V3-V4,V5-V6,V7-V8 and
                                               -- voltage measurements and no filter
          byte_count <= "010"; -- two bytes
          
          rw  <= '0'; -- write mode
          run <= '1'; -- run
        when PS_INIT_OK => NULL;
        -----------------------------------------------------
        when PS_IDLE_WAIT => NULL;
        -----------------------------------------------------
        when PS_CONVERT_CMD =>
          reg_addr <= x"01"; -- status/trigger reg
          wr_data  <= x"000000" & x"F8"; -- enable sensors for readout
                                            
          byte_count <= "001"; -- one byte
          
          rw  <= '0'; -- write mode
          run <= '1'; -- run
        when PS_CONVERT_CMD_OK => NULL;
        -----------------------------------------------------
        when PS_STATUS_CMD =>
          reg_addr <= x"01"; -- status/trigger reg
          
          byte_count <= "001"; -- one byte
          
          rw  <= '1'; -- read mode
          run <= '1'; -- run
        when PS_STATUS_CMD_OK =>          
          sensor_pair_number <= 0;
       -----------------------------------------------------
        when PS_READOUT_CMD =>
          reg_addr <= sensor_address(sensor_pair_number); -- status/trigger reg
          
          byte_count <= "100"; -- four bytes
          
          rw  <= '1'; -- read mode
          run <= '1'; -- run
        when PS_READOUT_CMD_OK => NULL;
        when PS_READOUT_SAVE =>
          sensor_pair_number <= sensor_pair_number + 1;
          -- save data for these sensors
          data(10*iDevice + 2*sensor_pair_number + 0) <= rd_data( 7 downto  0)&rd_data(15 downto  8);
          data(10*iDevice + 2*sensor_pair_number + 1) <= rd_data(23 downto 16)&rd_data(31 downto 24);
        when others => null;
      end case;
    end if;
  end process state_machine;

  
end architecture behavioral;
