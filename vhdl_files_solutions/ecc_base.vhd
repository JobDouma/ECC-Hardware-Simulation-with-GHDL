----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: ecc_base
-- Description: Base unit that is able to run all necessary commands.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

entity ecc_base is
    generic(
        n: integer := 8;
        log2n: integer := 3;
        ads: integer := 8);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        oper_a: in std_logic_vector(ads-1 downto 0);
        oper_b: in std_logic_vector(ads-1 downto 0);
        oper_o: in std_logic_vector(ads-1 downto 0);
        command: in std_logic_vector(2 downto 0);
        busy: out std_logic;
        done: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(ads-1 downto 0));
end ecc_base;

-- describe the behavior of the module in the architecture
architecture behavioral of ecc_base is

type my_state is (s_idle, s_wait_ram, s_load_p, s_load_arith, s_comp_arith, s_write_arith, s_done, s_done2);
signal state: my_state;
signal free, rw, enable, a_start, p_enable, a_done, mux_enable_out, mux_rw_out: std_logic;

signal reduced_command: std_logic_vector(1 downto 0);
signal reg_comm: std_logic_vector(2 downto 0);
signal reg_oper_o, reg_oper_a, reg_oper_b, mux_oper_o_a_m_out, mux_oper_o_a_out: std_logic_vector(ads-1 downto 0);
signal p, a, b, product, reg_product_out , mux_din_out: std_logic_vector(n-1 downto 0);
signal mult_product, sum_product_add, sum_product_sub, load_p: std_logic_vector(n-1 downto 0);

type ramtype is array(integer range<>) of std_logic_vector((n-1) downto 0);
signal memory_ram: ramtype(0 to (2**ads-1));
	
component modarithn
generic(
		n: integer := 8;
		log2n: integer := 3);
		port(
		command: in std_logic_vector(1 downto 0);
		a,b,p: in std_logic_vector(n-1 downto 0);
		rst, clk, start: in std_logic;
		product: out std_logic_vector(n-1 downto 0);
		done: out std_logic);
end component;

component ram_double
 generic( 
        ws: integer := 8;
        ads: integer := 8);
    port(
        enable: in std_logic;
        clk: in std_logic;
        din_a: in std_logic_vector((ws - 1) downto 0);
        address_a: in std_logic_vector((ads - 1) downto 0);
        address_b: in std_logic_vector((ads - 1) downto 0);
        rw: in std_logic;
        dout_a: out std_logic_vector((ws - 1) downto 0);
        dout_b: out std_logic_vector((ws - 1) downto 0));
end component;

begin
reduced_command <= command(1 downto 0);
m_dout <= a;
inst_ram: ram_double
generic map(ads=>ads, ws=>n)
port map( 
			address_a => mux_oper_o_a_m_out,
			address_b => reg_oper_b,
			enable => mux_enable_out,
			din_a => mux_din_out,
			rw => mux_rw_out,
			clk => clk,
			dout_a => a,
			dout_b => b);
			
inst_modarith: modarithn
generic map(n=>n, log2n => log2n)
port map(start => a_start,
			clk => clk,
			rst => rst,
			command => reduced_command,
			p => p,
			a => a,
			b => b,
			done => a_done,
			product => product);
			
			
reg_command: process(start, clk)
begin
	if start = '1' then
		if rising_edge(clk) then
			reg_comm <= command;
		end if;
	end if;
end process;

reg_p: process(p_enable, clk)
begin
	if p_enable = '1' then
	
			p <= b;
	
	end if;
	
end process;

reg_o: process(start, clk)
begin
	if start = '1' then
		if rising_edge(clk) then
			reg_oper_o <= oper_o;
		end if;
	end if;
end process;

reg_a: process(start, clk)
begin
	if start = '1' then
		if rising_edge(clk) then
			reg_oper_a <= oper_a;
		end if;
	end if;
end process;

reg_b: process(start, clk)
begin
	if start = '1' then
		if rising_edge(clk) then
			reg_oper_b <= oper_b;
		end if;
	end if;
end process;

reg_product: process(a_done, clk)
begin
	if a_done = '1' then
		if rising_edge(clk) then
			reg_product_out <= product;
		end if;
	end if;
end process;

mux_oper_o_a: process(rw, reg_oper_o, reg_oper_a)
begin
	if rw = '1' then
		mux_oper_o_a_out <= reg_oper_o;
	else
		mux_oper_o_a_out <= reg_oper_a;
	end if;
end process;

mux_free: process(free, mux_oper_o_a_out, m_address)
begin
	if free = '0' then
		mux_oper_o_a_m_out <= mux_oper_o_a_out;
	else
		mux_oper_o_a_m_out <= m_address;
	end if;
end process;

mux_din: process(clk, free, reg_product_out, m_din)
begin
	if free = '0' then
		mux_din_out <= reg_product_out;
	else
		mux_din_out <= m_din;
	end if;
end process;

mux_rw: process(free, rw, m_rw)
begin
	if free = '0' then
		mux_rw_out <= rw;
	else
		mux_rw_out <= m_rw;
	end if;
end process;

mux_enable: process(free, enable, m_enable)
begin
	if free = '0' then
		mux_enable_out <= enable;
	else
		mux_enable_out <= m_enable;
	end if;
end process;
				

reg_out: process(state)
begin
	case state is
		when s_idle =>
			free <= '1';
			done <= '0';
			rw <= '0';
			enable <= '0';
			a_start <= '0';
			p_enable <= '0';
		when s_wait_ram =>
			free <= '0';
			done <= '0';
			rw <= '0';
			enable <= '1';
			a_start <= '0';
			p_enable <= '0';
		when s_load_p =>
			free <= '0';
			done <= '1';
			rw <= '0';
			enable <= '1';
			a_start <= '0';
			p_enable <= '1';
		when s_load_arith =>
			free <= '0';
			done <= '0';
			rw <= '0';
			enable <= '1';
			a_start <= '1';
			p_enable <= '0';
		when s_comp_arith =>
			free <= '0';
			done <= '0';
			rw <= '0';
			enable <= '0';
			a_start <= '0';
			p_enable <= '0';
		when s_write_arith =>
			free <= '0';
			done <= '0';
			rw <= '1';
			enable <= '1';
			a_start <= '0';
			p_enable <= '0';
		when s_done =>
			free <= '0';
			done <= '0';
			rw <= '1';
			enable <= '1';
			a_start <= '0';
			p_enable <= '0';
		when s_done2 =>
			free <= '0';
			done <= '1';
			rw <= '0';
			enable <= '1';
			a_start <= '0';
			p_enable <= '0';
	end case;
end process;

reg_state: process(rst, clk)
begin
	if rst = '1' then
		state <= s_idle;
	elsif rising_edge(clk) then
		case state is
			when s_idle =>
				if start = '1' then
					state <= s_wait_ram;
				else
					state <= s_idle;
				end if;
			when s_wait_ram =>
				if reg_comm(2) = '1' then
					state <= s_load_p;
				else 
					state <= s_load_arith;
				end if;		
			when s_load_p =>
				state <= s_idle;
			when s_load_arith =>
				state <= s_comp_arith;
			when s_comp_arith =>
				if a_done = '0' then
					state <= s_comp_arith;
				else
					state <= s_write_arith;
				end if;
			when s_write_arith =>
				state <= s_done;
			when s_done =>
				state <= s_done2;
			when s_done2 =>
				state <= s_idle;
		end case;
	end if;
end process;

busy <= not(free);
end behavioral;