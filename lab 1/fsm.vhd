library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-- Do not modify the port map of this structure
entity comments_fsm is
port (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
end comments_fsm;

architecture behavioral of comments_fsm is

-- The ASCII value for the '/', '*' and end-of-line characters
constant SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
constant STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
constant NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

type STATE_TYPE is (s0, s1, s2, s3, s4);
signal state : STATE_TYPE;

begin

-- Insert your processes here
process (clk, reset)
begin
  if reset = '1' then
    state <= s0;

  elsif (clk'event and clk = '1') then
    case state is 
      when s0 => 
	if input = SLASH_CHARACTER then
	  state <= s1;
	  output <= '0';
	else  
	  state <= s0;
	  output <= '0';
	end if;
      when s1 => 
	if input <= STAR_CHARACTER then 
	  state <= s2;
	  output <= '0';
	elsif input <= SLASH_CHARACTER then 
	  state <= s3;
	  output <= '0';
	else
	  state <= s0;
	  output <= '0';
	end if;
      when s2 => 
	if input = STAR_CHARACTER then 
	  state <= s4;
	  output <= '1';
	else 
	  state <= s2;
	  output <= '1';
	end if;
      when s3 => 
	if input = NEW_LINE_CHARACTER then 
	  state <= s0;
	  output <= '1';
	else
	  state <= s3;
	  output <= '1';
	end if; 
      when s4 => 
	if input = STAR_CHARACTER then 
	  state <= s4;
	  output <= '1';
	elsif input = SLASH_CHARACTER then
	  state <= s0;
	  output <= '1';
	else 
	  state <= s2;
	  output <= '1';
	end if;
      end case;
    end if;


end process;

end behavioral;