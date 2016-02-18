LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

 ENTITY lab4b_tb IS
 END lab4b_tb;

ARCHITECTURE behavior OF lab4b_tb IS 

   signal Clk:      std_logic   := '0';  -- no reset
   signal Start:    std_logic   := '0';  -- no reset
   signal Din:      INTEGER     := 0;     -- no reset

   signal Done : std_logic;
   signal Dout : INTEGER;

   constant Clk_period : time := 10 ns;

BEGIN

   uut: entity work.DCT_beh -- DCT_beh 
       PORT MAP (
           Clk => Clk,
           Start => Start,
           Din => Din,
           Done => Done,
           Dout => Dout
      );

CLOCK: 
    process
    begin
        Clk <= '0';
        wait for Clk_period/2;
        Clk <= '1';
        wait for Clk_period/2;
    end process;

STIMULUS: 
    process
        variable i, j : INTEGER;
        variable cnt : INTEGER;
    begin     

         wait until clk = '1' and clk'event;  -- sync Start to clk

FIRST_BLOCK_IN:
        Start <= '1','0' after 11 ns;  --issued same time as datum 0
        for i in 0 to 63 loop
                if (i < 24) then
                    din <= 255;
                elsif (i > 40) then
                    din <= 255;
                else
                    din <= 0;
                end if;
                wait until clk = '1' and clk'event;
        end loop;
SECOND_BLOCK_N:
        Start <= '1','0' after 11 ns;  -- with first datum
        for cnt in 0 to 63 loop
            din <= cnt; 
            wait until clk = '1' and clk'event;
        end loop;
        din <= 0;  -- to show the last input datum clearly

        wait;
    end process;

END ARCHITECTURE;
