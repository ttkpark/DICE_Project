library verilog;
use verilog.vl_types.all;
entity CORE is
    port(
        CLK             : in     vl_logic;
        RESET           : in     vl_logic;
        INSTR           : in     vl_logic_vector(31 downto 0);
        READDATA        : in     vl_logic_vector(31 downto 0);
        PC              : out    vl_logic_vector(31 downto 0);
        MEMWRITE        : out    vl_logic;
        ALURESULT       : out    vl_logic_vector(31 downto 0);
        WRITEDATA       : out    vl_logic_vector(31 downto 0)
    );
end CORE;
