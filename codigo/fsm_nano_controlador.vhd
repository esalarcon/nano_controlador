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
           a_dec                 : out STD_LOGIC;
           wr                    : out  STD_LOGIC);
end fsm_nano_controlador;

architecture Behavioral of fsm_nano_controlador is
   type status is (FETCHING, EXECUTING, UPDATING, WRITING);
   signal actual, futuro         :  status;
   signal deco_opcode            :  std_logic_vector(23 downto 0);
   signal execute, write_val     :  std_logic;
   signal is_loading             :  std_logic;
   signal jump                   :  std_logic;
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

         when EXECUTING => 
                           execute   <= not is_loading;
                           write_val <= '0';
         when UPDATING  => 
                           execute   <= is_loading;
                           write_val <= '1';         
         when WRITING   =>
                           execute   <= '0';
                           write_val <= '0';
      end case;
   end process;
   
         
   pc_inc               <= deco_opcode(0)  and write_val;
   pc_load              <= deco_opcode(1)  and execute; 
   data_mux_alu_sel     <= deco_opcode(2); 
   a_load               <= deco_opcode(3)  and execute;
   a_inc                <= deco_opcode(4)  and execute;
   a_dec                <= deco_opcode(5)  and execute;
   x_load               <= deco_opcode(6)  and execute;
   x_inc                <= deco_opcode(7)  and execute;
   y_load               <= deco_opcode(8)  and execute;
   y_inc                <= deco_opcode(9)  and execute;
   z_load               <= deco_opcode(10) and execute;
   data_address_sel     <= deco_opcode(12 downto 11);
   wr                   <= deco_opcode(13) and write_val;
   is_loading           <= deco_opcode(14);
   
   z_dec                <= deco_opcode(23) and execute;
   
   
   program_stack_push   <= deco_opcode(23) and execute;                  
   program_stack_pop    <= deco_opcode(23) and execute;                  
   

   
   
   program_mux_pc_sel   <= deco_opcode(23);
   
   alu_cmd              <= deco_opcode(23 downto 22);
   
   process(clk)
   begin
      if(rising_edge(clk)) then
         case opcode is
            when "00000" => deco_opcode <= "000000000000000000000001";  --NOP
            when "00001" => deco_opcode <= "000000000000000000001001";  --MOV A,CTE
            when "00010" => deco_opcode <= "000000000000000000010001";  --INC A
            when "00011" => deco_opcode <= "000000000000000000100001";  --DEC A
            when "00100" => deco_opcode <= "000000000000000001000001";  --MOV X,CTE
            when "00101" => deco_opcode <= "000000000000000010000001";  --INC X
            when "00110" => deco_opcode <= "000000000000000100000001";  --MOV Y,CTE
            when "00111" => deco_opcode <= "000000000000001000000001";  --INC Y
            when "01000" => deco_opcode <= "000000000000010000000001";  --MOV Z,CTE
            when "01001" => deco_opcode <= "000000000011000000000001";  --STR X
            when "01010" => deco_opcode <= "000000000101000000001101";  --LDR X
            when "01011" => deco_opcode <= "000000000011100000000001";  --STR Y
            when "01100" => deco_opcode <= "000000000101100000001101";  --LDR Y
            when "01101" => deco_opcode <= "000000000000000000000000";
            when "01110" => deco_opcode <= "000000000000000000000000";
            when "01111" => deco_opcode <= "000000000000000000000000";
            when "10000" => deco_opcode <= "000000000000000000000000";
            when "10001" => deco_opcode <= "000000000000000000000000";
            when "10010" => deco_opcode <= "000000000000000000000000";
            when "10011" => deco_opcode <= "000000000000000000000000";
            when "10100" => deco_opcode <= "000000000000000000000000";
            when "10101" => deco_opcode <= "000000000000000000000000";
            when "10110" => deco_opcode <= "000000000000000000000000";
            when "10111" => deco_opcode <= "000000000000000000000000";
            when "11000" => deco_opcode <= "000000000000000000000000";
            when "11001" => deco_opcode <= "000000000000000000000000";
            when "11010" => deco_opcode <= "000000000000000000000000";
            when "11011" => deco_opcode <= "000000000000000000000000";
            when "11100" => deco_opcode <= "000000000000000000000000";
            when "11101" => deco_opcode <= "000000000000000000000000";
            when "11110" => deco_opcode <= "000000000000000000000000";
            when "11111" => deco_opcode <= "000000000000000000000000";
            when others  => null; 
         end case;
      end if;
   end process;
   
      

end Behavioral;

