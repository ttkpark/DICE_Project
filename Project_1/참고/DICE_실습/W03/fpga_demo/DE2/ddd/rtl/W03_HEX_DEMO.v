// SW3..SW0 select one decimal digit on HEX0. No clock is needed.
module W03_HEX_DEMO (/*AUTOARG*/
    // Outputs
    HEX0,
    // Inputs
    SW
);
    output wire [6:0] HEX0;
    input  wire [3:0] SW;
    /* BCD_TO_7SEG AUTO_TEMPLATE (
        .SEG (HEX0[6:0]),
        .BCD (SW[3:0])
    ); */
    BCD_TO_7SEG u_digit (/*AUTOINST*/
        // Outputs
        .SEG (HEX0[6:0]),
        // Inputs
        .BCD (SW[3:0])
    );
endmodule

// Local Variables:
// verilog-auto-arg-format: single
// verilog-library-files: ("09_bcd_to_7seg.v")
// End:
