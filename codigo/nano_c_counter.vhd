library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity nano_c_counter is
    Generic(LEN   : natural := 8);
    Port ( clk    : in  STD_LOGIC;
           rst    : in  STD_LOGIC;
           load   : in  STD_LOGIC;
           inc    : in  STD_LOGIC;
           dec    : in  STD_LOGIC;
           din    : in  STD_LOGIC_VECTOR (LEN-1 downto 0);
           dout   : out STD_LOGIC_VECTOR (LEN-1 downto 0));
end nano_c_counter;

architecture Behavioral of nano_c_counter is
   signal cnt     :  unsigned(LEN-1 downto 0);
   signal sel     :  std_logic_vector(2 downto 0);
begin
   sel   <= load&inc&dec;
   dout  <= std_logic_vector(cnt);
   process(clk)
   begin
      if(rising_edge(clk)) then
         if(rst = '1') then
            cnt <= (others => '0');
         else
            case sel is
               when "100"  => cnt <= unsigned(din);
               when "010"  => cnt <= cnt + 1;
               when "001"  => cnt <= cnt - 1;
               when others => null;
            end case;
         end if;
      end if;
   end process;
end Behavioral;
