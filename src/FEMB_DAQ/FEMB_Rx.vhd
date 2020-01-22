library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.WIB_Constants.all;
use work.FEMB_DAQ_IO.all;
use work.types.all;

--! The FEMB_RxTx modulue handles the transceiver streams and user logic interface

--! This module is used to isolate the details of the FPGAs transceivers.
--! It generates LINK_COUNT Tx and Rx links and provides decoded 8b10b data
--! interfaces for both.
--! As per Altera's documentation, an fPLL is generated for each Tx
--! (LINK_COUNT of them), but since they are have the same reference clock and
--! reconfigure controller, quartus will combine them as possible, lowering the
--! total number of fPLLs used. 
entity FEMB_Rx is

  port (
    clk_in             : in  std_logic;  --! user logic clock
    reset_clk_in_sync  : in  std_logic;
    Rx                 : in  std_logic_vector(LINK_COUNT-1 downto 0);  --! Rx input
    Rx_refclk          : in  std_logic_vector(LINK_GROUPS-1 downto 0);  --! reference clock for the Rx
    rx_data            : out data_8b10b_t(LINK_COUNT downto 1);    
    rx_valid           : out std_logic_vector(LINK_COUNT downto 1);
    monitor            : out FEMB_COLDATA_Rx_Monitor_array_t;
    control            : in  FEMB_COLDATA_Rx_Control_array_t
    );

end entity FEMB_Rx;

architecture behavioral of FEMB_Rx is

  component trans_reseter is
    generic (
      TX_COUNT : integer);
    port (
      sys_clk         : in  std_logic;
      sys_reset       : in  std_logic;
      pll_powerdown   : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_analogreset  : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_digitalreset : out std_logic_vector(TX_COUNT - 1 downto 0);
      pll_locked      : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_cal_busy     : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0));
  end component trans_reseter;
  
  component CD_RL_FIFO is
    port (
      aclr    : IN  STD_LOGIC := '0';
      data    : IN  STD_LOGIC_VECTOR (8 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      rdusedw : OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
      wrfull  : OUT STD_LOGIC;
      wrusedw : OUT STD_LOGIC_VECTOR (5 DOWNTO 0));
  end component CD_RL_FIFO;

  component timed_counter is
    generic (
      timer_count : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      enable      : in  std_logic;
      event       : in  std_logic;
      update_pulse : out std_logic;
      timed_count : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component timed_counter;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  
  ---------------------------------------------------------------------------
  -- COLD Data transceiver interface components
  component COLDATA_Rx is
    port (
      rx_analogreset          : in  std_logic_vector(3 downto 0)   := (others => '0');
      rx_digitalreset         : in  std_logic_vector(3 downto 0)   := (others => '0');
      rx_cdr_refclk           : in  std_logic_vector(0 downto 0)   := (others => '0');
      rx_serial_data          : in  std_logic_vector(3 downto 0)   := (others => '0');
      rx_is_lockedtoref       : out std_logic_vector(3 downto 0);
      rx_is_lockedtodata      : out std_logic_vector(3 downto 0);
      rx_std_coreclkin        : in  std_logic_vector(3 downto 0)   := (others => '0');
      rx_std_clkout           : out std_logic_vector(3 downto 0);
      rx_cal_busy             : out std_logic_vector(3 downto 0);
      reconfig_to_xcvr        : in  std_logic_vector(279 downto 0) := (others => '0');
      reconfig_from_xcvr      : out std_logic_vector(183 downto 0);
      rx_parallel_data        : out std_logic_vector(31 downto 0);
      rx_datak                : out std_logic_vector(3 downto 0);
      rx_errdetect            : out std_logic_vector(3 downto 0);
      rx_disperr              : out std_logic_vector(3 downto 0);
      rx_runningdisp          : out std_logic_vector(3 downto 0);
      rx_patterndetect        : out std_logic_vector(3 downto 0);
      rx_syncstatus           : out std_logic_vector(3 downto 0);
      unused_rx_parallel_data : out std_logic_vector(199 downto 0));
  end component COLDATA_Rx;

  constant GROUP_SIZE : integer := LINK_COUNT/LINK_GROUPS;

  component counter is
    generic (
      roll_over   : std_logic;
      end_value   : std_logic_vector;
      start_value : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      enable      : in  std_logic;
      event       : in  std_logic;
      count       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      at_max      : out std_logic);
  end component counter;

  component reseter is
    generic (
      DEPTH : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      reset       : out std_logic);
  end component reseter;
  
  ---------------------------------------------------------------------------
  -- COLD Data transceiver interface components
  ---------------------------------------------------------------------------

  signal fboutclk : std_logic;

  signal reconfig_to_RxTx_xcvr   : std_logic_vector((LINK_COUNT*70)-1 downto 0);
  signal reconfig_from_RxTx_xcvr : std_logic_vector((LINK_COUNT*46)-1 downto 0);

  signal rx_data_reordered   : std_logic_vector((LINK_COUNT*8)-1 downto 0) := (others => '0');
  signal rx_data_k_reordered : std_logic_vector(LINK_COUNT-1 downto 0)     := (others => '0');
  signal rx_data_ordered     : data_8b10b_t(LINK_COUNT downto 1);    
  signal core_clk            : std_logic_vector(LINK_COUNT-1 downto 0)     := (others => '0');
  signal core_clk_out        : std_logic_vector(LINK_COUNT-1 downto 0)     := (others => '0');
  signal rx_std_rmfifo_full  : std_logic_vector(LINK_COUNT-1 downto 0)     := (others => '0');
  signal rx_std_rmfifo_empty : std_logic_vector(LINK_COUNT-1 downto 0)     := (others => '0');

  signal rx_analogreset       : std_logic_vector(LINK_COUNT-1 downto 0);
  signal rx_digitalreset      : std_logic_vector(LINK_COUNT-1 downto 0);
  signal rx_is_locked_to_data : std_logic_vector(LINK_COUNT-1 downto 0);
  signal rx_cal_busy          : std_logic_vector(LINK_COUNT-1 downto 0);
  
--  signal rx_data_buffer      : data_8b10b_t(LINK_COUNT downto 1);

  signal rx_error      : std_logic_vector(LINK_COUNT downto 1) := (others => '0');
  signal rx_disp_error : std_logic_vector(LINK_COUNT downto 1) := (others => '0');


  signal rx_raw_data : data_8b10b_t(LINK_COUNT downto 1);
  signal link_rd : std_logic_vector(LINK_COUNT downto 1);
  signal link_rd_comb : std_logic_vector(LINK_COUNT downto 1);
  signal link_wr : std_logic_vector(LINK_COUNT downto 1);
  signal link_empty : std_logic_vector(LINK_COUNT downto 1);
  signal link_buffer_full : std_logic_vector(LINK_COUNT downto 1);
  signal link_buffer_used_wr : uint6_array_t(LINK_COUNT downto 1);
  signal link_buffer_used_rd : uint6_array_t(LINK_COUNT downto 1);    
  signal idle_count : uint5_array_t(LINK_COUNT downto 1);

  signal rx_data_buffer  : data_8b10b_t(LINK_COUNT downto 1);    
  signal rx_valid_buffer : std_logic_vector(LINK_COUNT downto 1);

  signal reset_core      : std_logic_vector(LINK_COUNT downto 1)     := (others => '0');
  signal reset_link_side : std_logic_vector(LINK_COUNT downto 1);
  
  -- monitoring sof rate
  signal SOF_pulse : std_logic_vector(LINK_COUNT downto 1);
  signal SOF_rate_update : std_logic_vector(LINK_COUNT downto 1);
  signal SOF_rate_capture : std_logic_vector(LINK_COUNT downto 1);
  signal sof_rate : uint32_array_t(LINK_COUNT downto 1);

  
begin  -- architecture behavioral

  --Transceiver IP CORE (look over right and left clocked IOs)
  refclk_group : for iRefClk in LINK_GROUPS downto 1 generate
    trans_reseter_1: entity work.trans_reseter
      generic map (
        TX_COUNT => LINK_COUNT/LINK_GROUPS)
      port map (
        sys_clk         => clk_in,
        sys_reset       => '0',
        pll_powerdown   => open,
        tx_analogreset  => rx_analogreset      ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) ),
        tx_digitalreset => rx_digitalreset     ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) ),
        pll_locked      => rx_is_locked_to_data( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) ),
        tx_cal_busy     => rx_cal_busy         ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) ),
        tx_ready        => open);
    
    monitor(iRefClk).rx_analogreset     <= rx_analogreset      ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) ); --control(iRefClk).rx_analogreset;
    monitor(iRefClk).rx_digitalreset    <= rx_digitalreset     ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) );--control(iRefClk).rx_digitalreset;
    monitor(iRefClk).rx_is_lockedtodata <= rx_is_locked_to_data( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE * (iRefclk-1) );--control(iRefClk).rx_digitalreset;
    
--    monitor(iRefClk).rx_errdetect    <= rx_error     ((GROUP_SIZE)*(iRefClk) downto   (GROUP_SIZE)*(iRefClk-1)+1);
--    monitor(iRefClk).rx_disperr      <= rx_disp_error((GROUP_SIZE)*(iRefClk) downto   (GROUP_SIZE)*(iRefClk-1)+1);
    COLDATA_Rx_1 : COLDATA_Rx
      port map (
        rx_analogreset          => rx_analogreset      ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefclk-1) ),--control(iRefClk).rx_analogreset,
        rx_digitalreset         => rx_digitalreset     ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefclk-1) ),--control(iRefClk).rx_digitalreset,
        rx_cdr_refclk           => Rx_refclk(iRefClk-1 downto iRefClk-1),
        rx_serial_data          => Rx                  ( (GROUP_SIZE)*(iRefClk) -1 downto GROUP_SIZE*(iRefClk-1) ),
        rx_is_lockedtoref       => open,--monitor(iRefClk).rx_is_lockedtoref,
        rx_is_lockedtodata      => rx_is_locked_to_data( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefclk-1) ),--monitor(iRefClk).rx_is_lockedtodata,
        rx_std_coreclkin        => core_clk            ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefClk-1) ),
        rx_std_clkout           => core_clk_out        ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefClk-1) ),
        rx_cal_busy             => rx_cal_busy         ( (GROUP_SIZE * iRefClk) -1 downto GROUP_SIZE*(iRefclk-1) ),--open,--monitor(iRefClk).rx_cal_busy,
        reconfig_to_xcvr        => reconfig_to_RxTx_xcvr   ((70*GROUP_SIZE)*(iRefClk) -1 downto (70*GROUP_SIZE)*(iRefClk-1)),
        reconfig_from_xcvr      => reconfig_from_RxTx_xcvr ((46*GROUP_SIZE)*(iRefClk) -1 downto (46*GROUP_SIZE)*(iRefClk-1)),
        rx_parallel_data        => rx_data_reordered(  8*(GROUP_SIZE)*(iRefClk) - 1 downto 8*(GROUP_SIZE)*(iRefClk-1) ),
        rx_datak                => rx_data_k_reordered(  (GROUP_SIZE)*(iRefClk) - 1 downto   (GROUP_SIZE)*(iRefClk-1) ),
        rx_errdetect            => rx_error     ((GROUP_SIZE)*(iRefClk) downto   (GROUP_SIZE)*(iRefClk-1) + 1),
        rx_disperr              => rx_disp_error((GROUP_SIZE)*(iRefClk) downto   (GROUP_SIZE)*(iRefClk-1) + 1),
        rx_runningdisp          => open,--monitor(iRefClk).rx_runningdisp,
        rx_patterndetect        => open,--monitor(iRefClk).rx_patterndetect,        
        rx_syncstatus           => open,--monitor(iRefClk).rx_syncstatus,
        unused_rx_parallel_data => open);
  end generate refclk_group;

  -- clock for the user logic side of the FIFOs
  core_clk <= core_clk_out;
  

  link_CDC: for iLink in LINK_COUNT downto 1 generate


    --Build reset for raw input processing
    pacd_2: entity work.pacd
      port map (
        iPulseA => control(((iLink-1)/4)+1).reset_link_side(((iLink-1) mod 4)+1),
        iClkA   => clk_in,
        iRSTAn  => '1',
        iClkB   => core_clk(iLink-1),
        iRSTBn  => '1',
        oPulseB => reset_link_side(iLink));
    

    
    rx_data_ordered(iLink)(7 downto 0) <= rx_data_reordered((iLink*8) -1 downto (iLink-1)*8);
    rx_data_ordered(iLink)(8)          <= rx_data_k_reordered(iLink-1);

    reseter_1: entity work.reseter
      port map (
        clk         => core_clk(iLink-1),
        reset_async => reset_clk_in_sync,
        reset_sync  => '0',
        reset       => reset_core(iLink));
    
    RL_input: process (core_clk(iLink-1),reset_core(iLink)) is
    begin  -- process RL_input
      if reset_core(iLink) = '1' then
          link_wr(iLink) <= '0';
          idle_count(iLink) <= (others => '0');        
      elsif core_clk(iLink-1)'event and core_clk(iLink-1) = '1' then  -- rising clock edge
--        if reset_link_side(iLink) = '1' then
        if ((reset_link_side(iLink) = '1')) then
          link_wr(iLink) <= '0';
          idle_count(iLink) <= (others => '0');
        else
          rx_raw_data(iLink) <= rx_data_ordered(iLink);
          link_wr(iLink) <= '1';
          idle_count(iLink) <= (others => '0');
          
          if link_buffer_full(iLink) = '1' then
            --Skip writing a word if the buffer is full
            link_wr(iLink) <= '0';                  
          elsif rx_error(iLink) = '1' or rx_disp_error(iLink) = '1' then
            -- don't write a bad char
            link_wr(iLink) <= '0';
          elsif or_reduce(link_buffer_used_wr(iLink)(5 downto 3)) = '1'  then
            -- we have atleast 8 words in the fifo, so we should skip 1x3C words
            -- if there are more than four of them in a row
            if ( (rx_data_ordered(iLink) = '1'&x"3C"            ) and
--                 (or_reduce(idle_count(iLink)(4 downto 2)) = '1') ) then
                 (or_reduce(idle_count(iLink)(4 downto 3)) = '1') ) then          
              link_wr(iLink) <= '0';
              idle_count(iLink) <= idle_count(iLink);
            end if;
          else
            --normal writing of data

            --keep track of the number of idles in a row we've written
            if rx_data_ordered(iLink) = '1'&x"3C" then          
              --Use a shift register to keep track of how many idles we've had
              idle_count(iLink) <= idle_count(iLink)(3 downto 0)&'1';
            end if;
          end if;
        end if;
      end if;
    end process RL_input;

    --Monitor SOF words
    SOF_pulse_proc: process (core_clk(iLink-1)) is
    begin  -- process SOF_pulse
      if core_clk(iLink-1)'event and core_clk(iLink-1) = '1' then  -- rising clock edge
        SOF_pulse(iLink) <= '0';
        if rx_raw_data(iLink) = '1'&x"BC" then
          SOF_pulse(iLink) <= '1';
        end if;
      end if;
    end process SOF_pulse_proc;    
    timed_counter_1: entity work.timed_counter
      generic map (
        timer_count => x"07A12000")
      port map (
        clk          => core_clk(iLink-1),
        reset_async  => '0',
        reset_sync   => '0',
        enable       => '1',
        event        => SOF_pulse(iLink),
        update_pulse => SOF_rate_update(iLink),
        timed_count  => SOF_Rate(iLink));
    pacd_1: entity work.pacd
      port map (
        iPulseA => SOF_rate_update(iLink),
        iClkA   => core_clk(iLink-1),
        iRSTAn  => '1',
        iClkB   => clk_in,
        iRSTBn  => '1',
        oPulseB => SOF_rate_capture(iLink));
    --transfer the value across clock domains after a pulse has moved across
    --the clock domains. 
    SOF_rate_caputre_proc: process (clk_in) is
    begin  -- process SOF_rate_caputre_proc
      if clk_in'event and clk_in = '1' then  -- rising clock edge
        if SOF_rate_capture(iLink) = '1' then
          monitor(((iLink-1)/4)+1).Raw_SOF_Rate(((iLink-1) mod 4)+1) <= SOF_rate(iLink);
        end if;
      end if;
    end process SOF_rate_caputre_proc;
    
    CD_RL_FIFO_1: entity work.CD_RL_FIFO
      port map (
        aclr    => reset_core(iLink),--reset_clk_in_sync,--'0',--control(((iLink-1)/4)+1).reset_link_side(((iLink-1) mod 4)+1),
        data    => rx_raw_data(iLink),
        rdclk   => clk_in,
        rdreq   => link_rd_comb(iLink),
        wrclk   => core_clk(iLink-1),
        wrreq   => link_wr(iLink),
        q       => rx_data_buffer(iLink),
        rdempty => link_empty(iLink),
        rdusedw => link_buffer_used_rd(iLink),
        wrfull  => link_buffer_full(iLink),
        wrusedw => link_buffer_used_wr(iLink));

    link_rd_comb(iLink) <= link_rd(iLink) and (not link_empty(iLink));
    
    RL_common_domain: process (clk_in,reset_clk_in_sync) is
    begin  -- process RL_common_domain
      if reset_clk_in_sync = '1' then
        link_rd(iLink) <= '0';
        rx_valid_buffer(iLink) <= '0';
        rx_valid(iLink) <= '0';       
      elsif clk_in'event and clk_in = '1' then  -- rising clock edge
--        link_rd(iLink) <= or_reduce(link_buffer_used_rd(iLink)(4 downto 0)) and (not link_empty(iLink));
        link_rd(iLink) <= or_reduce(link_buffer_used_rd(iLink)(5 downto 3)) and (not link_empty(iLink));

--        --stupid
--        if (or_reduce(link_buffer_used_rd(iLink)(4 downto 0)) = '0') and (link_empty(iLink) = '0') then
--          link_rd(iLink) <= '1';
--        end if;

        
        rx_valid_buffer(iLink) <= link_rd(iLink) and (not link_empty(iLink));

        --output buffered outputs
        rx_valid(iLink) <= rx_valid_buffer(iLink);
        rx_data(iLink)  <= rx_data_buffer(iLink);

        --monitoring
        monitor(((iLink-1)/4)+1).rdusedw(((iLink-1) mod 4)+1) <= link_buffer_used_rd(iLink);
        
      end if;
    end process RL_common_domain;
    
  end generate link_CDC;
  
  
    
  

end architecture behavioral;


