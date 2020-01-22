library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.types.all;

entity register_map_bridge is

  generic (
    CLOCK_DOMAINS : integer := 2);

  port (
    clk_reg_map : in  std_logic;
    -- register map signals (clk_reg_map)
    reset       : in  std_logic;
    WR_strobe   : in  std_logic;
    RD_strobe   : in  std_logic;
    WR_address  : in  std_logic_vector(15 downto 0);
    RD_address  : in  std_logic_vector(15 downto 0);
    data_in     : in  std_logic_vector(31 downto 0);
    data_out    : out std_logic_vector(31 downto 0);
    rd_ack      : out std_logic;
    wr_ack      : out std_logic;
    
    --fifo signals (clk_domain(i))
    clk_domain         : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    clk_domain_locked  : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    -- register read interface (clk_domain(i))
    read_address_valid : out std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    read_address_ack   : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    read_address       : out uint16_array_t(CLOCK_DOMAINS-1 downto 0);

    read_data_wr          : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    read_data             : in  uint36_array_t(CLOCK_DOMAINS-1 downto 0);
    --register write interface (clk_domain(i))
    write_addr_data_valid : out std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    write_addr_data_ack   : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
    write_addr            : out uint16_array_t(CLOCK_DOMAINS-1 downto 0);
    write_data            : out uint32_array_t(CLOCK_DOMAINS-1 downto 0)
    );

end entity register_map_bridge;

architecture Behavioral of register_map_bridge is


  component register_map_pass is
    generic (
      WIDTH : integer);
    port (
      clkA       : in  std_logic;
      clkB       : in  std_logic;
      inA        : in  std_logic_vector(WIDTH-1 downto 0);
      inA_valid  : in  std_logic;
      outB       : out std_logic_vector(WIDTH-1 downto 0);
      outB_valid : out std_logic);
  end component register_map_pass;


  -------------------------------------------------------------------------------
  -- signals
  -------------------------------------------------------------------------------
  type REG_STATE_t is (REG_STATE_IDLE,
                       REG_STATE_READ_WAIT,
                       REG_STATE_READ_RESET,
                       REG_STATE_READ_RESET_WAIT
                       );
  signal REG_State : REG_STATE_t := REG_STATE_IDLE;

  signal RD_strobe_delay : std_logic;
  signal WR_strobe_delay : std_logic;
  
  signal clk_domain_enabled         : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal clk_domain_enabled_buf     : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_cycle_address_fifo_in : std_logic_vector(15 downto 0);
  signal read_cycle_address_wr      : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_cycle_data_fifo_out   : uint36_array_t(CLOCK_DOMAINS-1 downto 0);
  signal write_cycle_addr_data_wr   : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_cycle_data_ack        : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_cycle_data_empty      : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal write_cycle_addr_and_data  : std_logic_vector(47 downto 0);

  signal read_data_fifo_valid : std_logic_vector(CLOCK_DOMAINS-1 downto 0);

  signal read_data_fifo_found : std_logic_vector(CLOCK_DOMAINS-1 downto 0);

  signal read_address_fifo_empty : std_logic_vector(CLOCK_DOMAINS-1 downto 0);

  signal write_fifo_empty        : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal write_addr_data         : uint48_array_t(CLOCK_DOMAINS-1 downto 0);

  signal read_data_acked : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_cycle_data_valid : std_logic_vector(CLOCK_DOMAINS-1 downto 0);

begin  -- architecture Behavioral

  -------------------------------------------------------------------------------
  -- Clock domain enable
  -------------------------------------------------------------------------------
  clk_domain_enabled <= clk_domain_locked;

  -------------------------------------------------------------------------------
  -- UDP interface to register maps in different clock domains
  -------------------------------------------------------------------------------
  register_control : process (clk_reg_map, reset) is
  begin  -- process register_control
    if reset = '1' then                 -- asynchronous reset (active high)
      -- turn of fifo reset request
      read_cycle_data_ack        <= (others => '0');
      write_cycle_addr_data_wr   <= (others => '0');
      read_cycle_address_wr      <= (others => '0');
      RD_strobe_delay            <= '0';
      WR_strobe_delay            <= '0';

    elsif clk_reg_map'event and clk_reg_map = '1' then  -- rising clock edge
      rd_ack          <= '0';
      wr_ack          <= '0';
      RD_strobe_delay <= RD_strobe;
      WR_strobe_delay <= WR_strobe;
      
      --read/write strobe resets
      read_cycle_address_wr      <= (others => '0');
      read_cycle_data_ack        <= (others => '0');
      write_cycle_addr_data_wr   <= (others => '0');

      
      --State machine
      case REG_STATE is
        -------------------------------------------------------------------------
        -- Register IDLE (read has priority over write)
        -------------------------------------------------------------------------        
        when REG_STATE_IDLE =>
          if RD_strobe_delay = '1' then
            --Address to read
            read_cycle_address_fifo_in <= RD_address;

            -- write the address we want to read to the other clock domains
            read_cycle_address_wr <= clk_domain_enabled;
            --Set no one as responded
            read_data_acked <= (others => '0');
            --wait for response
            REG_STATE             <= REG_STATE_READ_WAIT;
          elsif WR_strobe_delay = '1' then
            --write the data and address to each enabled fifo
            write_cycle_addr_data_wr <= clk_domain_enabled;
            write_cycle_addr_and_data <= WR_address & data_in;
            --we are done in this clock domain, go back to idle
            REG_STATE                <= REG_STATE_IDLE;
            -- ack the write
            wr_ack <= '1';
          end if;
        -------------------------------------------------------------------------
        -- Wait for a fifo to respond and return the value
        -- Since this setup allows for multiple responses from the same
        -- address(different domains), we have a rule that we take the lowest
        -- index return.
        -------------------------------------------------------------------------        
        when REG_STATE_READ_WAIT =>
          --Keep a track of which domains we've heard from
          read_data_acked <= read_data_acked or read_cycle_data_valid;
                    
          if (clk_domain_enabled and read_data_acked) = clk_domain_enabled then
            --All domain fifos have returned data (no enabled fifo is empty)

            --Process the response
            if (clk_domain_enabled(0) = '1') and (read_data_fifo_found(0) = '1') then
              --The first clock domain has to be treated special for the later
              --for loop
              --read the data
              data_out <= read_cycle_data_fifo_out(0)(31 downto 0);
              
            elsif CLOCK_DOMAINS /= 1 then  -- The following logic requires more
                                           -- than one clock domain
              for iClockDomain in 1 to CLOCK_DOMAINS-1 loop
                -- Check if this clock domain's fifo has data in it,
                -- but no clock domain fifo with a lower index does.
                if or_reduce(read_data_fifo_found(iClockDomain-1 downto 0) and
                             clk_domain_enabled(iClockDomain-1 downto 0)) = '0' then
                  --read the data
                  data_out <= read_cycle_data_fifo_out(iClockDomain)(31 downto 0);
                end if;
              end loop;  -- iClockDomain in 0 to CLOCK_DOMAINS-1 loop
            end if;
            
            --The read is done, ack the request with the data
            rd_ack       <= '1';
            REG_STATE           <= REG_STATE_IDLE;
          else
            --Continue to wait
            REG_STATE <= REG_STATE_READ_WAIT;
          end if;

        when others => REG_STATE <= REG_STATE_IDLE;
      end case;
    end if;
  end process register_control;

  --All the fifos needed for reads and writes
  CDCs : for iClockDomain in 0 to CLOCK_DOMAINS-1 generate
    --Send the address for reading
    read_address_CDC: entity work.register_map_pass
      generic map (
        WIDTH => 16)
      port map (
        clkA       => clk_reg_map,
        clkB       => clk_domain(iClockDomain),
        inA        => read_cycle_address_fifo_in,
        inA_valid  => read_cycle_address_wr(iClockDomain),
        outB       => read_address(iClockDomain),
        outB_valid => read_address_valid(iClockDomain));

    --Get the read data
    read_data_CDC: entity work.register_map_pass
      generic map (
        WIDTH => 36)
      port map (
        clkA       => clk_domain(iClockDomain),
        clkB       => clk_reg_map,
        inA        => read_data(iClockDomain),
        inA_valid  => read_data_wr(iClockDomain),
        outB       => read_cycle_data_fifo_out(iClockDomain),
        outB_valid => read_cycle_data_valid(iClockDomain));
    read_data_fifo_found(iClockDomain) <= read_cycle_data_fifo_out(iClockDomain)(32);  --clk_reg_map domain

    --write data
    write_data_CDC: entity work.register_map_pass
      generic map (
        WIDTH => 48)
      port map (
        clkA       => clk_reg_map,
        clkB       => clk_domain(iClockDomain),
        inA        => write_cycle_addr_and_data,             --clk_reg_map domain
        inA_valid  => write_cycle_addr_data_wr(iClockDomain),              --clk_reg_map domain
        outB       => write_addr_data(iClockDomain),
        outB_valid => write_addr_data_valid(iClockDomain));
    write_addr(iClockDomain)            <= write_addr_data(iClockDomain)(47 downto 32);  --clk_reg_map domain
    write_data(iClockDomain)            <= write_addr_data(iClockDomain)(31 downto 0);  --clk_reg_map domain
  end generate CDCs;



end architecture Behavioral;

