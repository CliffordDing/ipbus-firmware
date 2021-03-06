-- big_fifo_36
--
-- Parametrised depth single-clock FWFT FIFO based on 7-series FIFO36E1 in 36bit mode
--
-- Dave Newbold, August 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity big_fifo_36 is
	generic(
		N_FIFO: positive
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: in std_logic_vector(35 downto 0); -- data in
		wen: in std_logic; -- write enable
		full: out std_logic; -- full flag
		empty: out std_logic; -- empty flag
		ctr: out std_logic_vector(17 downto 0); -- data count
		ren: in std_logic; -- read enable
		q: out std_logic_vector(35 downto 0); -- data out
		valid: out std_logic -- data valid flag
	);
	
begin

	assert N_FIFO <= 512
		report "big_fifo_36 is too large for internal counters"
		severity failure;

end big_fifo_36;

architecture rtl of big_fifo_36 is

	signal en: std_logic_vector(N_FIFO downto 0);
	signal ifull, iempty: std_logic_vector(N_FIFO - 1  downto 0);
	signal rsti, warn_i, fifo_rst: std_logic;
	type fifo_d_t is array(N_FIFO downto 0) of std_logic_vector(71 downto 0);
	signal fifo_d: fifo_d_t;
	signal rst_ctr: unsigned(3 downto 0);
	signal ctri: unsigned(17 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rst_ctr <= "0000";
			elsif rsti = '1' then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	
	rsti <= '0' when rst_ctr = "1111" else '1';
	fifo_rst <= rsti and rst_ctr(3);
	
	fifo_d(0) <= X"0" & d(35 downto 32) & X"00000000" & d(31 downto 0);
	en(0) <= wen and not (rsti or ifull(0));
	en(N_FIFO) <= ren and not (rsti or iempty(N_FIFO - 1));

	fifo_gen: for i in N_FIFO - 1 downto 0 generate
	
	begin
	
		fifo: FIFO36E1
			generic map(
				DATA_WIDTH => 36,
				FIRST_WORD_FALL_THROUGH => true
			)
			port map(
				di => fifo_d(i)(63 downto 0),
				dip => fifo_d(i)(71 downto 64),
				do => fifo_d(i + 1)(63 downto 0),
				dop => fifo_d(i + 1)(71 downto 64),
				empty => iempty(i),
				full => ifull(i),
				injectdbiterr => '0',
				injectsbiterr => '0',
				rdclk => clk,
				rden => en(i + 1),
				regce => '1',
				rst => fifo_rst,
				rstreg => '0',
				wrclk => clk,
				wren => en(i)
			);
		
	end generate;
	
	en(N_FIFO - 1 downto 1) <= not ifull(N_FIFO - 1 downto 1) and not iempty(N_FIFO - 2 downto 0) and not (N_FIFO - 2 downto 0 => rsti);
	
	q <= fifo_d(N_FIFO)(67 downto 64) & fifo_d(N_FIFO)(31 downto 0);
	valid <= not iempty(N_FIFO - 1);
	full <= ifull(0);
	empty <= iempty(N_FIFO - 1);

	process(clk)
	begin
		if rising_edge(clk) then
			if rsti = '1' then
				ctri <= (others => '0');
			elsif en(0) = '1' and en(N_FIFO) = '0' then
				ctri <= ctri + 1;
			elsif en(0) = '0' and en(N_FIFO) = '1' then
				ctri <= ctri - 1;
			end if;
		end if;
	end process;

	ctr <= std_logic_vector(ctri);
	
end rtl;
