	component Flash_Controller is
		port (
			addr          : in  std_logic_vector(23 downto 0) := (others => 'X'); -- addr
			asmi_dataoe   : out std_logic_vector(3 downto 0);                     -- asmi_dataoe
			asmi_dataout  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- asmi_dataout
			asmi_dclk     : out std_logic;                                        -- asmi_dclk
			asmi_scein    : out std_logic;                                        -- asmi_scein
			asmi_sdoin    : out std_logic_vector(3 downto 0);                     -- asmi_sdoin
			bulk_erase    : in  std_logic                     := 'X';             -- bulk_erase
			busy          : out std_logic;                                        -- busy
			clkin         : in  std_logic                     := 'X';             -- clk
			data_valid    : out std_logic;                                        -- data_valid
			datain        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
			dataout       : out std_logic_vector(7 downto 0);                     -- dataout
			fast_read     : in  std_logic                     := 'X';             -- fast_read
			illegal_erase : out std_logic;                                        -- illegal_erase
			illegal_write : out std_logic;                                        -- illegal_write
			rden          : in  std_logic                     := 'X';             -- rden
			read_address  : out std_logic_vector(23 downto 0);                    -- read_address
			read_status   : in  std_logic                     := 'X';             -- read_status
			reset         : in  std_logic                     := 'X';             -- reset
			shift_bytes   : in  std_logic                     := 'X';             -- shift_bytes
			status_out    : out std_logic_vector(7 downto 0);                     -- status_out
			wren          : in  std_logic                     := 'X';             -- wren
			write         : in  std_logic                     := 'X'              -- write
		);
	end component Flash_Controller;

	u0 : component Flash_Controller
		port map (
			addr          => CONNECTED_TO_addr,          --          addr.addr
			asmi_dataoe   => CONNECTED_TO_asmi_dataoe,   --   asmi_dataoe.asmi_dataoe
			asmi_dataout  => CONNECTED_TO_asmi_dataout,  --  asmi_dataout.asmi_dataout
			asmi_dclk     => CONNECTED_TO_asmi_dclk,     --     asmi_dclk.asmi_dclk
			asmi_scein    => CONNECTED_TO_asmi_scein,    --    asmi_scein.asmi_scein
			asmi_sdoin    => CONNECTED_TO_asmi_sdoin,    --    asmi_sdoin.asmi_sdoin
			bulk_erase    => CONNECTED_TO_bulk_erase,    --    bulk_erase.bulk_erase
			busy          => CONNECTED_TO_busy,          --          busy.busy
			clkin         => CONNECTED_TO_clkin,         --         clkin.clk
			data_valid    => CONNECTED_TO_data_valid,    --    data_valid.data_valid
			datain        => CONNECTED_TO_datain,        --        datain.datain
			dataout       => CONNECTED_TO_dataout,       --       dataout.dataout
			fast_read     => CONNECTED_TO_fast_read,     --     fast_read.fast_read
			illegal_erase => CONNECTED_TO_illegal_erase, -- illegal_erase.illegal_erase
			illegal_write => CONNECTED_TO_illegal_write, -- illegal_write.illegal_write
			rden          => CONNECTED_TO_rden,          --          rden.rden
			read_address  => CONNECTED_TO_read_address,  --  read_address.read_address
			read_status   => CONNECTED_TO_read_status,   --   read_status.read_status
			reset         => CONNECTED_TO_reset,         --         reset.reset
			shift_bytes   => CONNECTED_TO_shift_bytes,   --   shift_bytes.shift_bytes
			status_out    => CONNECTED_TO_status_out,    --    status_out.status_out
			wren          => CONNECTED_TO_wren,          --          wren.wren
			write         => CONNECTED_TO_write          --         write.write
		);

