----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for monitor and control of COLDATA clock and command 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package FEMB_CnC_IO is

  type FEMB_CNC_Monitor_t is record
    error_convert_timing_counter : std_logic_vector(31 downto 0);
    convert_counter              : std_logic_vector(31 downto 0);
    calibrate_counter            : std_logic_vector(31 downto 0);
    sync_counter                 : std_logic_vector(31 downto 0);
    reset_counter                : std_logic_vector(31 downto 0);    
    cmd_sel                      : std_logic;
    clk_sel                      : std_logic;
    enable_converts_to_FEMB      : std_logic;
    sending_converts_to_FEMB     : std_logic;
    DTS_reset                    : std_logic;
    DTS_locked                   : std_logic;
    DTS_cmd_enable               : std_logic;
    DTS_TP_enable                : std_logic;
  end record FEMB_CNC_Monitor_t;

  type FEMB_CNC_Control_t is record
    error_convert_timing_counter_reset : std_logic;
    convert_counter_reset              : std_logic;
    calibrate_counter_reset            : std_logic;
    sync_counter_reset                 : std_logic;
    reset_counter_reset                : std_logic;
    cmd_sel                            : std_logic;
    clk_sel                            : std_logic;
    enable_converts_to_FEMB            : std_logic;
    DTS_reset                          : std_logic;
    stop_data                          : std_logic;
    start_data                         : std_logic;
    timestamp_reset                    : std_logic;
    calibration                        : std_logic;
    DTS_cmd_enable                     : std_logic;
    DTS_TP_enable                      : std_logic;

  end record FEMB_CNC_Control_t;
  constant DEFAULT_FEMB_CnC_Control : FEMB_CNC_Control_t := (error_convert_timing_counter_reset => '0',
                                                             convert_counter_reset              => '0', 
                                                             calibrate_counter_reset            => '0', 
                                                             sync_counter_reset                 => '0',         
                                                             reset_counter_reset                => '0',               
                                                             cmd_sel                            => '0',
                                                             clk_sel                            => '0',
                                                             enable_converts_to_FEMB            => '0',
                                                             DTS_reset                          => '0',
                                                             stop_data                          => '0',
                                                             start_data                         => '0',
                                                             timestamp_reset                    => '0',
                                                             calibration                        => '0',
                                                             DTS_cmd_enable                     => '0',
                                                             DTS_TP_enable                      => '0'
                                                             );    
end package FEMB_CnC_IO;
