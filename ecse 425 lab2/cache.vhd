library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
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
type STATE_TYPE is (start,read_ready,write_ready,mem_read1,mem_write1,read_state,write_state,read_memwait);
signal state : STATE_TYPE;
type cache_structure is array (0 to 31) of std_logic_vector (152 downto 0);
signal cache_struct : cache_structure := (others=>(others=>'0'));
signal address: std_logic_vector (14 downto 0);
begin

	process (clock, reset,s_read, s_write)
		variable idx : integer range 0 TO 31;
		variable offset : integer range 0 TO 3;
		variable counter : integer range 0 TO 5;
		variable is_read : integer range 0 to 1;
		begin
			--report "begin process";
			if reset = '1' then
				state <= start;
				report "reset";
				cache_struct <= (others=>(others=>'0'));
				-- set to high by default
				s_waitrequest <= '1';
			elsif (rising_edge(clock) and clock = '1') then
				offset := to_integer(unsigned(s_addr(3 downto 2))); -- ignore the last 2 bit of offset
				idx := to_integer(unsigned(s_addr(8 downto 4))); -- 5 bit index
				address <= cache_struct(idx)(133 downto 128)& s_addr (8 downto 0); 
				
			case state is

				when start =>
					report "start";
					s_waitrequest <= '1';
					if s_write = '1' and s_read = '0' then
						report "state <= write_ready";
						is_read := 0;					
						state <= write_ready;
					elsif s_read = '1' and s_write = '0' then
						report "state <= read_ready";
						is_read := 1;	
						state <= read_ready;
					else
						state <= start;

					end if;

				when read_ready =>
					if cache_struct(idx)(152) = '1' and s_addr(31 downto 9) = cache_struct(idx)(150 downto 128) then--read hit
						report "read hit, state <= read_state";
						state <= read_state;
					elsif (cache_struct(idx)(152) = '0' or s_addr(31 downto 9) /= cache_struct(idx)(150 downto 128)) and cache_struct(idx)(151) = '1' then -- read miss,dirty
						report "read miss,dirty ,state <= mem_write1;";
						state <= mem_write1;
					elsif (cache_struct(idx)(152) = '0' or s_addr(31 downto 9) /= cache_struct(idx)(150 downto 128)) and cache_struct(idx)(151) = '0' then -- read miss,clean
						report " read miss,clean ,state <= mem_read1;";
						state <= mem_read1;
					end if;
				when write_ready =>
					if cache_struct(idx)(152) = '1' and s_addr(31 downto 9) = cache_struct(idx)(150 downto 128) then --write hit
						report "write hit,state <= write_state" ;
						state <= write_state;
					elsif (cache_struct(idx)(152) = '0' or s_addr(31 downto 9) /= cache_struct(idx)(150 downto 128)) and cache_struct(idx)(151) = '1' then -- write miss,dirty
						report "write miss,dirty,state <= mem_write1";
						state <= mem_write1;
					elsif (cache_struct(idx)(152) = '0' or s_addr(31 downto 9) /= cache_struct(idx)(150 downto 128)) and cache_struct(idx)(151) = '0' then -- write miss,clean
						 report "write miss,clean, state <= mem_read1";
						state <= mem_read1;
					end if;

				when read_state =>
					report "read state";
					s_readdata <= cache_struct(idx)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset);
					report "s_readdata="&integer'image(to_integer(unsigned(cache_struct(idx)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset))));
					s_waitrequest <= '0';
					state <= start;
					report "finish read";
				when write_state =>
					report "write state";
					cache_struct(idx)(152) <= '1';
					cache_struct(idx)(151) <= '1';
					report "s_addr="&integer'image(to_integer(unsigned(s_addr(14 downto 0))));
					cache_struct(idx)(150 downto 128) <= s_addr(31 downto 9);
					cache_struct(idx)(127 downto 0)((32*(offset + 1)) - 1 downto 32*offset) <= s_writedata;
					report "s_writedata="&integer'image(to_integer(unsigned(s_writedata)));
					report "data in cache after write="&integer'image(to_integer(unsigned(cache_struct(idx)(127 downto 0)((32*(offset + 1)) - 1 downto 32*offset))));
					s_waitrequest <= '0';
					state <= start;

				when mem_write1 => --write data from cache to memory
					report "mem_write1";
					if counter <= 3 and m_waitrequest = '1' then
						report "m_waitrequest = 1, counter < 3";
						
						report "s_addr="&integer'image(to_integer(unsigned(s_addr(14 downto 0))));
						report "counter="&integer'image(counter);
						report "address1="&integer'image(to_integer(unsigned(cache_struct(idx)(133 downto 128))));
						report "address2="&integer'image(to_integer(unsigned(s_addr (8 downto 0))));
						if counter = 0 then 
							m_addr <= to_integer(unsigned(address));
						else 
							m_addr <= to_integer(unsigned(address)) + counter;
						end if;						
						m_write <= '1';
						m_read <= '0';
						m_writedata <= cache_struct(idx)(127 downto 0) ((8*counter + 32*offset + 7) downto  (8*counter + 32*offset));
						report "m_addr="&integer'image(to_integer(unsigned(address)) + counter);
						report "m_writedata=" & integer'image(to_integer(unsigned(cache_struct(idx)(127 downto 0) ((8*counter + 32*offset + 7) downto  (8*counter + 32*offset)))));
						counter := counter + 1;
						state <= mem_write1;
					elsif counter = 4 then
						report "mem_write1,counter = 4";
						counter := 0;
						m_write <= '0';
						state <= mem_read1;
					else	
						report "mem_write1,else";
						m_write <= '0';
						state <= mem_write1;
					end if;

				when mem_read1 => --read data from memory to cache
					report "mem_read1";
					if m_waitrequest = '1' then
						report "mem_read1,m_waitrequest = '1'";
						m_read <= '1';
						m_write <= '0';
						report "s_addr="&integer'image(to_integer(unsigned(s_addr(14 downto 0))));
						m_addr <= to_integer(unsigned(s_addr(14 downto 0)))+ counter ;
						report "m_addr="&integer'image(to_integer(unsigned(s_addr(14 downto 0))) + counter);
						state <= read_memwait;
					else
						state <= mem_read1;
					end if;

				when read_memwait => 
					report "wait mem read";
					
					if m_waitrequest = '0' and counter <= 3 then
						report "wait mem read,m_waitrequest = '0'";
						cache_struct(idx)(127 downto 0) ((8*counter +32*offset + 7) downto (8*counter + 32*offset)) <= m_readdata;
						report "m_readdata="&integer'image(to_integer(unsigned(m_readdata)));
						counter := counter + 1;
						m_read <= '0';
						state <= mem_read1;
					elsif counter = 4 then
						report "wait mem read,counter = 4";
						counter := 0;
						cache_struct(idx)(152) <= '1';
						cache_struct(idx)(151) <= '0';
						report "s_addr="&integer'image(to_integer(unsigned(s_addr(14 downto 0))));
						cache_struct(idx)(150 downto 128) <= s_addr(31 downto 9);
						m_read <= '0';
						m_write <= '0';
						s_waitrequest <= '0';
						if is_read = 1 then 
							state <= read_state;
						elsif is_read = 0 then 
							state <= write_state;
						end if;
					else 
						state <= read_memwait;
					end if;
				end case;

			end if;
		end process;



-- make circuits here

end arch;