----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.01.2021 20:01:40
-- Design Name: 
-- Module Name: fir - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
-- use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fir is
 generic (
     FILTER_ORDER : integer := 7;
     INPUT_RESOLUTION : integer := 8;
     OUTPUT_RESOLUTION : integer := 15; -- how to parametrise to INPUT_RESOLUTION*2-1 ?
                                        -- maybe during component initialization in testbench?
     b0 : integer := 0;
     b1 : integer := 0;
     b2 : integer := 0;
     b3 : integer := 0;
     b4 : integer := 0;
     b5 : integer := 0;
     b6 : integer := 0;
     b7 : integer := 0
     -- b8... etc : integer := 0, may pre-allocate more zero coefficients to increase flexibility
 );
 
 Port (
     clk: in std_logic;
     data_in: in signed(INPUT_RESOLUTION-1 downto 0);
     data_out: out signed(OUTPUT_RESOLUTION-1 downto 0);
     en: in std_logic;
     start: in std_logic;
     reset: in std_logic
 );
end fir;

architecture Behavioral of fir is

constant max_res: integer := (INPUT_RESOLUTION*2)-1; -- need to think of proper formula for maximum resolution as due to summation of 8 samples into one signal there may be more than 1 overflow
                                                     -- right now it has been set more or less experimentally

type samples_reg is array (0 to FILTER_ORDER) of signed(INPUT_RESOLUTION-1 downto 0);
type coeffs_reg is array (0 to FILTER_ORDER) of signed(INPUT_RESOLUTION-1 downto 0);

begin

process(clk, reset)
    
    variable samples: samples_reg := (others => (others => '0'));
    variable coeffs: coeffs_reg := (to_signed(b0,INPUT_RESOLUTION),
                                    to_signed(b1,INPUT_RESOLUTION),
                                    to_signed(b2,INPUT_RESOLUTION),
                                    to_signed(b3,INPUT_RESOLUTION),
                                    to_signed(b4,INPUT_RESOLUTION),
                                    to_signed(b5,INPUT_RESOLUTION),
                                    to_signed(b6,INPUT_RESOLUTION),
                                    to_signed(b7,INPUT_RESOLUTION)
                                    );
    
    variable data_processed: signed(max_res downto 0) := (others => '0');  

    -- signal s1 : signed(47 downto 0) := 48D"46137344123";
    
    begin    
    
    if reset = '1' then
         data_out <= (others => '0');
         samples := (others => (others => '0'));
         data_processed := (others => '0');

    -- synch part
    elsif rising_edge(clk) then
        if en = '1' then
        
            if start = '1' then
            
                -- draw sample in new cycle
                samples(0) := data_in;
                
                -- this has to be cleaned before new cycle or it'll add to previous filter output
                data_processed := (others => '0');
                
                -- actual FIR part
                for j in 0 to FILTER_ORDER loop
                    data_processed := data_processed + samples(j)*coeffs(j);
                end loop;
                
                -- output truncated data
                data_out <= data_processed(OUTPUT_RESOLUTION-1 downto 0);
                
                -- shifting sample registers
                for i in FILTER_ORDER downto 1 loop
                    samples(i) := samples(i-1);
                end loop;
                
            else
                samples := (others => (others => '0'));
                data_out <= (others => '0');
                
            end if;
            
        end if;
    end if;
    
 end process;


end Behavioral;
