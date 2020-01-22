----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the FEMB daq links
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.WIB_Constants.all;
use work.COLDATA_IO.all;
use work.types.all;

package FEMB_DAQ_IO is

  -------------------------------------------------------------------------------
  -- DQM
  -------------------------------------------------------------------------------    
  type FEMB_DQM_t is record
    COLDATA_stream : data_8b10b_t(LINK_COUNT downto 1);
  end record FEMB_DQM_t;

  -------------------------------------------------------------------------------
  -- Monitoring
  -------------------------------------------------------------------------------    
  type CD_Spy_Monitor_t is record
    ext_en     : std_logic;
    word_en    : std_logic;
    word_trig  : std_logic_vector(8 downto 0);
    state      : std_logic_vector(1 downto 0);
    stream_id  : integer;
    fifo_empty : std_logic;
    fifo_data  : std_logic_vector(8 downto 0);      
  end record CD_Spy_Monitor_t;
  
  ---------------------------------------
  -- COLDATA ASIC Stream monitor
  type CD_Stream_Monitor_t is record
    enable                               : std_logic;
    convert_delay                  : integer range 0 to 255;
    wait_window                    : std_logic_vector(7 downto 0);
    counter_BUFFER_FULL            : std_logic_vector(31 downto 0);
    counter_CONVERT_IN_WAIT_WINDOW : std_logic_vector(31 downto 0);
    counter_BAD_SOF                : std_logic_vector(31 downto 0);
    counter_UNEXPECTED_EOF         : std_logic_vector(31 downto 0);
    counter_MISSING_EOF            : std_logic_vector(31 downto 0);
    counter_KCHAR_IN_DATA          : std_logic_vector(31 downto 0);
    counter_BAD_CHSUM              : std_logic_vector(31 downto 0);
    counter_packets                : std_logic_vector(31 downto 0);
    counter_timestamp_incr         : std_logic_vector(31 downto 0);
    counter_BAD_RO_START           : std_logic_vector(31 downto 0);
    counter_BAD_WRITE              : std_logic_vector(31 downto 0);
    timer_incr_error               : std_logic_vector(31 downto 0);
    timer_frames                   : std_logic_vector(31 downto 0);
    data                           : std_logic_vector(8 downto 0);
  end record CD_Stream_Monitor_t;
  type CD_Stream_Monitor_array_t is array (LINKS_PER_FEMB downto 1) of CD_Stream_Monitor_t;

  ---------------------------------------
  -- Fake COLDATA Stream monitor
  type Fake_CD_Monitor_t is record
    counter_packets_A         : std_logic_vector(31 downto 0);
    counter_packets_B         : std_logic_vector(31 downto 0);
    data_A                    : std_logic_vector(8 downto 0);
    data_B                    : std_logic_vector(8 downto 0);

    inject_CD_errors          : std_logic_vector(15 downto 0);
    inject_BAD_checksum       : std_logic_vector(1 downto 0);
    inject_BAD_SOF            : std_logic_vector(1 downto 0);
    inject_LARGE_FRAME        : std_logic_vector(1 downto 0);
    inject_K_CHAR             : std_logic_vector(1 downto 0);
    inject_SHORT_FRAME        : std_logic_vector(1 downto 0);

    set_reserved              : std_logic_vector(15 downto 0);
    set_header                : std_logic_vector(31 downto 0);
    fake_data_type            : std_logic_vector(1 downto 0);
    fake_stream_type          : std_logic_vector(LINKS_PER_CDA downto 1);
  end record Fake_CD_Monitor_t;       
  type Fake_CD_Monitor_array_t is array (CDAS_PER_FEMB downto 1) of Fake_CD_Monitor_t;

  -----------------------------------------------------------
  -- FEMB monitor
  type FEMB_COLDATA_Rx_Monitor_t is record   
    rx_analogreset              : std_logic_vector(LINKS_PER_FEMB downto 1);      
    rx_digitalreset             : std_logic_vector(LINKS_PER_FEMB downto 1);     
    rx_cal_busy                 : std_logic_vector(LINKS_PER_FEMB downto 1);         
    rx_is_lockedtoref           : std_logic_vector(LINKS_PER_FEMB downto 1);  
    rx_is_lockedtodata          : std_logic_vector(LINKS_PER_FEMB downto 1); 
    rx_errdetect                : std_logic_vector(LINKS_PER_FEMB downto 1);       
    rx_disperr                  : std_logic_vector(LINKS_PER_FEMB downto 1);         
    rx_runningdisp              : std_logic_vector(LINKS_PER_FEMB downto 1);
    rx_patterndetect            : std_logic_vector(LINKS_PER_FEMB downto 1);
    rx_syncstatus               : std_logic_vector(LINKS_PER_FEMB downto 1);
    counter_rx_disp_error       : uint32_array_t(LINKS_PER_FEMB downto 1);
    counter_rx_error            : uint32_array_t(LINKS_PER_FEMB downto 1);
    reset_counter_rx_disp_error : std_logic_vector(LINKS_PER_FEMB downto 1);
    reset_counter_rx_error      : std_logic_vector(LINKS_PER_FEMB downto 1);
    raw_sof_rate                : uint32_array_t(LINKS_PER_FEMB downto 1);
    rdusedw                     : uint6_array_t(LINKS_PER_FEMB downto 1);
  end record FEMB_COLDATA_Rx_Monitor_t;
  type FEMB_COLDATA_Rx_Monitor_array_t is array (FEMB_COUNT downto 1) of FEMB_COLDATA_Rx_Monitor_t;
  
  -----------------------------------------------------------
  -- FEMB monitor
  type FEMB_DAQ_Monitor_t is record
    CD_Stream         : CD_Stream_Monitor_array_t;    
    Fake_CD           : Fake_CD_Monitor_array_t;
    LOS               : std_logic_vector(LINKS_PER_FEMB downto 1);
    fake_loopback_en  : std_logic_vector(LINKS_PER_FEMB downto 1);
    Rx                : FEMB_COLDATA_Rx_Monitor_t;
  end record FEMB_DAQ_Monitor_t;
  type FEMB_DAQ_Monitor_array_t is array (FEMB_COUNT downto 1) of FEMB_DAQ_Monitor_t;
  
 
  -------------------------------------------------------------------------------
  -- FEMBs Monitor
  type FEMB_DAQs_Monitor_t is record
    FEMB               : FEMB_DAQ_Monitor_array_t;
    reset              : std_logic;
    reconf_reset       : std_logic;
    spy                : CD_Spy_Monitor_t;
    copyFEMB1and2to3and4 : std_logic;       
  end record FEMB_DAQs_Monitor_t;


  -------------------------------------------------------------------------------
  -- Control
  -------------------------------------------------------------------------------    
  type CD_Spy_Control_t is record
    arm        : std_logic;
    sw_trig    : std_logic;
    ext_en     : std_logic;
    word_en    : std_logic;
    word_trig  : std_logic_vector(8 downto 0);
    stream_id  : integer;
    fifo_read  : std_logic;
  end record CD_Spy_Control_t;
  constant DEFAULT_CD_Spy_Control : CD_Spy_Control_t := (arm       => '0',
                                                         sw_trig   => '0',
                                                         ext_en    => '0',
                                                         word_en   => '0',
                                                         word_trig => "1"&x"BC",
                                                         stream_id => 0,
                                                         fifo_read => '0'
                                                         );
  
  ---------------------------------------
  -- COLDATA ASIC Stream control
  type CD_Stream_Control_t is record
    enable                               : std_logic;
    convert_delay                        : integer range 0 to 255;
    wait_window                          : std_logic_vector(7 downto 0);
    reset_counter_BUFFER_FULL            : std_logic;
    reset_counter_CONVERT_IN_WAIT_WINDOW : std_logic;
    reset_counter_BAD_SOF                : std_logic;
    reset_counter_UNEXPECTED_EOF         : std_logic;
    reset_counter_MISSING_EOF            : std_logic;
    reset_counter_KCHAR_IN_DATA          : std_logic;
    reset_counter_BAD_CHSUM              : std_logic;
    reset_counter_packets                : std_logic;
    reset_counter_timestamp_incr         : std_logic;
    reset_counter_BAD_WRITE              : std_logic;
    reset_counter_BAD_RO_START           : std_logic;  
    reset_timer_frames                   : std_logic;
    reset_timer_incr_error               : std_logic;
  end record CD_Stream_Control_t;
  type CD_Stream_Control_array_t is array (LINKS_PER_FEMB downto 1) of CD_Stream_Control_t;
  constant DEFAULT_CD_Stream_Control : CD_Stream_Control_t := (enable                               => '0',
                                                               convert_delay                        => 0,
                                                               wait_window                          => x"02",
                                                               reset_counter_BUFFER_FULL            => '0',
                                                               reset_counter_CONVERT_IN_WAIT_WINDOW => '0',
                                                               reset_counter_BAD_SOF                => '0',
                                                               reset_counter_UNEXPECTED_EOF         => '0',
                                                               reset_counter_MISSING_EOF            => '0',
                                                               reset_counter_KCHAR_IN_DATA          => '0',
                                                               reset_counter_BAD_CHSUM              => '0',
                                                               reset_counter_packets                => '0',
                                                               reset_counter_timestamp_incr         => '0',
                                                               reset_counter_BAD_WRITE              => '0',
                                                               reset_counter_BAD_RO_START           => '0',
                                                               reset_timer_frames                   => '0',
                                                               reset_timer_incr_error               => '0');
  ---------------------------------------
  -- Fake COLDATA Stream control
  type Fake_CD_Control_t is record
    reset_counter_packets_1_A : std_logic;
    reset_counter_packets_1_B : std_logic;

    inject_errors             : std_logic;
    inject_CD_errors          : std_logic_vector(15 downto 0);
    inject_BAD_checksum       : std_logic_vector(1 downto 0);
    inject_BAD_SOF            : std_logic_vector(1 downto 0);
    inject_LARGE_FRAME        : std_logic_vector(1 downto 0);
    inject_K_CHAR             : std_logic_vector(1 downto 0);
    inject_SHORT_FRAME        : std_logic_vector(1 downto 0);
    
    set_reserved              : std_logic_vector(15 downto 0);
    set_header                : std_logic_vector(31 downto 0);
    fake_data_type            : std_logic_vector(1 downto 0);
    fake_stream_type          : std_logic_vector(LINKS_PER_CDA downto 1);
  end record Fake_CD_Control_t;       
  type Fake_CD_Control_array_t is array (CDAS_PER_FEMB downto 1) of Fake_CD_Control_t;
  constant DEFAULT_Fake_CD_Control : Fake_CD_Control_t := (reset_counter_packets_1_A => '0',
                                                           reset_counter_packets_1_B => '0',
                                                           inject_errors => '0',
                                                           inject_CD_errors => x"0000",
                                                           inject_BAD_checksum => "00",
                                                           inject_BAD_SOF => "00",
                                                           inject_LARGE_FRAME => "00",
                                                           inject_K_CHAR   => "00",   
                                                           inject_SHORT_FRAME => "00",
                                                           set_reserved => x"0000",
                                                           set_header => x"00000000",
                                                           fake_data_type => "01",
                                                           fake_stream_type => "11");
 

  -----------------------------------------------------------
  -- FEMB Control
  type FEMB_COLDATA_Rx_Control_t is record   
    rx_analogreset     : std_logic_vector(LINKS_PER_FEMB downto 1);      
    rx_digitalreset    : std_logic_vector(LINKS_PER_FEMB downto 1);     
    reset_counter_rx_disp_error : std_logic_vector(LINKS_PER_FEMB downto 1);
    reset_counter_rx_error      : std_logic_vector(LINKS_PER_FEMB downto 1);
    reset_link_side             : std_logic_vector(LINKS_PER_FEMB downto 1);
  end record FEMB_COLDATA_Rx_Control_t;
  constant DEFAULT_FEMB_COLDATA_RX_CONTROL : FEMB_COLDATA_Rx_Control_t := (rx_analogreset  => (others => '0'),
                                                                           rx_digitalreset => (others => '0'),
                                                                           reset_counter_rx_disp_error => (others => '0'),
                                                                           reset_counter_rx_error => (others => '0'),
                                                                           reset_link_side => (others => '0'));
  type FEMB_COLDATA_Rx_Control_array_t is array (FEMB_COUNT downto 1) of FEMB_COLDATA_Rx_Control_t;
  
  -----------------------------------------------------------
  -- FEMB control
  type FEMB_DAQ_Control_t is record
    Rx                : FEMB_COLDATA_Rx_Control_t;
    CD_Stream         : CD_Stream_Control_array_t;    
    Fake_CD           : Fake_CD_Control_array_t;
    fake_loopback_en  : std_logic_vector(LINKS_PER_FEMB downto 1);
  end record FEMB_DAQ_Control_t;
  type FEMB_DAQ_Control_array_t is array (FEMB_COUNT downto 1) of FEMB_DAQ_Control_t;
  constant DEFAULT_FEMB_DAQ_Control : FEMB_DAQ_Control_t := (Rx => DEFAULT_FEMB_COLDATA_RX_Control,
                                                             CD_Stream => (others => DEFAULT_CD_Stream_Control),
                                                             Fake_CD   => (others => DEFAULT_Fake_CD_Control),
                                                             fake_loopback_en => (others => '0')
                                                             );


  -------------------------------------------------------------------------------
  -- FEMBs Control
  type FEMB_DAQs_Control_t is record
    FEMB              : FEMB_DAQ_Control_array_t;
    reset             : std_logic;
    reconf_reset      : std_logic;
    spy               : CD_Spy_Control_t;
    copyFEMB1and2to3and4 : std_logic;
  end record FEMB_DAQs_Control_t;    
  constant DEFAULT_FEMB_DAQs_Control : FEMB_DAQs_Control_t := (FEMB => (others => DEFAULT_FEMB_DAQ_Control),
                                                               reset => '0',
                                                               reconf_reset => '0',
                                                               spy => DEFAULT_CD_SPY_CONTROL,
                                                               copyFEMB1and2to3and4 => '0');
  
end FEMB_DAQ_IO;
