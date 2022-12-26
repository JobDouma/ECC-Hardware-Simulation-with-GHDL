----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: modaddn_mult
-- Description: n-bit modular multiplier (through consecutive additions)
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
-- product = b*a mod p
entity modaddn_mult is
    generic(
        n: integer := 4);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        rst, clk, start: in std_logic;
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end modaddn_mult;

-- describe the behavior of the module in the architecture
architecture behavioral of modaddn_mult is

type my_state is (s_idle, s_add, s_done);

signal c, a_reg, p_reg, product_reg: std_logic_vector(n-1 downto 0);
signal state: my_state;
signal ctr: std_logic_vector(n-1 downto 0);
signal enable: std_logic;

component modaddn
	generic(
		n: integer :=8 );
	port(
		a,b,p: in std_logic_vector(n-1 downto 0);
		sum: out std_logic_vector(n-1 downto 0));
end component;

begin

inst_modaddn: modaddn
	generic map(n=>n)
	port map(	a => product_reg,
			b => a_reg,
			p => p_reg,
			sum => c);

reg_product: process(rst, clk)
begin
	if rst = '1'  then
		product_reg <= (others => '0');
	elsif rising_edge(clk) then
		if start = '1' then
			product_reg <= (others => '0');
		else
			product_reg <= c;
		end if;
	end if;
end process;

reg_a_p: process(rst, clk)
begin
	if rst = '1' then
		a_reg <= (others => '0');
		p_reg <= (others => '0');
	elsif rising_edge(clk) and state /= s_done then
		if start = '1' then
			a_reg <= a;
			p_reg <= p;
		end if;
	end if;
end process;
			
counter: process(rst, clk)
begin
	if rst = '1' then
		ctr <= std_logic_vector(to_unsigned(0,n));
	elsif rising_edge(clk) then
		if start = '1' then
			ctr <= std_logic_vector(to_unsigned(0,n));
		elsif enable = '1' then
			ctr <= std_logic_vector(unsigned(ctr)+to_unsigned(1,n));
		end if;
	end if;
end process;

FSM_state: process(rst, clk)
begin
	if rst = '1' then
		state <= s_idle;
	elsif rising_edge(clk) then
		case state is
			when s_idle =>
				if start = '1' then
					state <= s_add;
				end if;
			when s_add =>
				if ctr = std_logic_vector(unsigned(b) - to_unsigned(1, n-1)) then
					state <= s_done;
				end if;
			when others =>
				state <= s_idle;
		end case;
	end if;
end process;

FSM_out: process(state)
begin
	case state is
		when s_idle =>
			enable <= '0';
			done <= '0';
		when s_add =>
			enable <= '1';
			done <= '0';
		when others =>
			enable <= '0';
			done <= '1';
	end case;
end process;

product <= product_reg;

end behavioral;
