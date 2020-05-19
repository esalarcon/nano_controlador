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
         bus_request          : IN     std_logic;
         bus_request_ack      : OUT    std_logic;
         wr                   : OUT    std_logic);
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal program_data_bus : std_logic_vector(17 downto 0) := (others => '0');
   signal data_data_in_bus : std_logic_vector(7 downto 0) := (others => '0');
   signal  bus_request     : std_logic := '0';
         
 	--Outputs
   signal data_address_bus : std_logic_vector(12 downto 0);
   signal program_address_bus : std_logic_vector(9 downto 0);
   signal data_data_out_bus : std_logic_vector(7 downto 0);
   signal wr : std_logic;
   signal bus_request_ack : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
   -- Others
   type ram is array (natural range <>) of std_logic_vector(7 downto 0);
   signal memram  : ram(255 downto 0) := (others => (x"01"));
   
   -- Decodificación de direcciones
   constant CS_RAM                     : std_logic_vector(1 downto 0) := "00";
   constant CS_TIMER                   : std_logic_vector(1 downto 0) := "01";
   constant CS_PORT                    : std_logic_vector(1 downto 0) := "10";
   
   
   signal wr_ram, wr_port, wr_timer    :  std_logic;     
   signal data_ram, data_timer         :  std_logic_vector(7 downto 0);
   signal leds                         :  std_logic_vector(7 downto 0);
   
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: nano_controlador_top PORT MAP (
          clk                 => clk,
          rst                 => rst,
          data_address_bus    => data_address_bus,
          program_address_bus => program_address_bus,
          data_data_out_bus   => data_data_out_bus,
          program_data_bus    => program_data_bus,
          data_data_in_bus    => data_data_in_bus,
          bus_request         => bus_request,
          bus_request_ack     => bus_request_ack,
          wr                  => wr);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
   end process;
 
   wr_ram   <= wr when CS_RAM   = data_address_bus(9 downto 8) else '0';
   wr_port  <= wr when CS_PORT  = data_address_bus(9 downto 8) else '0';
   wr_timer <= wr when CS_TIMER = data_address_bus(9 downto 8) else '0';
 
   --decodificación
   with data_address_bus(9 downto 8) select
      data_data_in_bus  <= data_ram    when CS_RAM,
                           data_timer  when CS_TIMER,
                           x"55"       when others;
   
   
   --puerto de salida.
   process
   begin
      wait until rising_edge(clk);
      if(wr_port = '1') then
         leds <= data_data_out_bus;
      end if; 
   end process;
  
   --Timer.
   process
      variable tc       : std_logic := '0';
      variable cuenta   : integer range 0 to 255 := 99;
   begin
      wait until rising_edge(clk);
      if(wr_timer = '1') then
         cuenta := 99;
         tc     := '0';
      end if;
      if(cuenta /= 0) then
         cuenta := cuenta-1;
      end if;
      if(cuenta = 0) then
         tc := '1';
      end if;
      data_timer <= "0000000"&tc;
   end process;

   process
      variable i  : natural range 0 to 255;
   begin
      wait until rising_edge(clk);
      i:= to_integer(unsigned(data_address_bus(7 downto 0)));
      if(wr_ram = '1') then
         memram(i) <= data_data_out_bus;
      end if;
      data_ram <= memram(i);
   end process;

 
   --Memoria de programa.
   --(Generada por el ensamblador)
   process
   begin
      wait until rising_edge(clk);
      case program_address_bus is
         when "0000000000" => program_data_bus <= "00001" & "0000000000001";
         when "0000000001" => program_data_bus <= "00000" & "0000011111110";
         when "0000000010" => program_data_bus <= "00000" & "0001000000000";
         when "0000000011" => program_data_bus <= "00001" & "0000000010100";
         when "0000000100" => program_data_bus <= "00000" & "0000011111111";
         when "0000000101" => program_data_bus <= "00001" & "0000000000001";
         when "0000000110" => program_data_bus <= "10111" & "0000100000000";
         when "0000000111" => program_data_bus <= "01110" & "0000000000101";
         when "0000001000" => program_data_bus <= "00000" & "0000100000000";
         when "0000001001" => program_data_bus <= "10011" & "0000011111111";
         when "0000001010" => program_data_bus <= "00011" & "0000000000000";
         when "0000001011" => program_data_bus <= "00000" & "0000011111111";
         when "0000001100" => program_data_bus <= "01111" & "0000000000101";
         when "0000001101" => program_data_bus <= "00001" & "0000000000001";
         when "0000001110" => program_data_bus <= "11111" & "0000011111110";
         when "0000001111" => program_data_bus <= "01101" & "0000000000001";
         when others       => program_data_bus <= "00000" & "0000000000000";
      end case;
   end process;



   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      wait for clk_period*2;	
      rst <= '0';
      wait for clk_period*10001;
      bus_request <= '1';
      wait until rising_edge(bus_request_ack);
      wait for clk_period*500;
      bus_request <= '0';
      wait;
   end process;

END;
