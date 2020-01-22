library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.Flash_IO.all;
use ieee.std_logic_misc.all;
use work.types.all;
entity Flash is
  
  port (
    clk_25Mhz    : in  std_logic;
    clk_10Mhz    : in  std_logic;
    reset        : in  std_logic;
    asmi_dataout : in  std_logic_vector(3 downto 0) := (others => 'X');  -- asmi_dataout
    asmi_dclk    : out std_logic;       -- asmi_dclk
    asmi_scein   : out std_logic;       -- asmi_scein
    asmi_sdoin   : out std_logic_vector(3 downto 0);  -- asmi_sdoin
    asmi_dataoe  : out std_logic_vector(3 downto 0);  -- asmi_dataoe    
    monitor      : out Flash_monitor_t;
    control      : in  Flash_control_t);

end entity Flash;

architecture behavior of Flash is

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  component RemoteReload is
    port (
      busy        : out std_logic;
      clock       : in  std_logic                    := 'X';
      data_out    : out std_logic_vector(23 downto 0);
      param       : in  std_logic_vector(2 downto 0) := (others => 'X');
      read_param  : in  std_logic                    := 'X';
      reconfig    : in  std_logic                    := 'X';
      reset       : in  std_logic                    := 'X';
      reset_timer : in  std_logic                    := 'X';
      write_param : in  std_logic                     := 'X';             -- write_param
      data_in     : in  std_logic_vector(23 downto 0) := (others => 'X')  -- data_in
);
  end component RemoteReload;

  component Flash_Controller is
    port (
      clkin         : in  std_logic                     := 'X';
      rden          : in  std_logic                     := 'X';
      addr          : in  std_logic_vector(23 downto 0) := (others => 'X');
      reset         : in  std_logic                     := 'X';
      dataout       : out std_logic_vector(7 downto 0);
      busy          : out std_logic;
      data_valid    : out std_logic;
      write         : in  std_logic                     := 'X';
      datain        : in  std_logic_vector(7 downto 0)  := (others => 'X');
      illegal_write : out std_logic;
      wren          : in  std_logic                     := 'X';
      read_status   : in  std_logic                     := 'X';
      status_out    : out std_logic_vector(7 downto 0);
      fast_read     : in  std_logic                     := 'X';
      bulk_erase    : in  std_logic                     := 'X';
      illegal_erase : out std_logic;
      read_address  : out std_logic_vector(23 downto 0);
      shift_bytes   : in  std_logic                     := 'X';
      asmi_dataout  : in  std_logic_vector(3 downto 0)  := (others => 'X');  -- asmi_dataout
      asmi_dclk     : out std_logic;    -- asmi_dclk
      asmi_scein    : out std_logic;    -- asmi_scein
      asmi_sdoin    : out std_logic_vector(3 downto 0);  -- asmi_sdoin
      asmi_dataoe   : out std_logic_vector(3 downto 0)   -- asmi_dataoe
      );
  end component Flash_Controller;

--  component tri is
--    port (
--      a_in  : in  std_logic;
--      oe    : in  std_logic;
--      a_out : out std_logic);
--  end component tri;
  
  type FLASH_STATE_T is (FLASH_STATE_IDLE,
                         FLASH_STATE_WAIT,
                         FLASH_STATE_WAIT_2,
                         FLASH_STATE_WRITE,
                         FLASH_STATE_WRITE_FINISH,
                         FLASH_STATE_WRITE_FINISH2,
                         FLASH_STATE_ERASE,
                         FLASH_STATE_READ);
  signal flash_state : FLASH_STATE_T := FLASH_STATE_IDLE;

  signal wr_en       : std_logic                     := '0';
  signal shift_bytes : std_logic                     := '0';
  signal flash_wr    : std_logic                     := '0';
  signal bulk_erase  : std_logic                     := '0';
  signal address     : std_logic_vector(23 downto 0) := (others => '0');
  signal data        : std_logic_vector(7 downto 0)  := (others => '0');

  signal read_enable     : std_logic                    := '0';
  signal read_data       : std_logic_vector(7 downto 0) := (others => '0');
  signal read_data_valid : std_logic                    := '0';
  signal read_start      : std_logic                    := '0';

  signal flash_busy : std_logic                    := '0';
  signal busy       : std_logic                    := '0';
  signal busy_sr    : std_logic_vector(2 downto 0) := (others => '0');

  signal byte_count   : unsigned(7 downto 0) := (others => '0');
  signal byte_address : unsigned(7 downto 0) := (others => '0');

  signal page : uint32_array_t(FLASH_PAGE_SIZE-1 downto 0) := (others => (others => '0'));

  signal illegal_write       : std_logic;
  signal illegal_write_latch : std_logic;
  signal illegal_erase       : std_logic;
  signal illegal_erase_latch : std_logic;

  signal reconfig_rd_param   : std_logic;
  signal reconfig_wr_param   : std_logic;
  signal reconfig   : std_logic;

  --signal AS_DATA_OUT : std_logic_vector(3 downto 0);
  --signal AS_DATA_OUT_ENABLE : std_logic_vector(3 downto 0);
  function reverse_vector_bits (a : in std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'reverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_any_vector

begin  -- architecture behavior

--page control
  monitor.data <= page;
  page_control : process (clk_25Mhz) is
  begin  -- process page_control
    if clk_25Mhz'event and clk_25Mhz = '1' then  -- rising clock edge
      if flash_state = FLASH_STATE_IDLE then
        if control.data_wr = '1' then
          page(control.data_address) <= control.data;
        end if;
      elsif flash_state = FLASH_STATE_READ then
--        if byte_address /= byte_count and read_data_valid = '1' then
        if read_data_valid = '1' then
        -- fill the correct byte of our 32bit word
          case byte_address(1 downto 0) is
            when "00" =>
              page(to_integer(byte_address(7 downto 2)))( 7 downto  0) <= reverse_vector_bits(read_data);
            when "01" =>
              page(to_integer(byte_address(7 downto 2)))(15 downto  8) <= reverse_vector_bits(read_data);
            when "10" =>
              page(to_integer(byte_address(7 downto 2)))(23 downto 16) <= reverse_vector_bits(read_data);
            when "11" =>
              page(to_integer(byte_address(7 downto 2)))(31 downto 24) <= reverse_vector_bits(read_data);
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process page_control;



  --Monitor of command signals


--  monitor.data <= control.data;
  monitor.byte_count <= control.byte_count;
  monitor.address    <= control.address;
  FlashWriteControl : process (clk_25Mhz) is
  begin  -- process FlashWriteControl
    if clk_25Mhz'event and clk_25Mhz = '1' then  -- rising clock edge
      if reset = '1' then
        flash_state <= FLASH_STATE_IDLE;
      else
        --Zero out control signals unless modifed later
        wr_en       <= '0';
        shift_bytes <= '0';
        flash_wr    <= '0';
        bulk_erase  <= '0';
        read_start  <= '0';

        --State machine for FLASH control
        case flash_state is
          when FLASH_STATE_IDLE =>
            --Idle
            if busy = '0' then
              -- if the controller isn't still busy with a command
              if control.wr = '1' then
                -- start a write transaction
                flash_state  <= FLASH_STATE_WRITE;
                byte_count   <= unsigned(control.byte_count);
                byte_address <= x"00";
                address      <= control.address;
              elsif control.rd = '1' then
                -- start a write transaction
                flash_state  <= FLASH_STATE_READ;
                byte_count   <= unsigned(control.byte_count);
                byte_address <= x"00";
                address      <= control.address;
                read_enable  <= '1';
                read_start   <= '1';
              elsif control.erase = '1' then
                --bulk erase of the flash
                flash_state <= FLASH_STATE_ERASE;
              end if;
            end if;
          when FLASH_STATE_ERASE =>
            bulk_erase  <= '1';
            wr_en       <= '1';
            --Finish
            flash_state <= FLASH_STATE_WAIT;
          when FLASH_STATE_READ =>

            if byte_address = byte_count then
              --We are done
              if read_data_valid = '1' then
                read_enable <= '0';
                flash_state <= FLASH_STATE_IDLE;
              end if;
            elsif read_data_valid = '1' then
              --move to the next byte
--              if byte_address <  byte_count then
              byte_address <= byte_address + 1;
--              end if;
            end if;
          when FLASH_STATE_WRITE =>
            --Process block writes from register map

            --Use LS 2 bits to select byte from 32bit word
            case byte_address(1 downto 0) is
              when "00" =>
                data <= reverse_vector_bits(page(to_integer(byte_address(7 downto 2)))( 7 downto  0));
              when "01" =>
                data <= reverse_vector_bits(page(to_integer(byte_address(7 downto 2)))(15 downto  8));
              when "10" =>
                data <= reverse_vector_bits(page(to_integer(byte_address(7 downto 2)))(23 downto 16));
              when "11" =>
                data <= reverse_vector_bits(page(to_integer(byte_address(7 downto 2)))(31 downto 24));
              when others => null;
            end case;

            --write to the internal memory for page write until we have
            --cleared the byte count
            wr_en       <= '1';
            shift_bytes <= '1';
            if byte_count = byte_address then
              flash_state <= FLASH_STATE_WRITE_FINISH;
            else
              byte_address <= byte_address + 1;
            end if;
          when FLASH_STATE_WRITE_FINISH =>
            wr_en       <= '1';
            shift_bytes <= '0';
            flash_wr    <= '1';
            flash_state <= FLASH_STATE_WRITE_FINISH2;
          when FLASH_STATE_WRITE_FINISH2 =>
            wr_en       <= '0';
            flash_wr    <= '0';
            flash_state <= FLASH_STATE_WAIT;

            --if byte_address < byte_count then -- if byte_count < byte_address then
            --  --write to the internal memory for page write until we have
            --  --cleared the byte count
            --  wr_en <= '1';
            --  shift_bytes <= '1';              
            --  byte_address <= byte_address + 1;
            --elsif byte_count = byte_address then
            --  --page fill is done, start the write sequence
            --  wr_en <= '1';
            --  flash_wr <= '1';
            --  --Finish
            --  flash_state <= FLASH_STATE_WAIT;
            --end if;
          when FLASH_STATE_WAIT =>
            --This state gives us a chance to wait for busy to be active
            --return to the idle state
            flash_state <= FLASH_STATE_WAIT_2;
          when FLASH_STATE_WAIT_2 =>
            if busy = '0' then
              flash_state <= FLASH_STATE_IDLE;
            end if;
          when others => null;
        end case;
      end if;
      
    end if;
  end process FlashWriteControl;

  monitor.busy <= busy;
  BusyProcessor : process (clk_25Mhz) is
  begin  -- process BusyProcessor
    if clk_25Mhz'event and clk_25Mhz = '1' then  -- rising clock edge
      if reset = '1' then
      else
        busy    <= or_reduce(busy_sr);
        busy_sr <= busy_sr(2 downto 1) & flash_busy;
      end if;
    end if;
  end process BusyProcessor;

  monitor.illegal_erase <= illegal_erase_latch;
  monitor.illegal_write <= illegal_write_latch;
  ErrorCaptureProcess : process(clk_25Mhz) is
  begin
    if clk_25Mhz'event and clk_25Mhz = '1' then  -- rising clock edge
      if control.rd = '1' or control.wr = '1' or control.erase = '1' then
        illegal_write_latch <= illegal_write;
        illegal_erase_latch <= illegal_erase;
      else
        illegal_write_latch <= illegal_write_latch or illegal_write;
        illegal_erase_latch <= illegal_erase_latch or illegal_erase;
      end if;
    end if;
  end process ErrorCaptureProcess;


  Flash_1 : Flash_Controller
    port map (
      clkin         => clk_25Mhz,
      rden          => read_enable,
      addr          => address,
      reset         => reset,
      dataout       => read_data,
      busy          => flash_busy,
      data_valid    => read_data_valid,
      write         => flash_wr,
      datain        => data,
      illegal_write => illegal_write,
      wren          => wr_en,
      read_status   => 'X',
      status_out    => monitor.status,
      fast_read     => read_start,
      bulk_erase    => bulk_erase,
      illegal_erase => illegal_erase,
      read_address  => monitor.read_address,
      shift_bytes   => shift_bytes,
      asmi_dataout  => asmi_dataout,
      asmi_dclk     => asmi_dclk,
      asmi_scein    => asmi_scein,
      asmi_sdoin    => asmi_sdoin,
      asmi_dataoe   => asmi_dataoe
--      asmi_dataout  => AS_DATA,  
--      asmi_dclk     => AS_CLK,     
--      asmi_scein    => AS_NCS,    
--      asmi_sdoin    => AS_DATA_OUT,    
--      asmi_dataoe   => AS_DATA_OUT_ENABLE
      );


  monitor.reconfig <= control.reconfig;
  monitor.reconfig_param <= control.reconfig_param;
  pacd_1: entity work.pacd
    port map (
      iPulseA => control.reconfig_rd_param,
      iClkA   => clk_25Mhz,
      iRSTAn  => '1',
      iClkB   => clk_10Mhz,
      iRSTBn  => '1',
      oPulseB => reconfig_rd_param);
  pacd_2: entity work.pacd
    port map (
      iPulseA => control.reconfig_wr_param,
      iClkA   => clk_25Mhz,
      iRSTAn  =>  '1',
      iClkB   => clk_10Mhz,
      iRSTBn  => '1',
      oPulseB => reconfig_wr_param);
  pacd_3: entity work.pacd
    port map (
      iPulseA => control.reconfig,
      iClkA   => clk_25Mhz,
      iRSTAn  =>  '1',
      iClkB   => clk_10Mhz,
      iRSTBn  => '1',
      oPulseB => reconfig);
  RemoteReload_1 : RemoteReload
    port map (
      busy        => monitor.reconfig_busy,
      clock       => clk_10Mhz,
      data_out    => monitor.reconfig_rd_data,
      param       => control.reconfig_param,
      read_param  => reconfig_rd_param,
      reconfig    => reconfig,
      reset       => control.reconfig_reset,
      reset_timer => 'X',
      write_param => reconfig_wr_param,
      data_in     => control.reconfig_wr_data);

--  AS_TRI_IOs: for iBit in 3 downto 0 generate
--    tri_1: tri
--      port map (
--        a_in  => AS_DATA_OUT(iBit),
--        oe    => AS_DATA_OUT_ENABLE(iBit),
--        a_out => AS_DATA(iBit));
--  end generate AS_TRI_IOs;
  

end architecture behavior;
