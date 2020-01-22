library IEEE;
use IEEE.std_logic_1164.all;

entity reg_control is
  
  generic (
    ADDR_WIDTH       : integer := 16;
    DATA_WIDTH       : integer := 32;
    COUNT_WIDTH      : integer := 4);

  port (
    clk            : in std_logic;
    reset          : in std_logic;
    -- reg request input (from UDP HDL)
    reply_ip       : in std_logic_vector(31 downto 0);
    reply_mac      : in std_logic_vector(48 downto 0);
    reply_port     : in std_logic_vector(16 downto 0);
    addr_in        : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_in        : in std_logic_vector(DATA_WIDTH-1 downto 0);
    hw_destination : in std_logic_vector(4 downto 0);
    rw_in          : in std_logic;
    read_count     : in std_logic_vector(COUNT_WIDTH-1 downto 0);
    reply_in       : in std_logic;

    --register map interface (WIB)    
    rd_strobe     : out std_logic;
    wr_strobe     : out std_logic;
    reg_data_out  : out std_logic_vector(DATA_WIDTH -1 downto 0);
    reg_addr      : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    reg_data_in   : in  std_logic_vector(DATA_WIDTH -1 downto 0);
    rd_ack        : in  std_logic;
    wr_ack        : in  std_logic;

    --register map interface (FEMB)
    FEMB_BRD           : OUT std_logic_vector(3 downto 0);
    FEMB_RD_strb       : OUT STD_LOGIC;
    FEMB_WR_strb       : OUT STD_LOGIC;
    FEMB_RD_Data_valid : IN  STD_LOGIC;
    FEMB_RD_DATA       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    --response (to UDP HDL)
    tx_udp_SOF         : in  std_logic;
    tx_udp_EOF         : in  std_logic;
    tx_reset           : out std_logic;
    
    EN_WR_RDBK	       : out std_logic;    		
    tx_WR_data	       : in  std_logic_vector(31 downto 0);
    reg_wr_strb	       : out std_logic;    		-- Input destination ready 
    
    reg_rd_strb	       : out std_logic;    		-- Input destination ready 
    reg_start_address  : out std_logic_vector(15 downto 0);
    reg_RDOUT_num      : out std_logic_vector(3 downto 0);   -- number of registers to read out
    reg_address	       : in  std_logic_vector(15 downto 0);
    reg_data	       : out std_logic_vector(31 downto 0);
    
    FEMB_BRD	       : OUT std_logic_vector(3 downto 0);		
    FEMB_RDBK_strb     : OUT STD_LOGIC;
    FEMB_RDBK_DATA     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    FEMB_WR_strb_RESP  : OUT STD_LOGIC    
    );                 

end entity reg_control;

architecture Behavioral of reg_control is

  type SM_state_t is (SM_RESET,
                      SM_IDLE,
                      SM_PRE_START,
                      SM_START,
                      SM_WIB_REG_START_SINGLE,
                      SM_WIB_REG_START_MULT,
                      SM_WIB_REG_WAIT_SINGLE,
                      SM_WIB_REG_WAIT_MULT,
                      SM_WIB_REG_DELAY_MULT,
                      SM_FEMB_REG_START,
                      SM_FEMB_REG_WAIT,
                      SM_SEND_SINGLE,
                      SM_SEND_MULTIPLE,
                      SM_SEND_WAIT,
                      );
  signal state : SM_state_t;

  --FIFO queue
  constant DIR_READ : std_logic := '1';
  constant DIR_WRITE : std_logic := '0';
  signal queue_empty : std_logic;
  signal queue_rd : std_logic;
  -- data signals
  signal queue_data_WIB_REQ : std_logic;
  signal queue_data_FEMB_ID : std_logic_vector(3 downto 0);
  signal queue_data_single_transaction : std_logic;
  signal queue_data_RW : std_logic;

  type reply_queue_data_t is array ((2**COUNT_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal reply_data : reply_queue_data_t;

  --register map signals
  signal mult_op_counter : unsigned(COUNT_WIDTH-1 downto 0);

  
begin  -- architecture Behavioral

  -------------------------------------------------------------------------------
  -- Overall state machine
  -------------------------------------------------------------------------------
  SM_control: process (clk, reset) is
  begin  -- process SM_control
    if reset = '0' then                 -- asynchronous reset (active low)
      state <= SM_RESET;
    elsif clk'event and clk = '1' then  -- rising clock edge
      -- state machine
      case state is
        -----------------------------------------------------
        when SM_RESET =>
          state <= SM_IDLE;
        -----------------------------------------------------
        when SM_IDLE =>
          if queue_empty = '0' then
            state <= SM_PRE_START;
          end if;
        -----------------------------------------------------  
        when SM_PRE_START =>
          --delay one clock tick for fifo output
          state <= SM_START;
        -----------------------------------------------------  
        when SM_START =>
          --Figure out which kind of transaction we are doing
          if queue_data_WIB_REQ = '1' then
            --WIB request
            if queue_data_single_transaction = '1' then
              state <= SM_WIB_REG_START_SINGLE;
            else
              state <= SM_WIB_REG_START_MULT;
              mult_op_counter <= (others => '0'); -- zero
            end if;
          else
            --FEMB request
            state <= SM_FEMB_REG_START;
          end if;
        -----------------------------------------------------
        when SM_WIB_REG_START_MULT =>
          if mult_op_counter = queue_data_count then
            state <= SM_SEND_MULTIPLE;            
          else
            state <= SM_WIB_REG_WAIT_MULT;              
          end if;
        -----------------------------------------------------
        when SM_WIB_REG_WAIT_MULT =>
          if queue_data_RW = DIR_READ and rd_ack= '1' then
--            mult_op_counter(to_integer(mult_op_counter)) <= reg_data_in;
            mult_op_counter <= mult_op_counter + 1;
            state <= SM_WIB_REG_START_MULT;
          elsif queue_data_RW = DIR_WRITE and wr_ack = '1' then
            --We ignore EN_WR_RDBK here because we want to make sure we wait
            --until the end of all the un RDBK'd writes before we move on to
            --process a new packet.
--            mult_op_counter(to_integer(mult_op_counter)) <= queue_data_write_data;
            mult_op_counter <= mult_op_counter + 1;
            state <= SM_WIB_REG_DELAY_MULT;
          end if;
        -----------------------------------------------------
        when SM_WIB_REG_DELAY_MULT =>
          --We need a delay here for a fifo rd to be ready for START_MULT
          -- only needed with a 
          state <= SM_WIB_REG_START_MULT;
        -----------------------------------------------------          
        when SM_WIB_REG_START_SINGLE =>
          state <= SM_WIB_REG_WAIT_SINGLE;
        -----------------------------------------------------
        when SM_WIB_REG_WAIT_SINGLE =>
          if queue_data_RW = DIR_READ and rd_ack= '1' then
            state <= SM_SEND_SINGLE;
          elsif queue_data_RW = DIR_WRITE then
            if EN_WR_RDBK = '1' and wr_ack = '1' then
              state <= SM_SEND_SINGLE;
            else
              state <= SM_SEND_DONE;
            end if;
          else
            --stay in current state
            --state <= SM_WIB_REG_WAIT_SINGLE;
          end if;          
        -----------------------------------------------------
        when SM_FEMB_REG_START =>
          state <= SM_FEMB_REG_WAIT;
        -----------------------------------------------------
        when SM_FEMB_REG_WAIT =>
          if queue_data_RW = DIR_READ and FEMB_RD_Data_valid = '1' then
            state <= SM_SEND_SINGLE;
          elsif queue_data_RW = DIR_WRITE then
            if EN_WR_RDBK = '1' then
              state <= SM_SEND_SINGLE;
            else
              state <= SM_SEND_DONE;
            end if;
          else
            --stay in current state
            --state <= SM_FEMB_REG_WAIT;
          end if;
        -----------------------------------------------------
        when SM_SEND_SINGLE =>
          state <= SM_SEND_WAIT;
        -----------------------------------------------------
        when SM_SEND_WAIT =>
          if udp_eop = '1' then
            state <= SM_SEND_IDLE;
          end if;
        -----------------------------------------------------
        when others => state <= SM_RESET;
      end case;
    end if;
  end process SM_control;

  -------------------------------------------------------------------------------
  -- Control of the fifo queue of operations
  -------------------------------------------------------------------------------
  queue_control: process (clk) is
  begin  -- process queue_control
    if clk'event and clk = '1' then  -- rising clock edge
      --Pulses
      queue_rd <= '0';
      
      case state is
        -----------------------------------------------------  
        when SM_IDLE =>
          if queue_empty = '0' and queue_rd = '0' then
            queue_rd <= '1';
          end if;
        -----------------------------------------------------  
        when SM_WIB_REG_WAIT_MULT =>
          if queue_data_RW = DIR_WR and wr_ack = '1' then
            queue_rd <= '1'
          end if;
        when others => null;
      end case;
    end if;
  end process queue_control;

  -------------------------------------------------------------------------------
  -- Control of the tx udp module
  -------------------------------------------------------------------------------
  tx_control: process (clk) is
  begin  -- process tx_control
    if clk'event and clk = '1' then  -- rising clock edge
      --pulses
      tx_reset <= '0';

      case state is
        -----------------------------------------------------  
        when SM_RESET =>
          tx_reset <= '1';
        -----------------------------------------------------

        -----------------------------------------------------
        when others => null;
      end case;
    end if;
  end process tx_control;
  
end architecture Behavioral;
