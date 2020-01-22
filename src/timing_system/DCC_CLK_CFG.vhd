library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.DCC_IO.all;

entity DCC_CLK_CFG is

  port (
    clk             : in    std_logic;
    reset           : in    std_logic;
    SI5338_SCL      : inout std_logic;
    SI5338_SDA      : inout std_logic;
    SI5338_SDA_EN   : out std_logic;
    clk_switch      : out   std_logic;
    cmd_switch      : out   std_logic;
    clk_DUNE_P      : in    std_logic;
    clk_DUNE_50Mhz  : out   std_logic;
    clk_locked      : out   std_logic;
    monitor         : out   DCC_CLK_CFG_Monitor_t;
    control         : in    DCC_CLK_CFG_Control_t);

end entity DCC_CLK_CFG;

architecture behavioral of DCC_CLK_CFG is

  component DCC_DUNE_PLL is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component DCC_DUNE_PLL;


  component I2c_master is
    generic (
      ACK_DISABLE : std_logic;
      SCL_WIDTH   : integer);
    port (
      rst           : in    std_logic;
      sys_clk       : in    std_logic;
      SCL_O         : inout std_logic;
      SDA           : inout   std_logic;
      SDA_EN        : out   std_logic;
      I2C_WR_STRB   : in    std_logic;
      I2C_RD_STRB   : in    std_logic;
      I2C_DEV_ADDR  : in    std_logic_vector(6 downto 0);
      I2C_NUM_BYTES : in    std_logic_vector(3 downto 0);
      I2C_ADDRESS   : in    std_logic_vector(7 downto 0);
      I2C_DOUT      : out   std_logic_vector(31 downto 0);
      I2C_DIN       : in    std_logic_vector(31 downto 0);
      I2C_BUSY      : out   std_logic;
      I2C_DEV_AVL   : out   std_logic);
  end component I2c_master;

  component SI5338_MEM is
    port (
      address : in  std_logic_vector (8 downto 0);
      clock   : in  std_logic := '1';
      q       : out std_logic_vector (23 downto 0));
  end component SI5338_MEM;

  --Memory interface
  constant ROM_DONE  : unsigned(8 downto 0) := '1' & x"5D";
  signal ROM_address : unsigned(8 downto 0) := (others => '0');
  signal ROM_data    : std_logic_vector(23 downto 0);




  -- I2C interface
  constant SI5338_address : std_logic_vector(6 downto 0)  := "111"&x"0";
  signal wr_strobe        : std_logic_vector(1 downto 0)  := "00";
  signal rd_strobe        : std_logic_vector(1 downto 0)  := "00";
  signal reg_address      : std_logic_vector(7 downto 0)  := (others => '0');
  signal i2c_busy         : std_logic;
  signal byte_count       : std_logic_vector(3 downto 0)  := x"0";
  signal data_out         : std_logic_vector(31 downto 0) := (others => '0');
  signal data_in          : std_logic_vector(31 downto 0) := (others => '0');

  -- Programming state machine
  type Program_state_t is (PROGRAM_STATE_START,
                           PROGRAM_STATE_BOOTUP_IDLE,
                           PROGRAM_STATE_SETUP_1,
                           PROGRAM_STATE_SETUP_2,
                           PROGRAM_STATE_PROGRAM_REGS,
                           PROGRAM_STATE_PROGRAM_REGS_RMW,
                           PROGRAM_STATE_REGS_DONE,
                           PROGRAM_STATE_CHECK_LOS,
                           PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_RD,
                           PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_WR,
                           PROGRAM_STATE_SOFT_RESET,
                           PROGRAM_STATE_DISABLE_LOL,
                           PROGRAM_STATE_SOFT_RESET_DELAY,
                           PROGRAM_STATE_CHECK_LOCK,
                           PROGRAM_STATE_CHECK_LOCK_RESULT,
                           PROGRAM_STATE_COPY_FCAL1_RD,
                           PROGRAM_STATE_COPY_FCAL1_WR,
                           PROGRAM_STATE_COPY_FCAL2_RD,
                           PROGRAM_STATE_COPY_FCAL2_WR,
                           PROGRAM_STATE_COPY_FCAL3_RD1,
                           PROGRAM_STATE_COPY_FCAL3_RD2,
                           PROGRAM_STATE_COPY_FCAL3_WR,
                           PROGRAM_STATE_FCAL_OVRD_EN_RD,
                           PROGRAM_STATE_FCAL_OVRD_EN_WR,
                           PROGRAM_STATE_OEB_ALL,
                           PROGRAM_STATE_DONE
                           );
  signal program_state  : Program_state_t              := PROGRAM_STATE_START;
  signal fcal_temp      : std_logic_vector(7 downto 0) := (others => '0');
  signal timer          : unsigned(23 downto 0)        := x"000000";
  constant LOS_BIT      : integer                      := 2;
  constant PLL_LOL_BIT  : integer                      := 4;
  constant LOS_FDBK_BIT : integer                      := 3;
  constant SYS_CAL_BIT  : integer                      := 0;


  -- PLL controls
  signal reset_FEMB_PLL  : std_logic := '1';
  signal reset_DUNE_PLL  : std_logic := '1';
  signal locked_FEMB_PLL : std_logic;
  signal locked_DUNE_PLL : std_logic;


  signal test1 : std_logic := '0';
  signal test0 : std_logic := '1';
  
begin  -- architecture behavioral

  -- Si5338C control
  I2c_master_1 : entity work.I2c_master
    generic map (
      ACK_DISABLE => '1',
      SCL_WIDTH   => 120)  -- Drop the I2C frequency to 100khz with a 250Mhz clock
    port map (
      rst           => reset,
      sys_clk       => clk,
      SCL_O         => SI5338_SCL,
      SDA           => SI5338_SDA,
      SDA_EN        => SI5338_SDA_EN,
      I2C_WR_STRB   => wr_strobe(0),
      I2C_RD_STRB   => rd_strobe(0),
      I2C_DEV_ADDR  => SI5338_address,
      I2C_NUM_BYTES => byte_count,
      I2C_ADDRESS   => reg_address,
      I2C_DOUT      => data_in,-- data_out,
      I2C_DIN       => data_out, --data_in,
      I2C_BUSY      => i2c_busy,
      I2C_DEV_AVL   => open);

  

  SI5338_MEM_1 : entity work.SI5338_MEM
    port map (
      address => std_logic_vector(ROM_address),
      clock   => clk,
      q       => ROM_data);

  si5338_program : process (clk, reset) is
  begin  -- process si5338_program
    if reset = '1' then                 -- asynchronous reset (active high)
      program_state  <= PROGRAM_STATE_START;
      reset_DUNE_PLL <= '1';
      reset_FEMB_PLL <= '1';
      wr_strobe      <= (others => '0');
      rd_strobe      <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge

      --Reset rd/wr strobe
      wr_strobe(0) <= '0';
      rd_strobe(0) <= '0';
      --store the last rd/wr strobe value since it take more than one clock
      --tick for the I2C module to register itself as busy
      wr_strobe(1) <= wr_strobe(0);
      rd_strobe(1) <= rd_strobe(0);

      case program_state is

        ----------------------------------------------------
        when PROGRAM_STATE_START =>
          --Hold the PLLs in reset since we are messing with their ref clocks
          reset_DUNE_PLL <= '1';
          reset_FEMB_PLL <= '1';

          timer         <= x"000000";
          program_state <= PROGRAM_STATE_BOOTUP_IDLE;

        ----------------------------------------------------
        when PROGRAM_STATE_BOOTUP_IDLE =>
          timer <= timer + 1;
          if timer(19 downto 18) = "11" then
            -- sleep for 12 ms
            program_state <= PROGRAM_STATE_SETUP_1;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_SETUP_1 =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- Write the byte 0x10 to register 230d
            byte_count   <= x"1";
            reg_address  <= x"E6";
            data_out     <= x"000000"&x"10";
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_SETUP_2;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_SETUP_2 =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- Write the byte 0xE5 to register 241d
            byte_count   <= x"1";
            reg_address  <= x"F1";
            data_out     <= x"000000"&x"E5";
            wr_strobe(0) <= '1';

            ROM_address   <= (others => '0');
            program_state <= PROGRAM_STATE_PROGRAM_REGS;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_PROGRAM_REGS =>
          if ROM_address = ROM_DONE then
            program_state <= PROGRAM_STATE_REGS_DONE;
          elsif i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            if ROM_data(7 downto 0) = x"00" then
              -- We just have to do a write
              byte_count   <= x"1";
              reg_address  <= ROM_data(23 downto 16);
              data_out     <= x"000000" & ROM_data(15 downto 8);
              wr_strobe(0) <= '1';

              -- go to next reg
              ROM_address   <= ROM_address + 1;
              program_state <= PROGRAM_STATE_PROGRAM_REGS;
            else
              -- We have to do a read-modify-write
              byte_count   <= x"1";
              reg_address  <= ROM_data(23 downto 16);
              rd_strobe(0) <= '1';

              -- process read
              program_state <= PROGRAM_STATE_PROGRAM_REGS_RMW;
            end if;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_PROGRAM_REGS_RMW =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- use data_in to set data_out and do a write
            byte_count  <= x"1";
            reg_address <= ROM_data(23 downto 16);
            data_out    <= x"000000" &
                        ((data_in(7 downto 0) and ROM_data(7 downto 0)) or
                         (ROM_data(15 downto 8) and (not ROM_data(7 downto 0))));
            wr_strobe(0) <= '1';

            -- go to next reg
            ROM_address   <= ROM_address + 1;
            program_state <= PROGRAM_STATE_PROGRAM_REGS;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_REGS_DONE =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- read register 0xDA for LOS to go away
            byte_count    <= x"1";
            reg_address   <= x"DA";
            rd_strobe(0)     <= '1';
            program_state <= PROGRAM_STATE_CHECK_LOS;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_CHECK_LOS =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            if data_in(LOS_BIT) = '0' then
              -- loss of signal has gone away, move on
              program_state <= PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_RD;
            else
              program_state <= PROGRAM_STATE_REGS_DONE;
            end if;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_RD =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"31";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_WR;
          end if;

        ----------------------------------------------------                   
        when PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_WR =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"31";
            data_out     <= x"000000" & '0' & data_in(6 downto 0);
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_SOFT_RESET;
          end if;

        ----------------------------------------------------                    
        when PROGRAM_STATE_SOFT_RESET =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"F6";
            data_out     <= x"000000" & x"02";
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_DISABLE_LOL;
          end if;

        ----------------------------------------------------                    
        when PROGRAM_STATE_DISABLE_LOL =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"F1";
            data_out     <= x"000000" & x"65";
            wr_strobe(0) <= '1';

            timer         <= x"000000";
            program_state <= PROGRAM_STATE_SOFT_RESET_DELAY;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_SOFT_RESET_DELAY =>
          timer <= timer + 1;
          if timer(20 downto 18) = "111" then
            -- sleep for 24 ms
            program_state <= PROGRAM_STATE_CHECK_LOCK;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_CHECK_LOCK =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- read register 0xDA for PLL_LOL, LOS_FDBK, and SYS_CAL
            byte_count   <= x"1";
            reg_address  <= x"DA";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_CHECK_LOCK_RESULT;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_CHECK_LOCK_RESULT =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            if (data_in(PLL_LOL_BIT) = '0' and data_in(LOS_FDBK_BIT) = '0' and data_in(SYS_CAL_BIT) = '0') then
              -- looks good
              program_state <= PROGRAM_STATE_COPY_FCAL1_RD;
            else
              program_state <= PROGRAM_STATE_CHECK_LOCK;
            end if;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_COPY_FCAL1_RD =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"EB";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL1_WR;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_COPY_FCAL1_WR =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"2D";
            data_out     <= x"000000" & data_in(7 downto 0);
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL2_RD;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_COPY_FCAL2_RD =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"EC";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL2_WR;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_COPY_FCAL2_WR =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"2E";
            data_out     <= x"000000" & data_in(7 downto 0);
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL3_RD1;
          end if;

        ----------------------------------------------------
        when PROGRAM_STATE_COPY_FCAL3_RD1 =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            -- read the upper bits of 0x2F
            byte_count   <= x"1";
            reg_address  <= x"2F";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL3_RD2;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_COPY_FCAL3_RD2 =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            --cache the upper bits of 0x2F
            fcal_temp <= data_in(7 downto 2) & "00";

            -- read the lower bits from ED
            byte_count   <= x"1";
            reg_address  <= x"ED";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_COPY_FCAL3_WR;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_COPY_FCAL3_WR =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"2F";
            data_out     <= x"000000" & fcal_temp(7 downto 2) & data_in(1 downto 0);
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_FCAL_OVRD_EN_RD;
          end if;


        ----------------------------------------------------
        when PROGRAM_STATE_FCAL_OVRD_EN_RD =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"31";
            rd_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_FCAL_OVRD_EN_WR;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_FCAL_OVRD_EN_WR =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"31";
            data_out     <= x"000000" & '1' & data_in(6 downto 0);
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_OEB_ALL;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_OEB_ALL =>
          if i2c_busy = '0' and wr_strobe = "00" and rd_strobe = "00" then
            byte_count   <= x"1";
            reg_address  <= x"E6";
            data_out     <= x"00000000";
            wr_strobe(0) <= '1';

            program_state <= PROGRAM_STATE_DONE;
          end if;

        ----------------------------------------------------          
        when PROGRAM_STATE_DONE =>
          --Turn off reset on the PLLs
          reset_DUNE_PLL <= '0';
          reset_FEMB_PLL <= '0';

          if control.reset_SI5338 = '1' then
            program_state <= PROGRAM_STATE_START;
          end if;

        when others =>
          program_state <= PROGRAM_STATE_START;
      end case;
    end if;
  end process si5338_program;



  monitor.clk_switch   <= control.clk_switch;
  monitor.cmd_switch   <= control.cmd_switch;
  monitor.reset_SI5338 <= control.reset_SI5338;
  DCC_CLK_Control : process (clk, reset) is
  begin  -- process DCC_CLK_Control
    if reset = '1' then                 -- asynchronous reset (active high)
      clk_switch <= DEFAULT_DCC_CLK_CFG_Control.clk_switch;
      cmd_switch <= DEFAULT_DCC_CLK_CFG_Control.cmd_switch;
    elsif clk'event and clk = '1' then  -- rising clock edge
      -- control
      clk_switch              <= control.clk_switch;
      cmd_switch              <= control.cmd_switch;
      -- monitoring
      monitor.reset_DUNE_PLL  <= reset_DUNE_PLL;
      monitor.reset_FEMB_PLL  <= reset_FEMB_PLL;
      monitor.locked_DUNE_PLL <= locked_DUNE_PLL;
      monitor.locked_FEMB_PLL <= locked_FEMB_PLL;

      case program_state is
        when PROGRAM_STATE_START                   => monitor.program_state <= x"01";
        when PROGRAM_STATE_BOOTUP_IDLE             => monitor.program_state <= x"02";
        when PROGRAM_STATE_SETUP_1                 => monitor.program_state <= x"03";
        when PROGRAM_STATE_SETUP_2                 => monitor.program_state <= x"04";
        when PROGRAM_STATE_PROGRAM_REGS            => monitor.program_state <= x"05";
        when PROGRAM_STATE_PROGRAM_REGS_RMW        => monitor.program_state <= x"06";
        when PROGRAM_STATE_REGS_DONE               => monitor.program_state <= x"07";
        when PROGRAM_STATE_CHECK_LOS               => monitor.program_state <= x"08";
        when PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_RD => monitor.program_state <= x"09";
        when PROGRAM_STATE_FCAL_OVERRIDE_ENABLE_WR => monitor.program_state <= x"0a";
        when PROGRAM_STATE_SOFT_RESET              => monitor.program_state <= x"0b";
        when PROGRAM_STATE_DISABLE_LOL             => monitor.program_state <= x"0c";
        when PROGRAM_STATE_SOFT_RESET_DELAY        => monitor.program_state <= x"0d";
        when PROGRAM_STATE_CHECK_LOCK              => monitor.program_state <= x"0e";
        when PROGRAM_STATE_CHECK_LOCK_RESULT       => monitor.program_state <= x"0f";
        when PROGRAM_STATE_COPY_FCAL1_RD           => monitor.program_state <= x"10";
        when PROGRAM_STATE_COPY_FCAL1_WR           => monitor.program_state <= x"11";
        when PROGRAM_STATE_COPY_FCAL2_RD           => monitor.program_state <= x"12";
        when PROGRAM_STATE_COPY_FCAL2_WR           => monitor.program_state <= x"13";
        when PROGRAM_STATE_COPY_FCAL3_RD1          => monitor.program_state <= x"14";
        when PROGRAM_STATE_COPY_FCAL3_RD2          => monitor.program_state <= x"15";
        when PROGRAM_STATE_COPY_FCAL3_WR           => monitor.program_state <= x"16";
        when PROGRAM_STATE_FCAL_OVRD_EN_RD         => monitor.program_state <= x"17";
        when PROGRAM_STATE_FCAL_OVRD_EN_WR         => monitor.program_state <= x"18";
        when PROGRAM_STATE_OEB_ALL                 => monitor.program_state <= x"19";
        when PROGRAM_STATE_DONE                    => monitor.program_state <= x"1a";
        when others                                => monitor.program_state <= x"00";
      end case;


    end if;
  end process DCC_CLK_Control;

  ----------
  DCC_DUNE_PLL_1 : DCC_DUNE_PLL
    port map (
      refclk   => clk_DUNE_P,
      rst      => reset_DUNE_PLL,
      outclk_0 => clk_DUNE_50Mhz,
      locked   => locked_DUNE_PLL);


  clk_locked <= locked_FEMB_PLL and locked_DUNE_PLL;

end architecture behavioral;


