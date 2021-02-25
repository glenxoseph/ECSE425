library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
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
end cache;

architecture arch of cache is

-- declare signals here
type STATE_TYPE is (start,read_ready,write_ready,mem_read1,mem_write1,mem_read2,mem_write2,read_sate,write_state,mem_wait);
signal state : STATE_TYPE;
signal next_state: STATE_TYPE;
type cache_struct is array (0 to 31) of std_logic_vector (152 downto 0)

begin

	process (clock, reset, s_write, s_read)
		begin 
			if reset = '1' then 
				state <= start;
			elsif (rising_edge(clock) and clock = '1') then 
				state <= next_state;
			end if;
		end process

	process (state,m_waitrequest,s_read,s_write)
		variable idx : integer;
		variable offset : integer := 0;
		variable counter : integer := 0;
		variable address : std_logic_vector (14 downto 0);
		variable adr_tag : std_logic_vector (22 downto 0);
		variable cache_tag : std_logic_vector (22 downto 0);
		begin 
			offset := to_integer(unsigned(s_addr(3 downto 2))); -- ignore the last 2 bit of offset
			idx := to_integer(unsigned(s_addr(8 downto 4))); -- 5 bit index
			adr_tag = to_integer(unsigned(s_addr(31 downto 9))); -- 23 bit tag
			cache_tag = to_integer(unsigned(cache_struct(idx)(150 downto 128)));
			
			case state is 
		
				when start => 
					s_waitrequest <= '1';
					if s_write = '1' then 
						next_state <= write_ready;
					elsif s_read = '1' then 
						next_state <= read_ready;
					else 
						next_state <= start;
					end if;

				when read_ready => 
					if cache_struct(idx)(152) = '1' and adr_tag = cache_tag then--read hit
						next_state <= read_state;
					elsif (cache_struct(idx)(152) = '0' or adr_tag /= cache_tag) and cache_struct(idx)(151) = '1' then -- read miss,dirty 
						next_state <= mem_write1;
					elsif (cache_struct(idx)(152) = '0' or adr_tag /= cache_tag) and cache_struct(idx)(151) = '0' then -- read miss,clean
						next_state <= mem_read1;
					end if;
				when write_ready => 
					if cache_struct(idx)(152) = '1' and adr_tag = cache_tag then --write hit
						next_state <= write_state;
					elsif (cache_struct(idx)(152) = '0' or adr_tag /= cache_tag) and cache_struct(idx)(151) = '1' then -- write miss,dirty 
						next_state <= mem_write2;
					elsif (cache_struct(idx)(152) = '0' or adr_tag /= cache_tag) and cache_struct(idx)(151) = '0' then -- write miss,clean
						next_state <= mem_read2;
					end if;

				when read_state => 
					s_readdata <= cache_struct(idx)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset);
					s_waitrequest <= '0';
					next_state <= start;

				when write_state => 
					cache_struct(idx)(152) <= '1';
					cache_struct(idx)(151) <= '1';
					cache_struct(idx)(150 downto 128) <= s_addr(31 downto 9);
					cache_struct(idx)(127 downto 0)((32*(offset + 1)) - 1 downto 32*offset) <= s_writedata;
					s_waitrequest <= '0';
					next_state <= start;

				when mem_write1 => --write data from cache to memory
					if counter <= 3 and m_waitrequest = '1' then 
						address := cache_struct(idx)(133 downto 128) & s_addr (8 downto 0);
						m_addr <= to_integer(unsigned(address)) + counter;
						m_write <= '1';
						m_read <= '0';
						m_writedata <= cache_struct(idx)(127 downto 0) ((8*count + 32*offset + 7) downto  (8*count + 32*offset));
						counter := counter + 1;
						next_state <= mem_write1;
					elsif counter = 4 then 
						counter := '0';
						m_write <= '0';
						next_state <= mem_read1;
					else	
						next_state <= mem_write1;
					end if;
				when mem_read1 => --read data from memory to cache
					if m_waitrequest = '1' then 
						m_read <= '1';
						m_write <= '0';
						m_addr <= to_integer(unsigned(s_addr(14 downto 0))) + counter;
						next_state <= mem_read1;
					elsif m_waitrequest = '0' and counter <= 3 then  
						cache_struct(idx)(127 downto 0) ((8*count + 32*offset + 7) downto (8*count + 32*offset)) <= m_readdata;	
						counter := counter + 1;
						next_state <= mem_read1;
					elsif counter = 4 then 
						counter := 0;
						cache_struct(idx)(152) <= '1';
						cache_struct(idx)(151) <= '0';
						cache_struct(idx)(150 downto 128) <= adr_tag;
						m_read <= '0';
						m_write <= '0';
						next_state <= read_state;
					else 
						next_state <= mem_read1;
					end if;
					
										
						

	end process



-- make circuits here

end arch;