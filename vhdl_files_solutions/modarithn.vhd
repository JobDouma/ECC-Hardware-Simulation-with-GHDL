----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: modarithn
-- Description: Modular arithmetic unit (multiplication, addition, subtraction)
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
-- product = a*b mod p or a+b mod p or a-b mod p
entity modarithn is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        a: in std_logic_vector(n-1 downto 0);
        b: in std_logic_vector(n-1 downto 0);
        p: in std_logic_vector(n-1 downto 0);
        rst: in std_logic;
        clk: in std_logic;
        start: in std_logic;
        command: in std_logic_vector(1 downto 0);
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);

end modarithn;

architecture behavioral of modarithn is
	signal sum_as, mult_done, mult_start: std_logic;
	signal  sum_product_add, sum_product_sub, mult_product: std_logic_vector(n-1 downto 0);
component modmultn
	generic(
		n: integer := 8;
		log2n: integer := 3);
	port(
		a,b,p: in std_logic_vector(n-1 downto 0);
		rst, clk, start: in std_logic;
		product: out  std_logic_vector(n-1 downto 0);
		done: out std_logic);
end component;

component modaddsubn
	generic(
		n: integer := 8);
	port(
		a,b,p: in std_logic_vector(n-1 downto 0);
		as: in std_logic;
		sum: out std_logic_vector(n-1 downto 0));
end component;


begin
inst_modmultn: modmultn
	generic map(n=>n)
	port map(
			a => a,
			b => b,
			p => p,
			rst => rst,
			clk => clk,
			start => mult_start,
			done => mult_done,
			product => mult_product);
inst_modaddsubn_add: modaddsubn
	generic map(n=>n)
	port map(
		a => a,
		b => b,
		p => p,
		as => '0',
		sum => sum_product_add);

inst_modaddsubn_sub: modaddsubn
	generic map(n=>n)
	port map(
		a => a,
		b => b,
		p => p,
		as => '1',
		sum => sum_product_sub);

	
	mux: process(rst, clk, mult_done, sum_product_add, sum_product_sub, mult_product, start)
	begin
		if rst = '1' or (start = '1' and not (command = std_logic_vector(to_unsigned(1,2)))) then
			done <= '0';
		elsif rising_edge(clk) then
			if command = std_logic_vector(to_unsigned(1,2)) then
				product <= mult_product;
				done <= mult_done;
				mult_start <= start;
			elsif command = std_logic_vector(to_unsigned(2,2)) and start = '0' then
				product <= sum_product_add;
				done <= '1';
				mult_start <= '0';
			elsif command = std_logic_vector(to_unsigned(3,2)) and start = '0' then
				product <= sum_product_sub;
				done <= '1';
				mult_start <= '0';
			end if;
		end if;
	end process;



end behavioral;
