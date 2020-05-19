library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nano_controlador_top is
    Generic(LEN_PROGRAM_ADDRESS  : natural := 10;
           LEN_PROGRAM_STACK     : natural := 4);
    Port ( clk                   : in  STD_LOGIC;
           rst                   : in  STD_LOGIC;
           data_address_bus      : out STD_LOGIC_VECTOR (12 downto 0);
           program_address_bus   : out STD_LOGIC_VECTOR (LEN_PROGRAM_ADDRESS-1 downto 0);
           data_data_out_bus     : out STD_LOGIC_VECTOR (7 downto 0);
           program_data_bus      : in  STD_LOGIC_VECTOR (17 downto 0);
           data_data_in_bus      : in  STD_LOGIC_VECTOR (7 downto 0);
           bus_request           : in  STD_LOGIC;
           bus_request_ack       : out STD_LOGIC;
           wr                    : out STD_LOGIC);
end nano_controlador_top;

architecture Behavioral of nano_controlador_top is
   constant LEN_DATA_ADDRESS     : natural := 13;
   constant LEN_DATA             : natural := 8;
   
   --componentes que necesito predeclarar.
   component fsm_nano_controlador is
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
           bus_request           : in   STD_LOGIC;
           bus_request_ack       : out  STD_LOGIC;
           wr                    : out  STD_LOGIC);
   end component;

   
   --Señales asociadas al PC
   signal program_address        : std_logic_vector(LEN_PROGRAM_ADDRESS-1 downto 0);
   signal program_mux_pc_in      : std_logic_vector(LEN_PROGRAM_ADDRESS-1 downto 0);
   signal program_stack_out      : std_logic_vector(LEN_PROGRAM_ADDRESS-1 downto 0);
   signal program_mux_pc_sel     : std_logic;
   signal program_stack_push     : std_logic;
   signal program_stack_pop      : std_logic;
   signal pc_load, pc_inc        : std_logic;

   --Señales asociadas a los punteros
   signal data_address_sel       : std_logic_vector(1 downto 0);
   signal x_load, x_inc          : std_logic;
   signal y_load, y_inc          : std_logic;
   signal z_load, z_dec, z_zero  : std_logic;
   signal x_rout, y_rout, z_rout : std_logic_vector(LEN_DATA_ADDRESS-1 downto 0);
   
   --Señales asociadas a los datos.
   signal data_mux_alu_in        : std_logic_vector(LEN_DATA-1 downto 0);
   signal a_rout, a_rin          : std_logic_vector(LEN_DATA-1 downto 0); 
   signal data_mux_alu_sel       : std_logic;
   signal a_load, a_inc, a_dec   : std_logic;
   signal a_zero                 : std_logic;
   signal alu_cmd                : std_logic_vector(1 downto 0);
   
   --Si quiero o no usar blockrams para la tabla de decodificación.
   --attribute ram_style : string;
   --attribute ram_style of fsm_nano_controlador : component is "block";
   
begin

--FSM de Control
fsm_control:   fsm_nano_controlador
               port map(clk                  => clk,
                        rst                  => rst,
                        opcode               => program_data_bus(17 downto LEN_DATA_ADDRESS),
                        a_zero               => a_zero,
                        z_zero               => z_zero,
                        program_mux_pc_sel   => program_mux_pc_sel,
                        pc_load              => pc_load,
                        pc_inc               => pc_inc,
                        program_stack_push   => program_stack_push,
                        program_stack_pop    => program_stack_pop,
                        data_address_sel     => data_address_sel,
                        x_load               => x_load,
                        x_inc                => x_inc,
                        y_load               => y_load,
                        y_inc                => y_inc,
                        z_load               => z_load,
                        z_dec                => z_dec,
                        data_mux_alu_sel     => data_mux_alu_sel,
                        alu_cmd              => alu_cmd,
                        a_load               => a_load,
                        a_inc                => a_inc,
                        a_dec                => a_dec,
                        bus_request          => bus_request,
                        bus_request_ack      => bus_request_ack,
                        wr                   => wr);
               

--Genero la sección del contador de programa (PC)
program_address_bus  <= program_address;
program_mux_pc_in    <= program_data_bus(LEN_PROGRAM_ADDRESS-1 downto 0) 
                        when program_mux_pc_sel = '0' else program_stack_out;
                        
reg_pc:  entity work.nano_c_counter(Behavioral)
         generic map(  LEN          => LEN_PROGRAM_ADDRESS)
         port map(     clk          => clk,
                       rst          => rst,
                       load         => pc_load,
                       inc          => pc_inc,
                       dec          => '0',
                       din          => program_mux_pc_in,
                       dout         => program_address);

stack:   entity work.nano_c_stack(Behavioral)
         generic map(   LEN_DATA    => LEN_PROGRAM_ADDRESS,
                        LEN_STACK   => LEN_PROGRAM_STACK)
         port map(      clk         => clk,
                        push        => program_stack_push,
                        pop         => program_stack_pop,
                        data_in     => program_address,
                        data_out    => program_stack_out);

--Genero de los punteros a memoria 
z_zero   <= '1' when unsigned(z_rout) = to_unsigned(0,LEN_DATA_ADDRESS) else '0';
with data_address_sel select
   data_address_bus  <= x_rout                                          when "10",
                        y_rout                                          when "11",
                        program_data_bus(LEN_DATA_ADDRESS-1 downto 0)   when others;
                        
reg_x:   entity work.nano_c_counter(Behavioral)
         generic map(  LEN          => LEN_DATA_ADDRESS)
         port map(     clk          => clk,
                       rst          => rst,
                       load         => x_load,
                       inc          => x_inc,
                       dec          => '0',
                       din          => program_data_bus(LEN_DATA_ADDRESS-1 downto 0),
                       dout         => x_rout);
                       
reg_y:   entity work.nano_c_counter(Behavioral)
         generic map(  LEN          => LEN_DATA_ADDRESS)
         port map(     clk          => clk,
                       rst          => rst,
                       load         => y_load,
                       inc          => y_inc,
                       dec          => '0',
                       din          => program_data_bus(LEN_DATA_ADDRESS-1 downto 0),
                       dout         => y_rout);

reg_z:   entity work.nano_c_counter(Behavioral)
         generic map(  LEN          => LEN_DATA_ADDRESS)
         port map(     clk          => clk,
                       rst          => rst,
                       load         => z_load,
                       inc          => '0',
                       dec          => z_dec,
                       din          => program_data_bus(LEN_DATA_ADDRESS-1 downto 0),
                       dout         => z_rout);

--Genero la parte de datos
a_zero            <= '1' when unsigned(a_rout) = to_unsigned(0,LEN_DATA) else '0';
data_data_out_bus <= a_rout;
data_mux_alu_in   <= program_data_bus(LEN_DATA-1 downto 0) when data_mux_alu_sel = '0'
                     else data_data_in_bus;
with alu_cmd select
   a_rin <= data_mux_alu_in               when "00",
            (data_mux_alu_in and a_rout)  when "01",
            (data_mux_alu_in or  a_rout)  when "10",
            (data_mux_alu_in xor a_rout)  when "11",
            (others => '0')               when others;
            
reg_a:   entity work.nano_c_counter(Behavioral)
         generic map(  LEN          => LEN_DATA)
         port map(     clk          => clk,
                       rst          => rst,
                       load         => a_load,
                       inc          => a_inc,
                       dec          => a_dec,
                       din          => a_rin,
                       dout         => a_rout);
end Behavioral;
