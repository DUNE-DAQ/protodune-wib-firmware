library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.types.all;


entity RCE_PCS is
  generic (
    TX_COUNT : integer := 4;
    WORD_WIDTH : integer := 8);
  port (
    sys_clk         : in  std_logic;
    sys_reset       : in  std_logic;
    reset           : in  std_logic;
    pll_powerdown   : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_analogreset  : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_digitalreset : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0);
    pll_locked      : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx_cal_busy     : out std_logic_vector(TX_COUNT - 1 downto 0);  
    tx_refclk       : in  std_logic;
    tx              : out std_logic_vector(TX_COUNT - 1 downto 0);
    clk_data        : out std_logic;
    data_wr         : in  std_logic_vector(TX_COUNT - 1 downto 0);
    k_data          : in  std_logic_vector(TX_COUNT*WORD_WIDTH     - 1 downto 0);
    data            : in  std_logic_vector(TX_COUNT*WORD_WIDTH * 8 - 1 downto 0));
end entity RCE_PCS;  

architecture behavioral of RCE_PCS is

  component pipeline_delay is
    generic (
      WIDTH : integer;
      DELAY : integer);
    port (
      clk      : in  std_logic;
      data_in  : in  std_logic_vector(WIDTH-1 downto 0);
      data_out : out std_logic_vector(WIDTH-1 downto 0));
  end component pipeline_delay;
  
  COMPONENT encoder_8b10b
    GENERIC ( METHOD : INTEGER := 1 );
    PORT
      (
        clk		:	 IN STD_LOGIC;
        rst		:	 IN STD_LOGIC;
        kin_ena		:	 IN STD_LOGIC;
        ein_ena		:	 IN STD_LOGIC;
        ein_dat		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        ein_rd		:	 IN STD_LOGIC;
        eout_val		:	 OUT STD_LOGIC;
        eout_dat		:	 OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        eout_rdcomb		:	 OUT STD_LOGIC;
        eout_rdreg		:	 OUT STD_LOGIC
	);
  END COMPONENT;

  component LINK_FIFO is
    port (
      data    : IN  STD_LOGIC_VECTOR (79 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (79 DOWNTO 0);
      rdempty : OUT STD_LOGIC);
  end component LINK_FIFO;
  
  component RCE_LINK is
    port (
      pll_powerdown        : in  std_logic_vector(3 downto 0)   := (others => '0');     
      tx_analogreset       : in  std_logic_vector(3 downto 0)   := (others => '0');
      tx_digitalreset      : in  std_logic_vector(3 downto 0)   := (others => '0');
      tx_pll_refclk        : in  std_logic_vector(0 downto 0)   := (others => '0');
      tx_pma_clkout        : out std_logic_vector(3 downto 0);
      tx_serial_data       : out std_logic_vector(3 downto 0);
      tx_pma_parallel_data : in  std_logic_vector(319 downto 0) := (others => '0');
      pll_locked           : out std_logic_vector(3 downto 0);
      tx_cal_busy          : out std_logic_vector(3 downto 0);
      reconfig_to_xcvr     : in  std_logic_vector(559 downto 0) := (others => '0');
      reconfig_from_xcvr   : out std_logic_vector(367 downto 0));
  end component RCE_LINK;

  component trans_reseter is
    generic (
      TX_COUNT : integer);
    port (
      sys_clk         : in  std_logic;
      sys_reset       : in  std_logic;
      pll_powerdown   : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_analogreset  : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_digitalreset : in  std_logic_vector(TX_COUNT - 1 downto 0);
      pll_locked      : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_cal_busy     : in  std_logic_vector(TX_COUNT - 1 downto 0);
      tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0));
  end component trans_reseter;

  signal clk_pcs : std_logic_vector(3 downto 0);


  --reset controller
  signal local_pll_powerdown   : std_logic_vector(TX_COUNT - 1 downto 0);
  signal local_tx_analogreset  : std_logic_vector(TX_COUNT - 1 downto 0);
  signal local_tx_digitalreset : std_logic_vector(TX_COUNT - 1 downto 0);
  signal local_tx_ready        : std_logic_vector(TX_COUNT - 1 downto 0);
  signal local_pll_locked      : std_logic_vector(TX_COUNT - 1 downto 0);
  signal local_tx_cal_busy     : std_logic_vector(TX_COUNT - 1 downto 0);  

  signal rdisp_in       : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal valid_10b      : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal rdisp_out_comb : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal rdisp_out_reg  : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  type link_10b_array_t is array (TX_COUNT -1 downto 0) of uint10_array_t(WORD_WIDTH - 1 downto 0);
  signal data_10b : link_10b_array_t := (others => (others => (others => '0')));  
  signal pma_parallel_data : std_logic_vector(TX_COUNT*WORD_WIDTH*10 -1 downto 0) := (others => '0');
  signal pma_parallel_data_pre_buffer : std_logic_vector(TX_COUNT*WORD_WIDTH*10 -1 downto 0) := (others => '0');
  signal pma_parallel_data_post_buffer : std_logic_vector(TX_COUNT*WORD_WIDTH*10 -1 downto 0) := (others => '0');

  signal fifo_rd_empty : std_logic_vector(TX_COUNT-1 downto 0);

  type int_array_t is array (TX_COUNT-1 downto 0) of integer;
  constant pre_delays : int_array_t := (0,0,0,0); -- downto
  constant post_delays : int_array_t := (0,0,0,0);

  signal reset_link : std_logic;
  signal reset_link_sr : std_logic_vector(2 downto 0);

  
  
begin  -- architecture behavioral
  clk_data <= clk_pcs(0);

  LINK_loop: for iLink in TX_COUNT - 1 downto 0 generate
    --Build the 8b to 10b parallel encoders for this channel
    encoder_chain: for iEnc in WORD_WIDTH - 1 downto 0 generate
      -- assumes LSB out first on PMA
      
      --Registered disparity from the last clock
      rdisp_in(iLink)(0) <= rdisp_out_reg(iLink)(WORD_WIDTH - 1);
      --Un-registered disparity from the 8b10b encoder previous in line
      rdisp_in(iLink)(WORD_WIDTH - 1 downto 1) <= rdisp_out_comb(iLink)(WORD_WIDTH - 2 downto 0);
      encoder_8b10b_ch0: encoder_8b10b
        generic map (
          METHOD => 1)
        port map (
          clk         => clk_pcs(0),
          rst         => reset,
          kin_ena     => k_data((iLink*WORD_WIDTH)+iEnc),
          ein_ena     => data_wr(iLink),
          ein_dat     => data( (iLink*WORD_WIDTH + iEnc+1)*8 -1 downto  (iLink*WORD_WIDTH + iEnc)*8),
          ein_rd      => rdisp_in(iLink)(iEnc),
          eout_val    => valid_10b(iLink)(iEnc),
          eout_dat    => data_10b(iLink)(iEnc),
          eout_rdcomb => rdisp_out_comb(iLink)(iEnc),
          eout_rdreg  => rdisp_out_reg(iLink)(iEnc));
   
    end generate encoder_chain;

    pipeline_delay_1: entity work.pipeline_delay
      generic map (
        WIDTH => 80,
        DELAY => pre_delays(iLink))
      port map (
        clk      => clk_pcs(0),
        data_in( 9 downto  0)    => data_10b(iLink)(0),
        data_in(19 downto 10)    => data_10b(iLink)(1),
        data_in(29 downto 20)    => data_10b(iLink)(2),
        data_in(39 downto 30)    => data_10b(iLink)(3),
        data_in(49 downto 40)    => data_10b(iLink)(4),
        data_in(59 downto 50)    => data_10b(iLink)(5),
        data_in(69 downto 60)    => data_10b(iLink)(6),
        data_in(79 downto 70)    => data_10b(iLink)(7),
        data_out => pma_parallel_data_pre_buffer(((iLink+1)*80)-1 downto iLink*80));
    
    LINK_FIFO_1: entity work.LINK_FIFO
      port map (
        data    => pma_parallel_data_pre_buffer(((iLink+1)*80) -1 downto 80*iLink),
        rdclk   => clk_pcs(iLink),
        rdreq   => not fifo_rd_empty(iLink),
        wrclk   => clk_pcs(0),
        wrreq   => '1',
        q       => pma_parallel_data_post_buffer(((iLink+1)*80)-1 downto iLink*80),
        rdempty => fifo_rd_empty(iLink));

    pipeline_delay_2: entity work.pipeline_delay
      generic map (
        WIDTH => 80,
        DELAY => post_delays(iLink))
      port map (
        clk      => clk_pcs(iLink),
        data_in  => pma_parallel_data_post_buffer(((iLink+1)*80)-1 downto iLink*80),
        data_out => pma_parallel_data(((iLink+1)*80)-1 downto iLink*80));
  end generate LINK_loop;


  pll_powerdown   <= local_pll_powerdown;
  tx_analogreset  <= local_tx_analogreset;
  tx_digitalreset <= local_tx_digitalreset;
  tx_ready        <= local_tx_ready;
  pll_locked      <= local_pll_locked;
  tx_cal_busy     <= local_tx_cal_busy;  

  reset_extend: process (sys_clk) is
  begin  -- process reset_extend
    if sys_clk'event and sys_clk = '1' then  -- rising clock edge
      reset_link <= or_reduce(reset_link_sr);
      reset_link_sr <= reset_link_sr(reset_link_sr'left downto 1) & sys_reset;
    end if;
  end process reset_extend;

  trans_reseter_1: entity work.trans_reseter
    generic map (
      TX_COUNT => TX_COUNT)
    port map (
      sys_clk         => sys_clk,
      sys_reset       => sys_reset,
      pll_powerdown   => local_pll_powerdown,
      tx_analogreset  => local_tx_analogreset,
      tx_digitalreset => local_tx_digitalreset,
      pll_locked      => local_pll_locked,
      tx_cal_busy     => local_tx_cal_busy,
      tx_ready        => local_tx_ready);

--  RCE_link_Reset_1: RCE_link_Reset
--    port map (
--      clock           => sys_clk,
--      reset           => reset_link,
--      pll_powerdown   => local_pll_powerdown,
--      tx_analogreset  => local_tx_analogreset,
--      tx_digitalreset => local_tx_digitalreset,
--      tx_ready        => local_tx_ready,
--      pll_locked      => local_pll_locked,
--      pll_select      => "00",
--      tx_cal_busy     => local_tx_cal_busy);

--  tx_reseter: process (sys_clk, reset_link) is
--  begin  -- process tx_reseter
--    if reset_link = '1' then            -- asynchronous reset (active high)
--      local_tx_ready <= x"0";
--      reset_state  <= 0;
--    elsif sys_clk'event and sys_clk = '1' then  -- rising clock edge
--      case reset_state is
--        when 0 => 
--          local_pll_powerdown     <= x"f";
--          local_tx_analogreset    <= x"f";
--          local_tx_digitalreset   <= x"f";
--          local_tx_ready          <= x"0";
--          reset_state             <= 1;
--          reset_counter           <= x"064";
--        when 1 =>                 
--          local_pll_powerdown     <= x"f";
--          local_tx_analogreset    <= x"f";
--          local_tx_digitalreset   <= x"f";
--          local_tx_ready          <= x"0";
--          
--          if reset_counter = x"000" then
--            reset_state           <= 2;
--            reset_counter         <= x"1f4";
--            local_pll_powerdown   <= x"0";
--            local_tx_analogreset  <= x"0";            
--          else
--            reset_counter <= reset_counter - 1;
--          end if;
--        when 2 =>
--          local_pll_powerdown     <= x"0";
--          local_tx_analogreset    <= x"0";
--          local_tx_digitalreset   <= x"f";
--          local_tx_ready          <= x"0";
--
--          if reset_counter = 0 then
--            reset_state           <= 3;
--            reset_counter         <= x"064";
--          elsif and_reduce(local_pll_locked) = '1' then
--            reset_counter <= reset_counter - 1;
--          else
--            reset_counter         <= x"1f4";
--          end if;
--        when 3 =>
--          local_pll_powerdown     <= x"0";
--          local_tx_analogreset    <= x"0";
--          local_tx_digitalreset   <= x"f";
--          local_tx_ready          <= x"0";
--          if reset_counter = 0 then
--            local_tx_digitalreset <= x"0";
--            reset_state           <= 4;
--            reset_counter         <= x"064";
--          else
--            reset_counter <= reset_counter -1;
--          end if;
--        when 4 =>
--          local_pll_powerdown     <= x"0";
--          local_tx_analogreset    <= x"0";
--          local_tx_digitalreset   <= x"0";
--          local_tx_ready          <= x"0";
--          if and_reduce(local_pll_locked) = '0' then
--            reset_state           <= 0;
--          elsif reset_counter = 0 then
--            reset_state           <= 5;
--          else
--            reset_counter <= reset_counter - 1;
--          end if;
--        when 5 =>
--          local_pll_powerdown     <= x"0";
--          local_tx_analogreset    <= x"0";
--          local_tx_digitalreset   <= x"0";
--          local_tx_ready          <= x"f";
--          if and_reduce(local_pll_locked) = '0' then
--            reset_state <= 0;
--          end if;
--        when others =>
--          reset_state <= 0;
--      end case;
--    end if;
--  end process tx_reseter;
  
  RCE_LINK_1: RCE_LINK
    port map (
      pll_powerdown        => local_pll_powerdown,
      tx_analogreset       => local_tx_analogreset,
      tx_digitalreset      => local_tx_digitalreset,
      tx_pll_refclk(0)     => tx_refclk,
      tx_pma_clkout        => clk_pcs,
      tx_serial_data       => tx,
      tx_pma_parallel_data => pma_parallel_data,
      pll_locked           => local_pll_locked,
      tx_cal_busy          => local_tx_cal_busy,
      reconfig_to_xcvr     => (others => 'X'),
      reconfig_from_xcvr   => open);
  
end architecture behavioral;
