module mux8to1 (
    input [7:0] din,  // 8-bit row contents: din[0], din[1], ..., din[7]
    input [2:0] sel,  // 3-bit select: selects one of the 8 inputs
    output dout
);
    assign dout = din[sel];  // picks the bit at position 'sel'
endmodule