-- megafunction wizard: %ALTIOBUF%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altiobuf_bidir 

-- ============================================================
-- File Name: DIF_IO_BIR.vhd
-- Megafunction Name(s):
-- 			altiobuf_bidir
--
-- Simulation Library Files(s):
-- 			arriav
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 16.0.0 Build 211 04/27/2016 SJ Standard Edition
-- ************************************************************


--Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, the Altera Quartus Prime License Agreement,
--the Altera MegaCore Function License Agreement, or other 
--applicable license agreement, including, without limitation, 
--that your use is for the sole purpose of programming logic 
--devices manufactured by Altera and sold by Altera or its 
--authorized distributors.  Please refer to the applicable 
--agreement for further details.


--altiobuf_bidir CBX_AUTO_BLACKBOX="ALL" DEVICE_FAMILY="Arria V" ENABLE_BUS_HOLD="FALSE" NUMBER_OF_CHANNELS=1 OPEN_DRAIN_OUTPUT="FALSE" USE_DIFFERENTIAL_MODE="TRUE" USE_DYNAMIC_TERMINATION_CONTROL="FALSE" USE_TERMINATION_CONTROL="FALSE" datain dataio dataio_b dataout oe oe_b
--VERSION_BEGIN 16.0 cbx_altiobuf_bidir 2016:04:27:18:05:34:SJ cbx_mgl 2016:04:27:18:06:48:SJ cbx_stratixiii 2016:04:27:18:05:34:SJ cbx_stratixv 2016:04:27:18:05:34:SJ  VERSION_END

 LIBRARY arriav;
 USE arriav.all;

--synthesis_resources = arriav_io_ibuf 1 arriav_io_obuf 2 arriav_pseudo_diff_out 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  DIF_IO_BIR_iobuf_bidir_knp IS 
	 PORT 
	 ( 
		 datain	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 dataio	:	INOUT  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 dataio_b	:	INOUT  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 dataout	:	OUT  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 oe	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0);
		 oe_b	:	IN  STD_LOGIC_VECTOR (0 DOWNTO 0) := (OTHERS => '1')
	 ); 
 END DIF_IO_BIR_iobuf_bidir_knp;

 ARCHITECTURE RTL OF DIF_IO_BIR_iobuf_bidir_knp IS

	 SIGNAL  wire_ibufa_o	:	STD_LOGIC;
	 SIGNAL  wire_obuf_ba_o	:	STD_LOGIC;
	 SIGNAL  wire_obuf_ba_oe	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_pseudo_diffa_w_lg_oebout3w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_obufa_o	:	STD_LOGIC;
	 SIGNAL  wire_obufa_oe	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_pseudo_diffa_w_lg_oeout2w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_pseudo_diffa_o	:	STD_LOGIC;
	 SIGNAL  wire_pseudo_diffa_obar	:	STD_LOGIC;
	 SIGNAL  wire_pseudo_diffa_oebout	:	STD_LOGIC;
	 SIGNAL  wire_pseudo_diffa_oein	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_oe1w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_pseudo_diffa_oeout	:	STD_LOGIC;
	 COMPONENT  arriav_io_ibuf
	 GENERIC 
	 (
		bus_hold	:	STRING := "false";
		differential_mode	:	STRING := "false";
		simulate_z_as	:	STRING := "z";
		lpm_type	:	STRING := "arriav_io_ibuf"
	 );
	 PORT
	 ( 
		dynamicterminationcontrol	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		ibar	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC
	 ); 
	 END COMPONENT;
	 COMPONENT  arriav_io_obuf
	 GENERIC 
	 (
		bus_hold	:	STRING := "false";
		open_drain_output	:	STRING := "false";
		shift_series_termination_control	:	STRING := "false";
		lpm_type	:	STRING := "arriav_io_obuf"
	 );
	 PORT
	 ( 
		dynamicterminationcontrol	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC;
		obar	:	OUT STD_LOGIC;
		oe	:	IN STD_LOGIC := '1';
		parallelterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
		seriesterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0')
	 ); 
	 END COMPONENT;
	 COMPONENT  arriav_pseudo_diff_out
	 PORT
	 ( 
		dtc	:	OUT STD_LOGIC;
		dtcbar	:	OUT STD_LOGIC;
		dtcin	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC;
		obar	:	OUT STD_LOGIC;
		oebout	:	OUT STD_LOGIC;
		oein	:	IN STD_LOGIC := '0';
		oeout	:	OUT STD_LOGIC
	 ); 
	 END COMPONENT;
 BEGIN

	dataio(0) <= wire_obufa_o;
	dataio_b(0) <= wire_obuf_ba_o;
	dataout(0) <= wire_ibufa_o;
	ibufa :  arriav_io_ibuf
	  GENERIC MAP (
		bus_hold => "false",
		differential_mode => "true"
	  )
	  PORT MAP ( 
		i => dataio(0),
		ibar => dataio_b(0),
		o => wire_ibufa_o
	  );
	wire_obuf_ba_oe <= wire_pseudo_diffa_w_lg_oebout3w;
	wire_pseudo_diffa_w_lg_oebout3w(0) <= NOT wire_pseudo_diffa_oebout;
	obuf_ba :  arriav_io_obuf
	  GENERIC MAP (
		bus_hold => "false",
		open_drain_output => "false"
	  )
	  PORT MAP ( 
		i => wire_pseudo_diffa_obar,
		o => wire_obuf_ba_o,
		oe => wire_obuf_ba_oe(0)
	  );
	wire_obufa_oe <= wire_pseudo_diffa_w_lg_oeout2w;
	wire_pseudo_diffa_w_lg_oeout2w(0) <= NOT wire_pseudo_diffa_oeout;
	obufa :  arriav_io_obuf
	  GENERIC MAP (
		bus_hold => "false",
		open_drain_output => "false"
	  )
	  PORT MAP ( 
		i => wire_pseudo_diffa_o,
		o => wire_obufa_o,
		oe => wire_obufa_oe(0)
	  );
	wire_pseudo_diffa_oein <= wire_w_lg_oe1w;
	wire_w_lg_oe1w(0) <= NOT oe(0);
	pseudo_diffa :  arriav_pseudo_diff_out
	  PORT MAP ( 
		i => datain(0),
		o => wire_pseudo_diffa_o,
		obar => wire_pseudo_diffa_obar,
		oebout => wire_pseudo_diffa_oebout,
		oein => wire_pseudo_diffa_oein(0),
		oeout => wire_pseudo_diffa_oeout
	  );

 END RTL; --DIF_IO_BIR_iobuf_bidir_knp
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY DIF_IO_BIR IS
	PORT
	(
		datain		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		oe		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		oe_b		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		dataio		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		dataio_b		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		dataout		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
END DIF_IO_BIR;


ARCHITECTURE RTL OF dif_io_bir IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (0 DOWNTO 0);



	COMPONENT DIF_IO_BIR_iobuf_bidir_knp
	PORT (
			datain	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			oe	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			oe_b	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			dataout	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			dataio	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			dataio_b	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	dataout    <= sub_wire0(0 DOWNTO 0);

	DIF_IO_BIR_iobuf_bidir_knp_component : DIF_IO_BIR_iobuf_bidir_knp
	PORT MAP (
		datain => datain,
		oe => oe,
		oe_b => oe_b,
		dataout => sub_wire0,
		dataio => dataio,
		dataio_b => dataio_b
	);



END RTL;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Arria V"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Arria V"
-- Retrieval info: CONSTANT: enable_bus_hold STRING "FALSE"
-- Retrieval info: CONSTANT: left_shift_series_termination_control STRING "FALSE"
-- Retrieval info: CONSTANT: number_of_channels NUMERIC "1"
-- Retrieval info: CONSTANT: open_drain_output STRING "FALSE"
-- Retrieval info: CONSTANT: use_differential_mode STRING "TRUE"
-- Retrieval info: CONSTANT: use_dynamic_termination_control STRING "FALSE"
-- Retrieval info: CONSTANT: use_termination_control STRING "FALSE"
-- Retrieval info: USED_PORT: datain 0 0 1 0 INPUT NODEFVAL "datain[0..0]"
-- Retrieval info: USED_PORT: dataio 0 0 1 0 BIDIR NODEFVAL "dataio[0..0]"
-- Retrieval info: USED_PORT: dataio_b 0 0 1 0 BIDIR NODEFVAL "dataio_b[0..0]"
-- Retrieval info: USED_PORT: dataout 0 0 1 0 OUTPUT NODEFVAL "dataout[0..0]"
-- Retrieval info: USED_PORT: oe 0 0 1 0 INPUT NODEFVAL "oe[0..0]"
-- Retrieval info: USED_PORT: oe_b 0 0 1 0 INPUT NODEFVAL "oe_b[0..0]"
-- Retrieval info: CONNECT: @datain 0 0 1 0 datain 0 0 1 0
-- Retrieval info: CONNECT: @oe 0 0 1 0 oe 0 0 1 0
-- Retrieval info: CONNECT: @oe_b 0 0 1 0 oe_b 0 0 1 0
-- Retrieval info: CONNECT: dataio 0 0 1 0 @dataio 0 0 1 0
-- Retrieval info: CONNECT: dataio_b 0 0 1 0 @dataio_b 0 0 1 0
-- Retrieval info: CONNECT: dataout 0 0 1 0 @dataout 0 0 1 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL DIF_IO_BIR.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL DIF_IO_BIR.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL DIF_IO_BIR.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL DIF_IO_BIR.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL DIF_IO_BIR_inst.vhd FALSE
-- Retrieval info: LIB_FILE: arriav
