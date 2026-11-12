library verilog;
use verilog.vl_types.all;
entity DMEM is
    port(
        CLK             : in     vl_logic;
        MEMWRITE        : in     vl_logic;
        ADDR            : in     vl_logic_vector(31 downto 0);
        WRITEDATA       : in     vl_logic_vector(31 downto 0);
        READDATA        : out    vl_logic_vector(31 downto 0)
    );
end DMEM;
