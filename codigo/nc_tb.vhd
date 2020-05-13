LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY nc_tb IS
END nc_tb;
 
ARCHITECTURE behavior OF nc_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT nano_controlador_top
    PORT(
         clk                  : IN     std_logic;
         rst                  : IN     std_logic;
         data_address_bus     : OUT    std_logic_vector(12 downto 0);
         program_address_bus  : OUT    std_logic_vector(9 downto 0);
         data_data_out_bus    : OUT    std_logic_vector(7 downto 0);
         program_data_bus     : IN     std_logic_vector(17 downto 0);
         data_data_in_bus     : IN     std_logic_vector(7 downto 0);
         wr                   : OUT    std_logic);
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal program_data_bus : std_logic_vector(17 downto 0) := (others => '0');
   signal data_data_in_bus : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal data_address_bus : std_logic_vector(12 downto 0);
   signal program_address_bus : std_logic_vector(9 downto 0);
   signal data_data_out_bus : std_logic_vector(7 downto 0);
   signal wr : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
   -- Others
   type ram is array (natural range <>) of std_logic_vector(7 downto 0);
   signal memram  : ram(255 downto 0) := (others => (x"01"));
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: nano_controlador_top PORT MAP (
          clk => clk,
          rst => rst,
          data_address_bus => data_address_bus,
          program_address_bus => program_address_bus,
          data_data_out_bus => data_data_out_bus,
          program_data_bus => program_data_bus,
          data_data_in_bus => data_data_in_bus,
          wr => wr
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
   end process;
 
   --Memoria de programa.
   process
   begin
      wait until rising_edge(clk);
      case program_address_bus is
         when "0000000000" => program_data_bus <= "00001"&"0000010101010";
         when "0000000001" => program_data_bus <= "00010"&"0000000000000";
         when "0000000010" => program_data_bus <= "00011"&"0000000000000"; 
         when "0000000011" => program_data_bus <= "00100"&"0000011111110"; 
         when "0000000100" => program_data_bus <= "01001"&"0000000000000";
         when "0000000101" => program_data_bus <= "00010"&"0000000000000";         
         when "0000000110" => program_data_bus <= "01010"&"0000000000000";    
         when "0000000111" => program_data_bus <= "01101"&"0000000001000";
         when "0000001000" => program_data_bus <= "10000"&"0001000000000";
         when "0000001001" => program_data_bus <= "01101"&"0000000001010";
         when "0000001010" => program_data_bus <= "00001"&"0000000000000"; --MOV A,0x00
         when "0000001011" => program_data_bus <= "01000"&"0000000000010"; --MOV Z,0x02
         when "0000001100" => program_data_bus <= "00010"&"0000000000000"; --INC A
         when "0000001101" => program_data_bus <= "10010"&"0000000001100"; --LOOP anterior
         when "0000001110" => program_data_bus <= "00011"&"0000000000000"; --DEC A        
         when "1000000000" => program_data_bus <= "10001"&"0000000000000";
         when others       => program_data_bus <= "00000"&"0000000000000";
      end case;
   end process;
 
   process
      variable i  : natural range 0 to 255;
   begin
      wait until rising_edge(clk);
      i:= to_integer(unsigned(data_address_bus(7 downto 0)));
      if(wr = '1') then
         memram(i) <= data_data_out_bus;
      end if;
      data_data_in_bus <= memram(i);
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      wait for clk_period*2;	
      rst <= '0';
      wait;
   end process;

END;
