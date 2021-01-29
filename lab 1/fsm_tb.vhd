LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY fsm_tb IS
END fsm_tb;

ARCHITECTURE behaviour OF fsm_tb IS

COMPONENT comments_fsm IS
PORT (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk, s_reset, s_output: STD_LOGIC := '0';
SIGNAL s_input: std_logic_vector(7 downto 0) := (others => '0');

CONSTANT clk_period : time := 1 ns;
CONSTANT SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
CONSTANT STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
CONSTANT NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";
CONSTANT X : std_logic_vector(7 downto 0) := "01011000";

BEGIN
dut: comments_fsm
PORT MAP(clk, s_reset, s_input, s_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 
--TODO: Thoroughly test your FSM
stim_process: PROCESS
BEGIN    
	--REPORT "Example case, reading a meaningless character";
	--s_input <= "01011000";
	--WAIT FOR 1 * clk_period;
	--ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
	--REPORT "_______________________";
    
	--WAIT;

	--	   X / * X \n / * X * \n * * /
	--output:  0 0 0 1 1  1 1 1 1 1  1 1 1
	--state:   0 1 2 2 2  2 4 2 4 2  4 4 0 
	
	s_reset <= '1';
	WAIT FOR 1 * clk_period;
	s_reset <= '0';
	WAIT FOR 1 * clk_period;

	REPORT "reading meaningless at s0";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character at s0, s0 -> s0, the output should be '0'" SEVERITY ERROR;


	REPORT "reading slash at s0";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a slash at s0, s0 -> s1, the output should be '0'" SEVERITY ERROR;	

	REPORT "reading star at s1";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a star at s1, s1 -> s2, the output should be '0'" SEVERITY ERROR;

	REPORT "reading meaningless at s2";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a meaningless character at s2, s2 -> s2, the output should be '1'" SEVERITY ERROR;

	REPORT "reading new line at s2";
	s_input <= NEW_LINE_CHARACTER; -- new line
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a new line at s2, s2 -> s2, the output should be '1'" SEVERITY ERROR;

	REPORT "reading slash at s2";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a slash at s2, s2 -> s2, the output should be '1'" SEVERITY ERROR;

	REPORT "reading star at s2";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a star at s2, s2 -> s4, the output should be '1'" SEVERITY ERROR;

	REPORT "reading meaningless at s4";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a meaningless character at s4, s4 -> s2, the output should be '1'" SEVERITY ERROR;

	REPORT "reading star at s2";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a star at s2, s2 -> s4, the output should be '1'" SEVERITY ERROR;

	REPORT "reading new line at s4";
	s_input <= NEW_LINE_CHARACTER; -- new line
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a new line at s4, s4 -> s2, the output should be '1'" SEVERITY ERROR;

	REPORT "reading star at s2";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a star at s2, s2 -> s4, the output should be '1'" SEVERITY ERROR;

	REPORT "reading star at s4";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a star at s4, s4 -> s4, the output should be '1'" SEVERITY ERROR;

	REPORT "reading slash at s4";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a slash at s4, s4 -> s0, the output should be '1'" SEVERITY ERROR;
	
	--        * \n / X / \n / / X / * \n
	--output: 0 0  0 0 0  0 0 0 1 1 1 1
	--state:  0 0  1 0 1 0  1 3 3 3 3 0
	--s_reset <= '1';
	--WAIT FOR 1 * clk_period;
	--s_reset <= '0';
	--WAIT FOR 1 * clk_period;

	REPORT "reading star at s0";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a star at s0, s0 -> s0, the output should be '0'" SEVERITY ERROR;

	REPORT "reading new line at s0";
	s_input <= NEW_LINE_CHARACTER; -- new line
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a new line at s0, s0 -> s0, the output should be '0'" SEVERITY ERROR;

	REPORT "reading slash at s0";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a slash at s0, s0 -> s1, the output should be '0'" SEVERITY ERROR;

	REPORT "reading meaningless at s1";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character at s1, s1 -> s0, the output should be '0'" SEVERITY ERROR;

	REPORT "reading slash at s0";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a slash at s0, s0 -> s1, the output should be '0'" SEVERITY ERROR;

	REPORT "reading new line at s1";
	s_input <= NEW_LINE_CHARACTER; -- new line
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a new line at s1, s1 -> s0, the output should be '0'" SEVERITY ERROR;

	REPORT "reading slash at s0";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a slash at s0, s0 -> s1, the output should be '0'" SEVERITY ERROR;

	REPORT "reading slash at s1";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a slash at s1, s1 -> s3, the output should be '0'" SEVERITY ERROR;

	REPORT "reading meaningless at s3";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a meaningless character at s3, s3 -> s3, the output should be '1'" SEVERITY ERROR;

	REPORT "reading slash at s3";
	s_input <= SLASH_CHARACTER; -- slash
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a slash at s3, s3 -> s3, the output should be '1'" SEVERITY ERROR;

	REPORT "reading star at s3";
	s_input <= STAR_CHARACTER; -- star
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a star at s3, s3 -> s3, the output should be '1'" SEVERITY ERROR;

	REPORT "reading new line at s3";
	s_input <= NEW_LINE_CHARACTER; -- new line
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a new line at s3, s3 -> s0, the output should be '1'" SEVERITY ERROR;
	
	REPORT "all tests completed";
    
	WAIT;

END PROCESS stim_process;
END;
