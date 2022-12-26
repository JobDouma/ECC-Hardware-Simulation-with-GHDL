----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- 
-- Author: Job Douma
--  
-- Module Name: addn
-- Description: add n
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module in the entity, including the parameter n (initialized to 4) that determines the width of the inputs and output
entity addn is
    generic(
        n: integer := 4);
    port(
        a, b: in std_logic_vector(n-1 downto 0);
        sum: out std_logic_vector(n downto 0));
end addn;

-- describe the behavior of the module in the architecture
architecture behavioral of addn is

-- declare internal signals
signal a_long, b_long: std_logic_vector(n downto 0);

begin

-- extend a and b with one bit because the "+" operator expects the inputs and output to be of equal length 
a_long <= '0' & a;
b_long <= '0' & b;

-- add two binary numbers
-- you have to explicitly transform into unsigned, therefore the tool knows the number representation.
-- after converting to unsigned, it is necessary to convert to back to std_logic_vector also explicitly.
sum <= std_logic_vector(unsigned(a_long) + unsigned(b_long));

end behavioral;