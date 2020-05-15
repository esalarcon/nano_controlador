library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fsm_nano_controlador is
    Port ( clk                   : in   STD_LOGIC;
           rst                   : in   STD_LOGIC;
           opcode                : in   STD_LOGIC_VECTOR (4 downto 0);
           a_zero                : in   STD_LOGIC;
           z_zero                : in   STD_LOGIC;
           program_mux_pc_sel    : out  STD_LOGIC;
           pc_load               : out  STD_LOGIC;
           pc_inc                : out  STD_LOGIC;
           program_stack_push    : out  STD_LOGIC;
           program_stack_pop     : out  STD_LOGIC;
           data_address_sel      : out  STD_LOGIC_VECTOR (1 downto 0);
           x_load                : out  STD_LOGIC;
           x_inc                 : out  STD_LOGIC;
           y_load                : out  STD_LOGIC;
           y_inc                 : out  STD_LOGIC;
           z_load                : out  STD_LOGIC;
           z_dec                 : out  STD_LOGIC;
           data_mux_alu_sel      : out  STD_LOGIC;
           alu_cmd               : out  STD_LOGIC_VECTOR (1 downto 0);
           a_load                : out  STD_LOGIC;
           a_inc                 : out  STD_LOGIC;
           a_dec                 : out  STD_LOGIC;
           wr                    : out  STD_LOGIC);
end fsm_nano_controlador;

architecture Behavioral of fsm_nano_controlador is
   type status is (FETCHING, EXECUTING, UPDATING, WRITING);
   signal actual, futuro         :  status;
   signal deco_opcode            :  std_logic_vector(20 downto 0);
   signal execute, write_val     :  std_logic;
   signal fetch, pc_load_cond    :  std_logic;
   signal is_loading, loop_pass  :  std_logic;
   signal jump, jz, jnz, is_loop :  std_logic;
begin
                              
   process(clk)
   begin
      if(rising_edge(clk)) then
         if(rst = '1') then
            actual <= FETCHING;
         else
            actual <= futuro;
         end if;
      end if;
   end process;
   
   -- El procesador divide al clock en cuatro fases.
   -- BUSQUEDA, EJECUCION, ACTUALIZACION y ESCRITURA
   -- todas las instrucciones lo respetan. 
   -- Por lo que para tener 1MIP necesito una FCLOCK
   -- de 4MHZ.
   process(actual)
   begin
      case actual is
         when FETCHING  => futuro <= EXECUTING;
         when EXECUTING => futuro <= UPDATING;
         when UPDATING  => futuro <= WRITING;
         when WRITING   => futuro <= FETCHING;
      end case;
   end process;
   
   process(actual, is_loading)
   begin
      case actual is
         when FETCHING  => 
                           execute   <= '0';                          
                           write_val <= '0';
                           fetch     <= '1';
         when EXECUTING => 
                           execute   <= not is_loading;
                           write_val <= '0';
                           fetch     <= '0';
         when UPDATING  => 
                           execute   <= is_loading;
                           write_val <= '1';
                           fetch     <= '0';                           
         when WRITING   =>
                           execute   <= '0';
                           write_val <= '0';
                           fetch     <= '0';
      end case;
   end process;
   
   -- Combinacionales.
   data_mux_alu_sel     <=  deco_opcode(2); 
   is_loading           <=  deco_opcode(2);
   program_mux_pc_sel   <=  deco_opcode(17);  
   alu_cmd              <=  deco_opcode(20 downto 19);
   data_address_sel     <=  deco_opcode(12 downto 11);
   is_loop              <=  deco_opcode(18) and (not z_zero);  
   loop_pass            <=  deco_opcode(18) and z_zero;
   jz                   <=  deco_opcode(14) and (a_zero);
   jnz                  <=  deco_opcode(15) and (not a_zero);
   pc_load_cond         <= (deco_opcode(1) or jz or jnz or is_loop);


   -- Señales sincronizadas con el ciclo de búsqueda
   z_dec                <= (not z_zero) and fetch when opcode = "10010" else '0';

   -- Señales sincronizadas con el ciclo de ejecución.
   pc_load              <=  pc_load_cond    and execute; 
   a_load               <=  deco_opcode(3)  and execute;
   a_inc                <=  deco_opcode(4)  and execute;
   a_dec                <=  deco_opcode(5)  and execute;
   x_load               <=  deco_opcode(6)  and execute;
   x_inc                <=  deco_opcode(7)  and execute;
   y_load               <=  deco_opcode(8)  and execute;
   y_inc                <=  deco_opcode(9)  and execute;
   z_load               <=  deco_opcode(10) and execute;
   program_stack_push   <=  deco_opcode(16) and execute;

   -- Señales sincronizadas con el clico de escritura
   pc_inc               <= (deco_opcode(0) or loop_pass) and write_val;
   wr                   <=  deco_opcode(13) and write_val;
   program_stack_pop    <=  deco_opcode(17) and write_val;
   
   -- Tabla de decodificación (32 instrucciones).
   -- 4 modos de direccionamiento IMPLICITO, DIRECTO, INDIRECTO (X o Y) e INMEDIATO
   process(clk)
   begin
      if(rising_edge(clk)) then
         case opcode is
            when "00000" => deco_opcode <= "000000010000000000001";  --MOV DIR,A
            when "00001" => deco_opcode <= "000000000000000001001";  --MOV A,$CTE
            when "00010" => deco_opcode <= "000000000000000010001";  --INC A
            when "00011" => deco_opcode <= "000000000000000100001";  --DEC A
            when "00100" => deco_opcode <= "000000000000001000001";  --MOV X,$CTE
            when "00101" => deco_opcode <= "000000000000010000001";  --INC X
            when "00110" => deco_opcode <= "000000000000100000001";  --MOV Y,$CTE
            when "00111" => deco_opcode <= "000000000001000000001";  --INC Y
            when "01000" => deco_opcode <= "000000000010000000001";  --MOV Z,$CTE
            when "01001" => deco_opcode <= "000000011000000000001";  --MOV X,A
            when "01010" => deco_opcode <= "000000001000000001101";  --MOV A,X
            when "01011" => deco_opcode <= "000000011100000000001";  --MOV Y,A
            when "01100" => deco_opcode <= "000000001100000001101";  --MOV A,Y
            when "01101" => deco_opcode <= "000000000000000000010";  --JMP CTE
            when "01110" => deco_opcode <= "000000100000000000000";  --JZ  CTE
            when "01111" => deco_opcode <= "000001000000000000000";  --JNZ CTE
            when "10000" => deco_opcode <= "000010000000000000010";  --CALL
            when "10001" => deco_opcode <= "000100000000000000011";  --RET
            when "10010" => deco_opcode <= "001000000000000000000";  --LOOP CTE
            when "10011" => deco_opcode <= "010000000000000001101";  --MOV A, DIR  
            when "10100" => deco_opcode <= "010000000000000001001";  --AND A, $CTE
            when "10101" => deco_opcode <= "010000001000000001101";  --AND A, [X]
            when "10110" => deco_opcode <= "010000001100000001101";  --AND A, [Y]
            when "10111" => deco_opcode <= "010000000000000001101";  --AND A, DIR
            when "11000" => deco_opcode <= "100000000000000001001";  --OR  A, $CTE
            when "11001" => deco_opcode <= "100000001000000001101";  --OR  A, [X]
            when "11010" => deco_opcode <= "100000001100000001101";  --OR  A, [Y]
            when "11011" => deco_opcode <= "100000000000000001101";  --OR  A, DIR
            when "11100" => deco_opcode <= "110000000000000001001";  --XOR A, $CTE
            when "11101" => deco_opcode <= "110000001000000001101";  --XOR A, [X]
            when "11110" => deco_opcode <= "110000001100000001101";  --XOR A, [Y]
            when "11111" => deco_opcode <= "110000000000000001101";  --XOR A, DIR
            when others  => null; 
         end case;
      end if;
   end process;
end Behavioral;
