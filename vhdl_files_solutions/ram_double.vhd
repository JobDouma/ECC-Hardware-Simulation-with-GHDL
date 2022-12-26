----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial  
-- 
-- Author: Job Douma
--  
-- Module Name: ram_double
-- Description: RAM memory with variable word size and depth.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
entity ram_double is
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
end ram_double;
    
-- describe the behavior of the module in the architecture
architecture behavioral of ram_double is
	type ramtype is array(integer range<>) of std_logic_vector((ws-1) downto 0);
	signal memory_ram: ramtype(0 to (2**ads-1));
begin
	process(clk, address_a, address_b)
	begin
		if enable = '1' then
		dout_a <= memory_ram(to_integer(to_01(unsigned(address_a))));
		dout_b <= memory_ram(to_integer(to_01(unsigned(address_b))));
	end if;
		if rising_edge(clk) then
			if enable = '1' then
				--dout_a <= memory_ram(to_integer(to_01(unsigned(address_a))));
				--dout_b <= memory_ram(to_integer(to_01(unsigned(address_b))));
				if rw = '1' then
					memory_ram(to_integer(to_01(unsigned(address_a)))) <= din_a;
				end if;
			end if;
		end if;
	end process;
end behavioral;
