----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: tb_ecc_add_double_small 
-- Description: testbench for the ecc_add_double module
----------------------------------------------------------------------------------

-- include the IEEE library and the STD_LOGIC_1164 package for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module: a testbench does not have any inputs or outputs
entity tb_ecc_mont_opt is
    generic(
        n: integer := 256;
        log2n: integer := 3;
ads : integer := 6);
end tb_ecc_mont_opt;

architecture behavioral of tb_ecc_mont_opt is

-- declare and initialize internal signals to drive the inputs of ecc_add_double

constant ecc_prime: std_logic_vector(n-1 downto 0) := X"ffffffff00000001000000000000000000000000ffffffffffffffffffffffff";
constant ecc_a: std_logic_vector(n-1 downto 0) := X"ffffffff00000001000000000000000000000000fffffffffffffffffffffffc";
constant ecc_b: std_logic_vector(n-1 downto 0) := X"5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b";

constant ecc_p1_x: std_logic_vector(n-1 downto 0) := X"6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296";
constant ecc_p1_y: std_logic_vector(n-1 downto 0) := X"4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5";
constant ecc_p1_z: std_logic_vector(n-1 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000001";

constant ecc_s: std_logic_vector(n-1 downto 0) := X"C03A898C5E674B2CE564F25F96BB8AE944985061ACCE54CAA5554BB508542151";

constant ecc_p1_x_smult: std_logic_vector(n-1 downto 0) := X"B586EFD756C25F6BC6469AA162BAC531C877C99DF5CBD8F95EEF31CE74226860";
constant ecc_p1_y_smult: std_logic_vector(n-1 downto 0) := X"8E5C8AAD3B74642DBF40A6851090A6DB6210C97AFE36CCF65300CC2F6514DE66";
constant ecc_p1_z_smult: std_logic_vector(n-1 downto 0) := X"5590FD84B53850234D3CEF495D7DB307470C449A1CA8431F184D4DDDB70B3714";

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
signal sgx, sgy, sgz: std_logic_vector(n-1 downto 0);

-- declare a signal to check if values match.
signal error_comp: std_logic := '0';

-- define the clock period
constant clk_period: time := 10 ns;

-- define signal to terminate simulation
signal testbench_finish: boolean := false;

-- declare the ecc_base component
component ecc_mont_opt
    generic(n: integer := 8;
            log2n: integer := 3;
ads : integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        done: out std_logic;
        p, a, b, gx, gy, gz, s:in std_logic_vector(n-1 downto 0);
        sgx, sgy, sgz:out std_logic_vector(n-1 downto 0));
end component;

begin

-- instantiate the ecc_base component
-- map the generic parameter in the testbench to the generic parameter in the component  
-- map the signals in the testbench to the ports of the component
inst_ecc_mont_opt: ecc_mont_opt
    generic map(n=>n,
            log2n=>log2n,
    ads => ads)
    port map(
        start=>start_i,
        rst=>rst_i,
        clk=>clk_i,
        done=>done_i,
	a => ecc_a,
	b => ecc_b,
	p => ecc_prime,
	gx => ecc_p1_x,
	gy => ecc_p1_y,
	gz => ecc_p1_z,
	s => ecc_s,
	sgx => sgx,
	sgy => sgy,
	sgz => sgz

    );

-- generate the clock with a duty cycle of 50%
gen_clk: process
begin
     while(testbench_finish = false) loop
        clk_i <= '0';
        wait for clk_period/2;
        clk_i <= '1';
        wait for clk_period/2;
     end loop;
     wait;
end process;

-- stimulus process (without sensitivity list, but with wait statements)
stim: process
variable i: integer;
begin
    wait for clk_period;
    
    rst_i <= '0';
    start_i <= '1';
    wait for clk_period;
    -- Fill memory with the ecc constants and points
    -- Perform point addition
    error_comp  <= '0';
    wait until done_i = '1';
    if (sgx /= ecc_p1_x_smult) or (sgy /= ecc_p1_y_smult) or (sgz /= ecc_p1_z_smult) then
	error_comp <= '1';
end if;
	testbench_finish <= true;
	wait;
end process;

end behavioral;
