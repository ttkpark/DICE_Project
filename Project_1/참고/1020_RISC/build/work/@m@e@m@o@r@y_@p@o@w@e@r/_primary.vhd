library verilog;
use verilog.vl_types.all;
entity MEMORY_POWER is
    port(
        CLK             : in     vl_logic;
        RESET           : in     vl_logic;
        INSTR           : in     vl_logic_vector(31 downto 0);
        MEMWRITE        : in     vl_logic;
        ALURESULT       : in     vl_logic_vector(31 downto 0);
        WRITEDATA       : in     vl_logic_vector(31 downto 0);
        DONE_ADDR       : in     vl_logic_vector(31 downto 0);
        DONE_TOKEN      : in     vl_logic_vector(31 downto 0);
        IMEM_WORDS      : in     vl_logic_vector(31 downto 0)
    );
end MEMORY_POWER;
