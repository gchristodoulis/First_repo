LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity DCT_beh is
    port (
        Clk :           in std_logic;
        Start :         in std_logic;
        Din :           in INTEGER;
        Done :          out std_logic;
        Dout :          out INTEGER
      );

 end DCT_beh;

architecture behavioral of DCT_beh is 
    type RF is array ( 0 to 7, 0 to 7 ) of INTEGER;
    signal OutBlock:            RF;
    signal InBlock:             RF;
    signal internal_Done:       std_logic := '0';  -- no reset
    signal Input_Ready:         std_logic := '0';  -- no reset
    signal done_detected:       std_logic := '0';  -- no reset
    signal input_rdy_detected:  std_logic := '0';  -- no reset
    signal last_out:            std_logic := '0';  -- no reset

begin
INPUT_DATA:
    process
    begin
        wait until Start = '1';
        --Read Input Data
        for i in 0 to 7 loop
            for j in 0 to 7 loop    
                wait until Clk = '1' and clk'event;
                InBlock(i,j) <= Din;
                if i=7 and j=7 then
                    Input_Ready <= '1', '0' after 11 ns;  
                end if;
            end loop;
        end loop;
    end process;

WAIT_FOR_InBlock:
    process
    begin   
        wait until clk = '1' and clk'event;
        input_rdy_detected <= Input_Ready;  
        --InBlock valid after the following rising edge of clk
    end process;

TRANSFORM:
    process 
            variable InpBlock       : RF;
            constant COSBlock       : RF :=
            ( 
                ( 125,   122,   115,    103,    88,     69,     47,      24  ),
                ( 125,   103,    47,    -24,   -88,   -122,   -115,     -69  ),
                ( 125,    69,   -47,   -122,   -88,     24,    115,     103  ),
                ( 125,    24,  -115,    -69,    88,    103,    -47,    -122  ),
                ( 125,   -24,  -115,     69,    88,   -103,    -47,     122  ),
                ( 125,   -69,   -47,    122,   -88,    -24,    115,    -103  ),
                ( 125,  -103,    47,     24,   -88,    122,   -115,      69  ),
                ( 125,  -122,   115,   -103,    88,    -69,     47,     -24  )
            );
            variable TempBlock      : RF;
            variable A, B, P, Sum   : INTEGER; 
    begin

        if input_rdy_detected = '0' then
            wait until input_rdy_detected = '1';
        end if;

        InpBlock := InBlock;  -- Broadside dump or swap

--TempBlock = COSBLOCK * InBlock  

-- arbitrarily make matrix multiple 2 clocks long      
      wait until clk = '1' and clk'event;  -- 1st xfm clock

        for i in 0 to 7 loop
            for j in 0 to 7 loop
                Sum := 0;
                for k in 0 to 7 loop
                    A := COSBlock( i, k ); 
                    B := InpBlock( k, j ); 
                    P := A * B; 
                    Sum := Sum + P; 
                    if( k = 7 ) then 
                        TempBlock( i, j ) := Sum;
                    end if;
                end loop;
            end loop;
        end loop;

  --  Done issued in clk cycle of last TempBlock( i, j )  := Sum;

        internal_Done <= '1', '0' after 11 ns;  
        wait until clk = '1' and clk'event;  -- 2nd xfrm clk   
        -- OutBlock available after last TempBlock value stored   

        OutBlock <= TempBlock;   -- Broadside dump or swap
    end process;

Done_BUFFER:
    Done <= internal_Done;


WAIT_FOR_OutBlock:
    process
    begin
        wait until clk = '1' and clk'event;
        done_detected <= internal_Done;
        -- Done can come either before the first output_data transfer
        -- or during the last output data transfer
        -- this gives us the clock delay to finish the last xfm transfer to 
        -- TempBlock( i, j)
        -- Technically part of the output process but was too cumbersome to write
    end process;

OUTPUT_DATA:
    process
    begin
        -- OutBlock is valid after clock edge when Done is true
        for i in 0 to 7 loop
            for j in 0 to 7 loop

                if i = 0 and j = 0 then

                    if done_detected = '0' then
                        wait until done_detected = '1';
                    end if; 
                end if;  

                Dout <=  OutBlock(i,j);                        
                wait until clk = '1' and clk'event;
            end loop;
        end loop;
    end process;

end behavioral;
