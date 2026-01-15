-------------------------------------------------------------------------------
-- MCU SPI comm module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity mcu is
	port
	(
	 CLK			 : in std_logic;
	 N_RESET 	 : in std_logic := '1';

	 -- spi
    MCU_MOSI    : in std_logic;
    MCU_MISO    : out std_logic := 'Z';
    MCU_SCK     : in std_logic;
	 MCU_SS 		 : in std_logic;

	 -- soft switches command
	 SOFTSW_COMMAND : out std_logic_vector(15 downto 0);
	 
	 -- HW ID
	 HWID : out std_logic_vector(7 downto 0) := (others => '0');
	 DVI_ONLY : out std_logic := '0';
	 
	 -- busy
	 BUSY: buffer std_logic := '1'
	 
	);
    end mcu;
architecture rtl of mcu is

	-- spi commands
	constant CMD_SWITCHES   : std_logic_vector(7 downto 0) := x"05";
	constant CMD_HW_SETUP	: std_logic_vector(7 downto 0) := x"F9";
	constant CMD_INIT_START	: std_logic_vector(7 downto 0) := x"FD";
	constant CMD_INIT_DONE	: std_logic_vector(7 downto 0) := x"FE";	
	constant CMD_NOPE			: std_logic_vector(7 downto 0) := x"FF";

	 -- spi
	 signal spi_do_valid 	: std_logic := '0';
	 signal spi_di 			: std_logic_vector(23 downto 0);
	 signal spi_do 			: std_logic_vector(23 downto 0);
	 signal spi_di_req 		: std_logic;
	 signal spi_miso 		 	: std_logic;
	
begin
	
	--------------------------------------------------------------------------
	-- MCU SPI communication
	--------------------------------------------------------------------------		  
	
	U_SPI: entity work.spi_slave
	generic map(
			N             => 24 -- 3 bytes (cmd + addr + data)       
	 )
	port map(
		  clk_i          => CLK,
		  spi_sck_i      => MCU_SCK,
		  spi_ssel_i     => MCU_SS,
		  spi_mosi_i     => MCU_MOSI,
		  spi_miso_o     => spi_miso,

		  di_req_o       => spi_di_req,
		  di_i           => spi_di,
		  wren_i         => '1',
		  
		  do_valid_o     => spi_do_valid,
		  do_o           => spi_do
	);

	spi_di <= CMD_NOPE & x"0000";
	
	MCU_MISO <= spi_miso when MCU_SS = '0' else '1';
	
	process (CLK)
	begin
		if (rising_edge(CLK)) then
		
			if spi_do_valid = '1' then
				case spi_do(23 downto 16) is 

					-- soft switches
					when CMD_SWITCHES => SOFTSW_COMMAND <= spi_do(15 downto 0);
						
					-- hw setup
					when CMD_HW_SETUP =>
						case spi_do(15 downto 8) is
							when x"00" => HWID <= spi_do(7 downto 0);
							when x"01" => DVI_ONLY <= spi_do(0);
							when others => null;
						end case;

					-- init start
					when CMD_INIT_START => BUSY <= '1';

					-- init done
					when CMD_INIT_DONE => BUSY <= '0';

					-- nope
					when CMD_NOPE => null;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;

end RTL;

