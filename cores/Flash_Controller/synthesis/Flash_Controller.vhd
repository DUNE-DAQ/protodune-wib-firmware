-- Flash_Controller.vhd

-- Generated using ACDS version 17.1 590

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Flash_Controller is
	port (
		addr          : in  std_logic_vector(23 downto 0) := (others => '0'); --          addr.addr
		asmi_dataoe   : out std_logic_vector(3 downto 0);                     --   asmi_dataoe.asmi_dataoe
		asmi_dataout  : in  std_logic_vector(3 downto 0)  := (others => '0'); --  asmi_dataout.asmi_dataout
		asmi_dclk     : out std_logic;                                        --     asmi_dclk.asmi_dclk
		asmi_scein    : out std_logic;                                        --    asmi_scein.asmi_scein
		asmi_sdoin    : out std_logic_vector(3 downto 0);                     --    asmi_sdoin.asmi_sdoin
		bulk_erase    : in  std_logic                     := '0';             --    bulk_erase.bulk_erase
		busy          : out std_logic;                                        --          busy.busy
		clkin         : in  std_logic                     := '0';             --         clkin.clk
		data_valid    : out std_logic;                                        --    data_valid.data_valid
		datain        : in  std_logic_vector(7 downto 0)  := (others => '0'); --        datain.datain
		dataout       : out std_logic_vector(7 downto 0);                     --       dataout.dataout
		fast_read     : in  std_logic                     := '0';             --     fast_read.fast_read
		illegal_erase : out std_logic;                                        -- illegal_erase.illegal_erase
		illegal_write : out std_logic;                                        -- illegal_write.illegal_write
		rden          : in  std_logic                     := '0';             --          rden.rden
		read_address  : out std_logic_vector(23 downto 0);                    --  read_address.read_address
		read_status   : in  std_logic                     := '0';             --   read_status.read_status
		reset         : in  std_logic                     := '0';             --         reset.reset
		shift_bytes   : in  std_logic                     := '0';             --   shift_bytes.shift_bytes
		status_out    : out std_logic_vector(7 downto 0);                     --    status_out.status_out
		wren          : in  std_logic                     := '0';             --          wren.wren
		write         : in  std_logic                     := '0'              --         write.write
	);
end entity Flash_Controller;

architecture rtl of Flash_Controller is
	component Flash_Controller_asmi_parallel_0 is
		port (
			clkin         : in  std_logic                     := 'X';             -- clk
			fast_read     : in  std_logic                     := 'X';             -- fast_read
			rden          : in  std_logic                     := 'X';             -- rden
			addr          : in  std_logic_vector(23 downto 0) := (others => 'X'); -- addr
			read_status   : in  std_logic                     := 'X';             -- read_status
			write         : in  std_logic                     := 'X';             -- write
			datain        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
			shift_bytes   : in  std_logic                     := 'X';             -- shift_bytes
			bulk_erase    : in  std_logic                     := 'X';             -- bulk_erase
			wren          : in  std_logic                     := 'X';             -- wren
			reset         : in  std_logic                     := 'X';             -- reset
			asmi_dataout  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- asmi_dataout
			dataout       : out std_logic_vector(7 downto 0);                     -- dataout
			busy          : out std_logic;                                        -- busy
			data_valid    : out std_logic;                                        -- data_valid
			status_out    : out std_logic_vector(7 downto 0);                     -- status_out
			illegal_write : out std_logic;                                        -- illegal_write
			illegal_erase : out std_logic;                                        -- illegal_erase
			read_address  : out std_logic_vector(23 downto 0);                    -- read_address
			asmi_dclk     : out std_logic;                                        -- asmi_dclk
			asmi_scein    : out std_logic;                                        -- asmi_scein
			asmi_sdoin    : out std_logic_vector(3 downto 0);                     -- asmi_sdoin
			asmi_dataoe   : out std_logic_vector(3 downto 0)                      -- asmi_dataoe
		);
	end component Flash_Controller_asmi_parallel_0;

begin

	asmi_parallel_0 : component Flash_Controller_asmi_parallel_0
		port map (
			clkin         => clkin,         --         clkin.clk
			fast_read     => fast_read,     --     fast_read.fast_read
			rden          => rden,          --          rden.rden
			addr          => addr,          --          addr.addr
			read_status   => read_status,   --   read_status.read_status
			write         => write,         --         write.write
			datain        => datain,        --        datain.datain
			shift_bytes   => shift_bytes,   --   shift_bytes.shift_bytes
			bulk_erase    => bulk_erase,    --    bulk_erase.bulk_erase
			wren          => wren,          --          wren.wren
			reset         => reset,         --         reset.reset
			asmi_dataout  => asmi_dataout,  --  asmi_dataout.asmi_dataout
			dataout       => dataout,       --       dataout.dataout
			busy          => busy,          --          busy.busy
			data_valid    => data_valid,    --    data_valid.data_valid
			status_out    => status_out,    --    status_out.status_out
			illegal_write => illegal_write, -- illegal_write.illegal_write
			illegal_erase => illegal_erase, -- illegal_erase.illegal_erase
			read_address  => read_address,  --  read_address.read_address
			asmi_dclk     => asmi_dclk,     --     asmi_dclk.asmi_dclk
			asmi_scein    => asmi_scein,    --    asmi_scein.asmi_scein
			asmi_sdoin    => asmi_sdoin,    --    asmi_sdoin.asmi_sdoin
			asmi_dataoe   => asmi_dataoe    --   asmi_dataoe.asmi_dataoe
		);

end architecture rtl; -- of Flash_Controller
