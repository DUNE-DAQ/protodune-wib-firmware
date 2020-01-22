library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

use work.WIB_Constants.all;
use work.COLDATA_IO.all;

use work.FEMB_DAQ_IO.all;
use work.Convert_IO.all;
use work.CD_EB_BRIDGE.all;
use work.types.all;

entity FEMB_DAQ is
  port (
    reset       : in std_logic;
    clk_FEMB    : in std_logic;
--    clk_FEMB    : out std_logic;
    reset_FEMB  : in std_logic;

    convert     : in convert_t;

    Rx          : in std_logic_vector((FEMB_COUNT*4) - 1 downto 0);

    Rx_refclk   : in std_logic_vector(1 downto 0);
    Rx_LOS_n    : in std_logic_vector((FEMB_COUNT*4) - 1 downto 0);
    clk_EVB     : in  std_logic;
    reset_EVB   : in std_logic;
    CD_stream   : out CD_stream_array_t(FEMB_COUNT*4 downto 1);
    CD_read     : in  std_logic_vector((FEMB_COUNT*4) downto 1);

    monitor     : out FEMB_DAQs_Monitor_t;
    control     : in  FEMB_DAQs_Control_t;
    DQM         : out FEMB_DQM_t
    );

end entity FEMB_DAQ;

architecture behavioral of FEMB_DAQ is


  -------------------------------------------------------------------------------
  --components
  -------------------------------------------------------------------------------
  component COLDATA_Simulator is
    port (
      clk              : in  std_logic;
      reset_sync       : in  std_logic;
      data_out_stream1 : out std_logic_vector(8 downto 0);
      data_out_stream2 : out std_logic_vector(8 downto 0);
      convert          : in  convert_t;
      monitor          : out FEMB_DAQ_Monitor_t;
      control          : in  FEMB_DAQ_Control_t
      );
  end component COLDATA_Simulator;

  component FEMB_Rx is
    port (
      clk_in    : in  std_logic;
      reset_clk_in_sync  : in  std_logic;
--      clk_out   : out std_logic;
      Rx        : in  std_logic_vector(LINK_COUNT-1 downto 0);
      Rx_refclk : in  std_logic_vector(LINK_GROUPS-1 downto 0);
      rx_data   : out data_8b10b_t(LINK_COUNT downto 1);
      rx_valid  : out std_logic_vector(LINK_COUNT downto 1);
      monitor   : out FEMB_COLDATA_Rx_Monitor_array_t;
      control   : in  FEMB_COLDATA_Rx_Control_array_t);
  end component FEMB_Rx;
  component CD_Stream_Processor is
    port (
      clk_CD         : in  std_logic;
      reset_CD       : in  std_logic;
      COLDATA_stream : in  std_logic_vector(8 downto 0);
      COLDATA_valid  : in std_logic;
      convert        : in  convert_t;
      clk_EVB        : in  std_logic;
      CD_to_EB_stream : out CD_Stream_t;    
      EB_rd           : in  std_logic;
      monitor        : out CD_Stream_Monitor_t;
      control        : in  CD_Stream_Control_t);
  end component CD_Stream_Processor;

  component SpyBuffer is
    generic (
      SAMPLE_WIDTH : integer);
    port (
      clk_wr     : in  std_logic;
      data_in    : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
      arm        : in  std_logic;
      state      : out std_logic_vector(1 downto 0);
      sw_trig    : in  std_logic;
      ext_en     : in  std_logic;
      ext_trig   : in  std_logic;
      word_en    : in  std_logic;
      word_trig  : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
      clk_rd     : in  std_logic;
      fifo_rd    : in  std_logic;
      fifo_empty : out std_logic;
      fifo_data  : out std_logic_vector(SAMPLE_WIDTH-1 downto 0));
  end component SpyBuffer;
  
  -------------------------------------------------------------------------------
  -- signals
  -------------------------------------------------------------------------------
  signal convert_counter : integer range 0 to 63 := 0;


  signal fake_COLDATA : data_8b10b_t(LINK_COUNT downto 1);
  signal fake_COLDATA_valid : std_logic_vector(LINK_COUNT downto 1);
  signal real_COLDATA : data_8b10b_t(LINK_COUNT downto 1);
  signal real_COLDATA_valid : std_logic_vector(LINK_COUNT downto 1);
  signal COLDATA_data : data_8b10b_t(LINK_COUNT downto 1);
  signal COLDATA_valid : std_logic_vector(LINK_COUNT downto 1);
  constant LINK_TYPE : std_logic_vector(LINK_COUNT downto 1) := x"5555";

  
  signal Rx_refclk_map : std_logic_vector(3 downto 0) := (others => '0');

  signal Rx_monitor : FEMB_COLDATA_Rx_Monitor_array_t;
  signal Rx_control : FEMB_COLDATA_Rx_Control_array_t;

  signal spy_stream  : std_logic_vector(8 downto 0);

  signal clk : std_logic := '0';
  
begin  -- architecture behavioral

  -------------------------------------------------------------------------------
  -- Capture data from FEMBs
  -------------------------------------------------------------------------------
    
  Rx_refclk_map(0) <= Rx_refclk(0);
  Rx_refclk_map(1) <= Rx_refclk(1);
  Rx_refclk_map(2) <= Rx_refclk(1);
  Rx_refclk_map(3) <= Rx_refclk(1);
  Rx_array_gen: for iFEMB in FEMB_COUNT downto 1 generate
    monitor.FEMB(iFEMB).Rx <= Rx_monitor(iFEMB);
    Rx_control(iFEMB) <= control.FEMB(iFEMB).Rx;    
  end generate Rx_array_gen;

--  clk_FEMB <= clk;
  FEMB_Rx_1 : entity work.FEMB_Rx
    port map (
      clk_in    => clk_FEMB,
      reset_clk_in_sync  => reset_FEMB,
--      clk_out   => clk,
      Rx        => Rx,
      Rx_refclk => Rx_refclk_map,
      rx_data   => real_COLDATA,
      rx_valid  => real_COLDATA_valid,
      monitor   => Rx_monitor,
      control   => Rx_control
      );

  -------------------------------------------------------------------------------
  -- Generate Fake COLDATA streams for testing
  -------------------------------------------------------------------------------

  FAKE_FEMBs : for iFEMB in FEMB_COUNT downto 1 generate
    FAKE_CDAs : for iCDA in CDAS_PER_FEMB downto 1 generate
      fake_COLDATA_generator : entity work.COLDATA_Simulator
        port map (
          clk              => clk_FEMB,--clk,--clk_FEMB,
          reset_sync       => reset_FEMB,
          data_out_stream1 => fake_COLDATA(((iFEMB-1) * CDAS_PER_FEMB + (iCDA-1))*LINKS_PER_CDA +1),
          data_out_stream2 => fake_COLDATA(((iFEMB-1) * CDAS_PER_FEMB + (iCDA-1))*LINKS_PER_CDA +2),
          convert          => convert,
          monitor          => monitor.FEMB(iFEMB).Fake_CD(iCDA),
          control          => control.FEMB(iFEMB).Fake_CD(iCDA));
      fake_COLDATA_valid(((iFEMB-1) * CDAS_PER_FEMB + (iCDA-1))*LINKS_PER_CDA +1) <= '1';
      fake_COLDATA_valid(((iFEMB-1) * CDAS_PER_FEMB + (iCDA-1))*LINKS_PER_CDA +2) <= '1';
    end generate FAKE_CDAs;
  end generate FAKE_FEMBs;

  -------------------------------------------------------------------------------
  -- Build COLDATA stream frames for readout
  -------------------------------------------------------------------------------
--  DQM.COLDATA_stream <= COLDATA_data;
  DQM_buffer: process (clk_FEMB) is --(clk) is --(clk_FEMB) is
  begin  -- process DQM_buffer
    if clk_FEMB'event and clk_FEMB = '1' then  -- rising clock edge
--    if clk'event and clk = '1' then  -- rising clock edge      
      DQM.COLDATA_stream <= COLDATA_data;
--      DQM.COLDATA_valid  <= COLDATA_valid;
    end if;
  end process DQM_buffer;
  monitor.copyFEMB1and2to3and4 <= control.copyFEMB1and2to3and4;
  data_sources : process (control.FEMB(1).fake_loopback_en,
                          control.FEMB(2).fake_loopback_en,
                          control.FEMB(3).fake_loopback_en,
                          control.FEMB(4).fake_loopback_en) is
  begin  -- process data_sources
    for iFEMB in FEMB_COUNT downto 1 loop
      monitor.FEMB(iFEMB).fake_loopback_en <= control.FEMB(iFEMB).fake_loopback_en;      
      for iLink in LINKS_PER_FEMB downto 1 loop
        -- Rx data source
        if control.FEMB(iFEMB).fake_loopback_en(iLink) = '0' then          
          --process Real Rx data from the transciever
          COLDATA_data((iFEMB-1)*LINKS_PER_FEMB + iLink) <= real_COLDATA((iFEMB-1)*LINKS_PER_FEMB + iLink);
          COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iLink) <= real_COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iLink);
          if control.copyFEMB1and2to3and4 = '1' then
            if iFEMB = 3 or iFEMB = 4 then
              COLDATA_data((iFEMB-1)*LINKS_PER_FEMB + iLink) <= real_COLDATA((iFEMB-1-2)*LINKS_PER_FEMB + iLink);
              COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iLink) <= real_COLDATA_valid((iFEMB-1-2)*LINKS_PER_FEMB + iLink);

            end if;
          end if;
        else
          --process local fake data.
          COLDATA_data((iFEMB-1)*LINKS_PER_FEMB + iLink) <= fake_COLDATA((iFEMB-1)*LINKS_PER_FEMB + iLink);
          COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iLink) <= fake_COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iLink);
        end if;
      end loop;  -- iLink
    end loop;  -- iFEMB
  end process data_sources;

  FEMB_Processors : for iFEMB in FEMB_COUNT downto 1 generate
    FEMB_Stream_Processors : for iStream in LINKS_PER_FEMB downto 1 generate
      CD_Stream_Processor_1 : entity work.CD_Stream_Processor
        generic map (
          IS_LINK_A => LINK_TYPE((iFEMB-1)*LINKS_PER_FEMB + iStream))
        port map (
          clk_CD         => clk_FEMB,--clk,--clk_FEMB,
          reset_CD       => reset_FEMB,
          COLDATA_stream => COLDATA_data((iFEMB-1)*LINKS_PER_FEMB + iStream),
          COLDATA_valid  => COLDATA_valid((iFEMB-1)*LINKS_PER_FEMB + iStream),
          convert        => convert,
          clk_EVB        => clk_EVB,
          CD_to_EB_stream => CD_Stream((iFEMB-1)*LINKS_PER_FEMB + iStream), 
          EB_rd          => CD_read((iFEMB-1)*LINKS_PER_FEMB + iStream),
          monitor        => monitor.FEMB(iFEMB).CD_Stream(iStream),
          control        => control.FEMB(iFEMB).CD_Stream(iStream));
    end generate FEMB_Stream_Processors;
  end generate FEMB_Processors;


  -------------------------------------------------------------------------------
  --spy buffer
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  spy_buffer_delay: process (clk_FEMB) is
--  spy_buffer_delay: process (clk) is
  begin  -- process spy_buffer_delay
    if clk_FEMB'event and clk_FEMB = '1' then  -- rising clock edge
--    if clk'event and clk = '1' then  -- rising clock edge
      --Adding a latch of delay for easier timing
      spy_stream <= COLDATA_data(control.spy.stream_id + 1);      
    end if;
  end process spy_buffer_delay;


  monitor.spy.stream_id <= control.spy.stream_id;  
  monitor.spy.ext_en    <= control.spy.ext_en;   
  monitor.spy.word_en   <= control.spy.word_en;  
  monitor.spy.word_trig <= control.spy.word_trig;

  SpyBuffer_1: SpyBuffer
    generic map (
      SAMPLE_WIDTH => 9)
    port map (
      clk_wr     => clk_FEMB,--clk,--clk_FEMB,
      data_in    => spy_stream,
      arm        => control.spy.arm,
      state      => monitor.spy.state,
      sw_trig    => control.spy.sw_trig,
      ext_en     => control.spy.ext_en,
      ext_trig   => convert.trigger,
      word_en    => control.spy.word_en,
      word_trig  => control.spy.word_trig,
      clk_rd     => clk_FEMB,--clk,--clk_FEMB,
      fifo_rd    => control.spy.fifo_read,
      fifo_empty => monitor.spy.fifo_empty,
      fifo_data  => monitor.spy.fifo_data);

end architecture behavioral;
