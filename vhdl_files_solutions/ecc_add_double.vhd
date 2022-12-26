----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- 
-- Author: Job Douma
--  
-- Module Name: ecc_add_double
-- Description: 
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
entity ecc_add_double is
    generic( 
        n: integer := 8;
		log2n: integer := 3;
        ads: integer := 8);
    port(
        start: in std_logic;
        clk: in std_logic;
        rst: in std_logic;
		add_double: in std_logic;
		m_enable: in std_logic;
		m_din: in std_logic_vector((n - 1) downto 0);
		m_rw: in std_logic;
		m_address: in std_logic_vector((ads - 1) downto 0);
		done: out std_logic;
		busy: out std_logic;
        m_dout: out std_logic_vector((n - 1) downto 0));
end ecc_add_double;
    
architecture behavioral of ecc_add_double is
	type ramtype_ads is array(integer range<>) of std_logic_vector(ads-1 downto 0);
	type ramtype_command is array(integer range<>) of std_logic_vector(2 downto 0);
	type my_state is (s_idle, s_load_p, s_load_p_wait, s_fetch, s_execute, s_execute_wait, s_done);
	signal state: my_state;
	signal start_base, done_base: std_logic;
	signal command: std_logic_vector(2 downto 0);
	signal oper_a, oper_b, oper_o: std_logic_vector(ads-1 downto 0);
	signal instpointer: std_logic_vector(n-1 downto 0);
	signal memory_add_a, memory_add_b, memory_add_o: ramtype_ads(0 to 43);
	signal memory_add_command: ramtype_command(0 to 43);
	signal memory_double_a, memory_double_b, memory_double_o: ramtype_ads(0 to 34);
	signal memory_double_command: ramtype_command(0 to 34);

component ecc_base
generic(
		n: integer := 8;
        log2n: integer := 3;
        ads: integer := 8);
	port(
		start, rst, clk, m_enable, m_rw: in std_logic;
		oper_a, oper_b, oper_o: in std_logic_vector(ads-1 downto 0);
		command: in std_logic_vector(2 downto 0);
        m_din:in std_logic_vector(n-1 downto 0);
        m_address:in std_logic_vector(ads-1 downto 0);
		busy, done: out std_logic;
		m_dout: out std_logic_vector(n-1 downto 0));

end component;

begin

inst_ecc_base: ecc_base
generic map(ads=>ads, log2n => log2n, n=>n)
port map(
		start => start_base,
		rst => rst,
		m_enable => m_enable,
		m_din => m_din,
		m_rw => m_rw,
		m_address => m_address,
		clk => clk,
		oper_a => oper_a,
		oper_b => oper_b,
		oper_o => oper_o,
		command => command,
		m_dout => m_dout,
	done=> done_base);



FSM_execute: process(rst, clk)
begin
	case state is
		when s_idle =>
			start_base <= '0';
			busy <= '0';
			instpointer <=  (others => '0');
			done <= '0';
		when s_load_p =>
			start_base <= '1';
			command <= std_logic_vector(to_unsigned(4,3));
			oper_a <= std_logic_vector(to_unsigned(0,ads));
			oper_b <= std_logic_vector(to_unsigned(0,ads));
			oper_o <= std_logic_vector(to_unsigned(0,ads));
			busy <= '1';
		when s_load_p_wait =>
			start_base <= '0';
		when s_fetch =>
			start_base <='1';
			if add_double = '0' then
				oper_a <= memory_add_a(to_integer(to_01(unsigned(instpointer))));
				oper_b <= memory_add_b(to_integer(to_01(unsigned(instpointer))));
				oper_o <= memory_add_o(to_integer(to_01(unsigned(instpointer))));
				command <= memory_add_command(to_integer(to_01(unsigned(instpointer))));
			else
				oper_a <= memory_double_a(to_integer(to_01(unsigned(instpointer))));
				oper_b <= memory_double_b(to_integer(to_01(unsigned(instpointer))));
				oper_o <= memory_double_o(to_integer(to_01(unsigned(instpointer))));
				command <= memory_double_command(to_integer(to_01(unsigned(instpointer))));
			end if;
		when s_execute =>
			start_base <= '0';
		when s_execute_wait =>
			start_base <= '0';
			if rising_edge(clk) then
				instpointer <= std_logic_vector(unsigned(instpointer)+to_unsigned(1,n));
			end if;
		when s_done =>
			done <= '1';
			busy <= '0';
	end case;
end process;


FSM_state: process(rst, clk)
begin
	if rst = '1' then
		state <= s_idle;
	elsif rising_edge(clk) then
		case state is
			when s_idle =>
				if start = '1' then
					state <= s_load_p;
				end if;
			when s_load_p => 
				if done_base = '1' then
					state <= s_load_p_wait;
				end if;
			when s_load_p_wait =>
				state <= s_fetch;
			when s_fetch =>
				state <= s_execute;
			when s_execute =>
				if done_base = '1' then
					state <= s_execute_wait;
				end if;
			when s_execute_wait =>
				if add_double = '0' then
					if instpointer = std_logic_vector(to_unsigned(42,n)) then
						state <= s_done;
					else
						state <= s_fetch;
					end if;
				else
					if instpointer = std_logic_vector(to_unsigned(33,n)) then
						state <= s_done;
					else
						state <= s_fetch;
					end if;
				end if;

			when s_done =>
				state <= s_idle;
		end case;
	end if;
end process;


--- Addition formula
memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); --t0 = x1*x2
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(6,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(4,ads)); --t1 = y1*y2
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(7,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(5,ads)); --t2 = z1*z2
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(8,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); --t3 = x1+y1
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(4,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(6,ads)); --t4 = x2+y2
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(7,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(15,ads)); --t3 = t3*t4
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); --t4 = t0+t1
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(15,ads)); --t3 = t3-t4;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(4,ads)); --t4 = y1+z1;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(5,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(7,ads)); -- t5 = Y2+Z2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(8,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t4 = t4*t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t5 = t1+t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t4 = t4-t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); -- t5 = X1+Z1;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(5,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(6,ads)); -- t6 = X2+Z2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(8,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t5 = t5*t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t6 = t0+t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t6 = t5-t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(2,ads)); -- t7 = b*t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t5 = t6-t7;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t7 = t5+t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t5 = t5+t7;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t7 = t1-t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t5 = t1+t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(2,ads)); -- t6 = b*t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t1 = t2+t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t2 = t1+t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6-t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6-t0;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t1 = t6+t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t6 = t1+t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t1 = t0+t0;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t0 = t1+t0;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t0 = t0-t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(34,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t1 = t4*t6
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(34,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(34,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(34,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(35,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t2 = t0*t6;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(35,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(35,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(35,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(36,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t6 = t5*t7;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(36,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(36,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(36,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(37,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- Y3 = t6+t2;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(37,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(37,ads)))))) <= std_logic_vector(to_unsigned(10,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(37,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(38,ads)))))) <= std_logic_vector(to_unsigned(15,ads)); -- t5 = t3*t5;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(38,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(38,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(38,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(39,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- X3 = t5-t1;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(39,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(39,ads)))))) <= std_logic_vector(to_unsigned(9,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(39,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(40,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t7 = t4*t7;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(40,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(40,ads)))))) <= std_logic_vector(to_unsigned(19,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(40,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(41,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t1 = t3*t0;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(41,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(41,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(41,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_add_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(42,ads)))))) <= std_logic_vector(to_unsigned(19,ads)); -- Z3 = t7+t1;
memory_add_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(42,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_add_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(42,ads)))))) <= std_logic_vector(to_unsigned(11,ads));
memory_add_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(42,ads)))))) <= std_logic_vector(to_unsigned(2,3));


--- Doubling formula
memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); -- t0 = X1*X1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(3,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(0,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(4,ads)); -- t1 = Y1*Y1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(4,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(1,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(5,ads)); -- t2 = Z1*Z1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(5,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(2,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); -- t3 = X1*Y1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(4,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(3,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(15,ads)); -- t3 = t3+t3;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(4,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(3,ads)); -- t6 = X1*Z1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(5,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(5,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6+t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(6,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(2,ads)); -- t5 = b*t2;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(7,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t5 = t5-t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(8,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- t4 = t5+t5;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(9,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t5 = t4+t5;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(10,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t4 = t1-t5;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(11,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(13,ads)); -- t5 = t1+t5;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(12,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t5 = t4*t5;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(17,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(13,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- t4 = t4*t3;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(16,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(14,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t3 = t2+t2;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(15,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t2 = t2+t3;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(16,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(2,ads)); -- t6 = b*t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(17,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6-t2;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(18,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6-t0;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(19,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t3 = t6+t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(20,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6+t3;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(21,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t3 = t0+t0;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(15,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(22,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(15,ads)); -- t0 = t3+t0;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(23,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t0 = t0-t2;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(24,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(12,ads)); -- t0 = t0*t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(25,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(4,ads)); -- t2 = Y1*Z1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(5,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(26,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t2 = t2+t2;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(14,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(27,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(17,ads)); -- Y3 = t5+t0;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(12,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(10,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(28,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t6 = t2*t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(29,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(16,ads)); -- X3 = t4-t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(9,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(30,ads)))))) <= std_logic_vector(to_unsigned(3,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(14,ads)); -- t6 = t2*t1;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(13,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(31,ads)))))) <= std_logic_vector(to_unsigned(1,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- t6 = t6+t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(32,ads)))))) <= std_logic_vector(to_unsigned(2,3));

memory_double_a(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(18,ads)); -- Z3 = t6+t6;
memory_double_b(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(18,ads));
memory_double_o(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(11,ads));
memory_double_command(to_integer(to_01(unsigned(std_logic_vector(to_unsigned(33,ads)))))) <= std_logic_vector(to_unsigned(2,3));
end behavioral;
