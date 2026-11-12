library verilog;
use verilog.vl_types.all;
entity IMEM is
    port(
        ADDR            : in     vl_logic_vector(31 downto 0);
        INSTR           : out    vl_logic_vector(31 downto 0)
    );
end IMEM;
