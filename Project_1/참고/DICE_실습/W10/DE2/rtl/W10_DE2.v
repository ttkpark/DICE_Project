// W10 pre-lab: LEDR[0] blinks from CLOCK_50 using a counter enable.
// Full on/off period = 2 * HALF_PERIOD_CYCLES / 50 MHz.
module W10_DE2 #(
    parameter HALF_PERIOD_CYCLES = 25_000_000
) (
    input  wire       CLOCK_50,
    input  wire [0:0] KEY,      // KEY[0]: low while pressed -> reset
    output wire [0:0] LEDR
);
    // KEY[0] -> two-register synchronizer (same as W10 lecture wrapper)
    reg key_meta, key_sync;
    always @(posedge CLOCK_50) begin
        key_meta <= KEY[0];
        key_sync <= key_meta;
    end
    wire resetn = key_sync;

    // One-cycle tick every HALF_PERIOD_CYCLES; tick is an enable, not a clock
    reg [25:0] div_count;
    wire tick = (div_count == HALF_PERIOD_CYCLES - 1);
    always @(posedge CLOCK_50) begin
        if (!resetn || tick) div_count <= 26'd0;
        else                 div_count <= div_count + 1'b1;
    end

    reg led;
    always @(posedge CLOCK_50) begin
        if (!resetn)   led <= 1'b0;
        else if (tick) led <= ~led;
    end
    assign LEDR[0] = led;
endmodule
