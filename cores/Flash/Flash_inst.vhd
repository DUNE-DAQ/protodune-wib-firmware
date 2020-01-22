	component Flash is
		port (
			clkin         : in  std_logic                     := 'X';             -- clk
			rden          : in  std_logic                     := 'X';             -- rden
			addr          : in  std_logic_vector(23 downto 0) := (others => 'X'); -- addr
			reset         : in  std_logic                     := 'X';             -- reset
			dataout       : out std_logic_vector(7 downto 0);                     -- dataout
			busy          : out std_logic;                                        -- busy
			data_valid    : out std_logic;                                        -- data_valid
			write         : in  std_logic                     := 'X';             -- write
			datain        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
			illegal_write : out std_logic;                                        -- illegal_write
			wren          : in  std_logic                     := 'X';             -- wren
			read_status   : in  std_logic                     := 'X';             -- read_status
			status_out    : out std_logic_vector(7 downto 0);                     -- status_out
			fast_read     : in  std_logic                     := 'X';             -- fast_read
			bulk_erase    : in  std_logic                     := 'X';             -- bulk_erase
			illegal_erase : out std_logic;                                        -- illegal_erase
			read_address  : out std_logic_vector(23 downto 0);                    -- read_address
			shift_bytes   : in  std_logic                     := 'X'              -- shift_bytes
		);
	end component Flash;

	u0 : component Flash
		port map (
			clkin         => CONNECTED_TO_clkin,         --         clkin.clk
			rden          => CONNECTED_TO_rden,          --          rden.rden
			addr          => CONNECTED_TO_addr,          --          addr.addr
			reset         => CONNECTED_TO_reset,         --         reset.reset
			dataout       => CONNECTED_TO_dataout,       --       dataout.dataout
			busy          => CONNECTED_TO_busy,          --          busy.busy
			data_valid    => CONNECTED_TO_data_valid,    --    data_valid.data_valid
			write         => CONNECTED_TO_write,         --         write.write
			datain        => CONNECTED_TO_datain,        --        datain.datain
			illegal_write => CONNECTED_TO_illegal_write, -- illegal_write.illegal_write
			wren          => CONNECTED_TO_wren,          --          wren.wren
			read_status   => CONNECTED_TO_read_status,   --   read_status.read_status
			status_out    => CONNECTED_TO_status_out,    --    status_out.status_out
			fast_read     => CONNECTED_TO_fast_read,     --     fast_read.fast_read
			bulk_erase    => CONNECTED_TO_bulk_erase,    --    bulk_erase.bulk_erase
			illegal_erase => CONNECTED_TO_illegal_erase, -- illegal_erase.illegal_erase
			read_address  => CONNECTED_TO_read_address,  --  read_address.read_address
			shift_bytes   => CONNECTED_TO_shift_bytes    --   shift_bytes.shift_bytes
		);

