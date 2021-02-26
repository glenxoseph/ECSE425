library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768;
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic; 

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin

-- put your tests here

-- Valid,   Dirty;  Read,   Tag Equal
-- 0        0       0       0   A
-- 0        0       0       1   IMPOSSIBLE
-- 0        0       1       0   B1
-- 0        0       1       1   IMPOSSIBLE
-- 0        1       0       0   IMPOSSIBLE
-- 0        1       0       1   IMPOSSIBLE
-- 0        1       1       0   IMPOSSIBLE
-- 0        1       1       1   IMPOSSIBLE
-- 1        0       0       0   C2
-- 1        0       0       1   B3
-- 1        0       1       0   C1
-- 1        0       1       1   B2
-- 1        1       0       0   B5
-- 1        1       0       1   B4
-- 1        1       1       0   C3
-- 1        1       1       1   A

    reset <= '1';
    s_read <='0';
    s_write <= '0';
    WAIT FOR clk_period;
    reset <= '0';

    WAIT FOR clk_period;

    report "Test A";
-- 0000, Invalid, Clean, Write, Miss
-- brand new cache, everything is invalid/clean/miss

    s_addr <= "11111111111111111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F000A";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';

-- 1111, Valid, Dirty, Read, Hit
-- this was written, so valid/dirty/hit
    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000A" report "Test A FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;
--helper
    s_addr <= "01111111111111111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F00AA";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';
-- x"000F000A" in memory
    WAIT FOR clk_period;

    reset <= '1';
    s_read <='0';
    s_write <= '0';
    WAIT FOR clk_period;
    reset <= '0';
-- reset after this

    report "Test B";
-- 0010, Invalid, Clean, Read, Miss
-- brand new cache, everything is invalid/clean/miss
    s_read <= '1';
    s_addr <= "11111111111111111111111000001111";
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000A" report "Test B1 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- 1011, Valid, Clean, Read, Hit
-- already read, so valid/hit
    s_read <= '1';
    s_addr <= "11111111111111111111111000001111";
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000A" report "Test B2 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- 1001, Valid, Clean, Write, Hit
-- this was read, so valid/hit

    s_addr <= "11111111111111111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F000F";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';

-- 1111, Valid, Dirty, Read, Hit
-- this was written, so dirty

    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000F" report "Test B3 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- 1101, Valid, Dirty, Write, Hit
-- this was written, so dirty

    s_addr <= "11111111111111111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F000E";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';

-- 1111, Valid, Dirty, Read, Hit

    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000E" report "Test B4 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- 1100, Valid, Dirty, Write, Miss
-- this address is written, so valid and dirty, but the tag is missed

    s_addr <= "11111111111110111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F000B";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';

-- 1111, Valid, Dirty, Read, Hit

    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000B" report "Test B5 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- helper
    s_addr <= "01111111111110111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F00BB";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';
-- x"000F000B" should be in memory

    reset <= '1';
    s_read <='0';
    s_write <= '0';
    WAIT FOR clk_period;
    reset <= '0';
-- reset

    WAIT FOR clk_period;

    Report "Test C";

-- 0010, Invalid, Clean, Read, Miss
-- brand new cache, everything is invalid/clean/miss
    s_read <= '1';
    s_addr <= "11111111111110111111111000001111";
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000B" report "Test C FAILED" severity error;
    s_read <= '0';

-- 1010, Valid, Clean, Read, Miss
-- after first read, this address is valid, we use another tag so we miss
    s_read <= '1';
    s_addr <= "11111111111111111111111000001111";
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000E" report "Test C1 FAILED" severity error;
    s_read <= '0';

-- 1000, Valid, Clean, Write, Miss
-- after first read, this address is valid, we use another tag so we miss
    s_addr <= "11111111111100111111111000001111";
    s_write <= '1';
    s_writedata <= x"000F00AA";
    wait until rising_edge(s_waitrequest);
    s_write <= '0';

-- 1111, Valid, Dirty, Read, Hit
    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F00AA" report "Test C2 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

-- 1110, Valid, Dirty, Read, Miss
-- after first read, this address is valid, we use another tag so we miss
    s_addr <= "11111111111111111111111000001111";
    s_read <= '1';
    wait until rising_edge(s_waitrequest);
    assert s_readdata = x"000F000E" report "Test C3 FAILED" severity error;
    s_read <= '0';

    WAIT FOR clk_period;

end process;

end;