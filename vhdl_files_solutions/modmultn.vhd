----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: modmultn
-- Description: n-bit modular multiplier (through the left-to-right double-and-add algorithm)
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
-- product = b*a mod p
entity modmultn is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        rst, clk, start: in std_logic;
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end modmultn;

-- describe the behavior of the module in the architecture
architecture behavioral of modmultn is

type my_state is (s_idle, s_loop, s_done);
signal state: my_state;
-- declare internal signals
signal a_reg, b_reg, p_reg, s_reg, s, c, mux_out: std_logic_vector(n-1 downto 0);
signal ctr: std_logic_vector(n-1 downto 0);
signal shift, b_left, enabled: std_logic;


component modaddn
	generic(
		n: integer := 8);
	port(
		a,b,p: in std_logic_vector(n-1 downto 0);
		sum: out std_logic_vector(n-1 downto 0));
end component;

begin

inst_modaddn_1: modaddn
	generic  map(n=>n)
	port map(	a => s_reg,
			b => s_reg,
			p => p_reg,
			sum => s);

inst_modaddn_2: modaddn
	generic  map(n=>n)
	port map(	a => s,
			b => mux_out,
			p => p_reg,
			sum => c);

mux: process(b_left, clk)
begin
	if b_left = '1' then
		mux_out <= a_reg;
	else
		mux_out <= (others => '0');
	end if;
end process;


-- store the inputs 'a', 'b' and 'p' in the registers 'a_reg', 'b_reg' and 'p_reg', respectively, if start = '1'
-- the registers have an asynchronous reset
-- rotate the content of 'b_reg' one position to the left if shift = '1'
reg_a_b_p: process(rst, clk)
begin
	if rst = '1' then
		a_reg <= (others => '0');
		b_reg <= (others => '0');
		p_reg <= (others => '0');
		s_reg <= (others => '0');

    elsif rising_edge(clk) then
        if enabled = '0' then
            a_reg <= a;
            b_reg <= b;
            p_reg <= p;
	    s_reg <= (others => '0');
    	else
	    s_reg <= c;
            b_reg <= b_reg(n-2 downto 0) & b_reg(n-1);
        end if;
    end if;
end process;

ctr_inc: process(rst, clk)
begin
	if rising_edge(clk) then
		if enabled = '1' then
			ctr <= std_logic_vector(unsigned(ctr)+to_unsigned(1,n));
		else
			ctr <= std_logic_vector(to_unsigned(0,n));
		end if;
	end if;
end process;

output: process(rst, clk)
begin
	case state is
		when s_idle =>
			done <= '0';
			enabled <= '0';
		when s_loop =>
			enabled <= '1';
			done <= '0';
		when s_done =>
			enabled <= '0';
			done <= '1';
	end case;
end process;


product <= s_reg;
b_left <= b_reg(n-1);

FSM_state: process(rst, clk)
begin
	if rst = '1' then
		state <= s_idle;
	elsif rising_edge(clk) then
		case state is
			when s_idle =>
				if start = '1' then
					state <= s_loop;
				end if;
			when s_loop =>
				if ctr = std_logic_vector(to_unsigned(n-1,n)) then
					state <= s_done;
				end if;
			when others =>
				state <= s_idle;
		end case;
	end if;
end process;

end behavioral;
