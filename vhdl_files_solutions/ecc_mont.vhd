----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: ecc_mont
-- Description: 4-bit adder
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module in the entity
entity ecc_mont is
	generic(
	n: integer := 8;
	log2n: integer := 3;
	ads: integer := 8);
    port(
    	start, clk, rst: in std_logic;
        p, a, b, gx, gy, gz, s: in std_logic_vector(n-1 downto 0);
    	done: out std_logic;
        sgx, sgy, sgz: out std_logic_vector(n-1 downto 0));
end ecc_mont;



-- describe the behavior of the module in the architecture
architecture behavioral of ecc_mont is
	type my_state is (s_idle, s_load_p, s_load_a, s_load_b, s_ctr, s_op1_x0, s_op1_y0, s_op1_z0, s_op1_x1, s_op1_y1, s_op1_z1, s_op1_wait0, s_op1_trigger, s_op1_loop, s_op1_rx, s_op1_ry, s_op1_rz, s_op1_wait1,  s_op2_x, s_op2_y, s_op2_z, s_op2_wait0, s_op2_trigger, s_op2_loop, s_op2_rx, s_op2_ry, s_op2_rz, s_write_result, s_done);
	signal state : my_state;

signal start_i: std_logic := '0';
signal rst_i: std_logic := '1';
signal clk_i: std_logic := '0';
signal add_double_i: std_logic := '0';
signal busy_i: std_logic;
signal done_i: std_logic;
signal m_enable_i: std_logic := '0';
signal m_din_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal m_dout_i: std_logic_vector(n-1 downto 0);
signal m_rw_i: std_logic := '0';
signal m_address_i: std_logic_vector(ads-1 downto 0) := (others => '0');
signal secret : std_logic;

signal r0x, r0y, r0z, r1x, r1y, r1z, op1x, op1y, op1z, op2x, op2y, op2z, muxx, muxy, muxz, counter : std_logic_vector(n-1 downto 0);

	component ecc_add_double
    generic(
        n: integer := n;
        log2n: integer := log2n;
	ads : integer := ads);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        add_double: in std_logic;
        done: out std_logic;
        busy: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(ads-1 downto 0));
end component;
begin
inst_ecc_add_double: ecc_add_double
    generic map(n=>n,
            log2n=>log2n, ads=>ads)
    port map(
        start=>start_i,
        rst=>rst,
        clk=>clk,
        add_double=>add_double_i,
        done=>done_i,
        busy=>busy_i,
        m_enable=>m_enable_i,
        m_din=>m_din_i,
        m_dout=>m_dout_i,
        m_rw=>m_rw_i,
        m_address=>m_address_i
    );

sgx <= r0x;
sgy <= r0y;
sgz <= r0z;

	FSM_execute: process(rst, clk)
	begin
		case state is
			when s_idle =>
				done <= '0';
				r0x <= std_logic_vector(to_unsigned(0,n));
				r0y <= std_logic_vector(to_unsigned(1,n));
				r0z <= std_logic_vector(to_unsigned(0,n));
				counter <= std_logic_vector(to_unsigned(n,n));
			when s_load_p =>
				r1x <= gx;
				r1y <= gy;
				r1z <= gz;
				m_enable_i <= '1';
				m_rw_i <= '1';
				m_din_i <= p;
				m_address_i <= std_logic_vector(to_unsigned(0,ads));
			when s_load_a =>
				m_din_i <= a;
				m_address_i <= std_logic_vector(to_unsigned(1,ads));
			when s_load_b =>
				m_din_i <= b;
				m_address_i <= std_logic_vector(to_unsigned(2,ads));
			when s_ctr =>
				if rising_edge(clk) then
					counter <= std_logic_vector(unsigned(counter)-to_unsigned(1,n));
				end if;
			when s_op1_x0 =>
				m_enable_i <= '1';
				m_rw_i <= '1';
				m_din_i <= r0x;
				m_address_i <= std_logic_vector(to_unsigned(3,ads));
			when s_op1_y0 =>
				m_din_i <= r0y;
				m_address_i <= std_logic_vector(to_unsigned(4,ads));
			when s_op1_z0 =>
				m_din_i <= r0z;
				m_address_i <= std_logic_vector(to_unsigned(5,ads));
			when s_op1_x1 =>
				m_din_i <= r1x;
				m_address_i <= std_logic_vector(to_unsigned(6,ads));
			when s_op1_y1 =>
				m_din_i <= r1y;
				m_address_i <= std_logic_vector(to_unsigned(7,ads));
			when s_op1_z1 =>
				m_din_i <= r1z;
				m_address_i <= std_logic_vector(to_unsigned(8,ads));
			when s_op1_wait0 =>
				m_enable_i <= '0';
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(0,ads));
			when s_op1_trigger =>
				start_i <= '1';
				add_double_i <= '0';
			when s_op1_loop =>
				done <= '0';
				start_i <= '0';
			when s_op1_rx =>
				op1x <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(9,ads));
			when s_op1_ry =>
				op1y <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(10,ads));
			when s_op1_rz =>
				op1z <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(11,ads));
			when s_op1_wait1 =>
				secret <= s(to_integer(signed(counter)));
				done <= '0';
				m_enable_i <= '0';
				if s(to_integer(signed(counter))) = '1' then
					muxx <= r1x;
					muxy <= r1y;
					muxz <= r1z;
				else
					muxx <= r0x;
					muxy <= r0y;
					muxz <= r0z;
				end if;
			when s_op2_x =>
				m_enable_i <= '1';
				m_rw_i <= '1';			
				m_din_i <= muxx;
				m_address_i <= std_logic_vector(to_unsigned(3,ads));
			when s_op2_y =>
				m_din_i <= muxy;
				m_address_i <= std_logic_vector(to_unsigned(4,ads));
			when s_op2_z =>
				m_din_i <= muxz;
				m_address_i <= std_logic_vector(to_unsigned(5,ads));
			when s_op2_wait0 =>
				m_enable_i <= '0';
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(0,ads));
			when s_op2_trigger =>
				start_i <= '1';
				add_double_i <= '1';
			when s_op2_loop =>
				start_i <= '0';
			when s_op2_rx =>
				op2x <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(9,ads));
			when s_op2_ry =>
				op2y <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(10,ads));
			when s_op2_rz =>
				op2z <= m_dout_i;
				m_enable_i <= '1';
				m_din_i <= (others => '0');
				m_rw_i <= '0';
				m_address_i <= std_logic_vector(to_unsigned(11,ads));
			when s_write_result =>
				m_enable_i <= '0';
				if s(to_integer(signed(counter))) = '1' then
					r0x <= op1x;
					r0y <= op1y;
					r0z <= op1z;

					r1x <= op2x;
					r1y <= op2y;
					r1z <= op2z;
				else
					r1x <= op1x;
					r1y <= op1y;
					r1z <= op1z;

					r0x <= op2x;
					r0y <= op2y;
					r0z <= op2z;
				end if;
			when s_done =>
				done <= '1';
					



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
					state <= s_load_a;
				when s_load_a =>
					state <= s_load_b;
				when s_load_b =>
					state <= s_ctr;
				when s_ctr =>
					state <= s_op1_x0;
				when s_op1_x0 =>
					state <= s_op1_y0;
				when s_op1_y0 =>
					state <= s_op1_z0;
				when s_op1_z0 =>
					state <= s_op1_x1;
				when s_op1_x1 =>
					state <= s_op1_y1;
				when s_op1_y1 =>
					state <= s_op1_z1;
				when s_op1_z1 =>
					state <= s_op1_trigger;
				when s_op1_wait0 =>
					state <= s_op1_trigger;
				when s_op1_trigger =>
					state <= s_op1_loop;
				when s_op1_loop =>
					if done_i = '1' then
						state <= s_op1_rx;
					end if;
				when s_op1_rx =>
					state <= s_op1_ry;
				when s_op1_ry =>
					state <= s_op1_rz;
				when s_op1_rz =>
					state <= s_op1_wait1;
				when s_op1_wait1 =>
					state <= s_op2_x;
				when s_op2_x =>
					state <= s_op2_y;
				when s_op2_y =>
					state <= s_op2_z;
				when s_op2_z =>
					state <= s_op2_wait0;
				when s_op2_wait0 =>
					state <= s_op2_trigger;
				when s_op2_trigger =>
					state <= s_op2_loop;
				when s_op2_loop =>
					if done_i = '1' then
						state <= s_op2_rx;
					end if;
				when s_op2_rx =>
					state <= s_op2_ry;
				when s_op2_ry =>
					state <= s_op2_rz;
				when s_op2_rz =>
					state <= s_write_result;
				when s_write_result =>
					if not (counter = std_logic_vector(to_unsigned(0,n))) then
						state <= s_ctr;
					else
						state <= s_done;
					end if;
				when s_done =>
					

			end case;
		end if;
	end process;

end behavioral;
