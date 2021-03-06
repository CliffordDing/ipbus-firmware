-- Ipbus slave bus cycle counter for testing
--
-- Simply counts up one for each bus access - for detecting erroneous multiple bus cycles
-- Top sixteen bits count writes, bottom count reads.
-- Writes to this location do nothing except increment the counter.
--
-- Dave Newbold, March 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;

entity ipbus_ctr is
	port(
		clk: in STD_LOGIC;
		reset: in STD_LOGIC;
		ipbus_in: in ipb_wbus;
		ipbus_out: out ipb_rbus
	);
	
end ipbus_ctr;

architecture rtl of ipbus_ctr is

	signal w_ctr, r_ctr: unsigned(15 downto 0);
	signal ack: std_logic;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if reset='1' then
				w_ctr <= (others=>'0');
				r_ctr <= (others=>'0');
			elsif ipbus_in.ipb_strobe='1' then
				if ipbus_in.ipb_write='1' then
					w_ctr <= w_ctr + 1;
				else
					r_ctr <= r_ctr + 1;
				end if;
			end if;

			ipbus_out.ipb_rdata <= std_logic_vector(w_ctr) & std_logic_vector(r_ctr);
			ack <= ipbus_in.ipb_strobe and not ack;

		end if;
	end process;
	
	ipbus_out.ipb_ack <= ack;
	ipbus_out.ipb_err <= '0';

end rtl;
