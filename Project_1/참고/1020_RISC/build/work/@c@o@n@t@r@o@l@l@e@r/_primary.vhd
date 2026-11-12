library verilog;
use verilog.vl_types.all;
entity CONTROLLER is
    port(
        INSTR           : in     vl_logic_vector(31 downto 0);
        ZERO            : in     vl_logic;
        REGWRITE        : out    vl_logic;
        MEMWRITE        : out    vl_logic;
        ALUSRC          : out    vl_logic;
        RESULTSRC       : out    vl_logic_vector(1 downto 0);
        IMMSRC          : out    vl_logic_vector(1 downto 0);
        ALUCTRL         : out    vl_logic_vector(2 downto 0);
        PCSRC           : out    vl_logic;
        ILLEGAL         : out    vl_logic
    );
end CONTROLLER;
