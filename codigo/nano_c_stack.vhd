library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nano_c_stack is
    Generic(LEN_DATA : natural := 10;
            LEN_STACK: natural := 6);
    Port ( clk       : in  STD_LOGIC;
           push      : in  STD_LOGIC;
           pop       : in  STD_LOGIC;
           data_in   : in  STD_LOGIC_VECTOR (LEN_DATA-1 downto 0);
           data_out  : out STD_LOGIC_VECTOR (LEN_DATA-1 downto 0));
end nano_c_stack;

architecture Behavioral of nano_c_stack is
   type memoria_stack is array (natural range <>) of std_logic_vector(LEN_DATA-1 downto 0);
   signal stack      :  memoria_stack(LEN_STACK-1 downto 0);
   signal ctrl       :  std_logic_vector(1 downto 0);
begin

   ctrl <= pop&push;
   process(clk)
   begin
      if(rising_edge(clk)) then
         case ctrl is
            when "01"   =>
                           --push
                           stack(LEN_STACK-1 downto 1) <= stack(LEN_STACK-2 downto 0);
                           stack(0) <= data_in;
            when "10"   =>
                           --pop.
                           stack(LEN_STACK-2 downto 0) <= stack(LEN_STACK-1 downto 1);
            when others => null;
         end case;
      end if;
   end process;
   data_out <= stack(0);
end Behavioral;

