module row_decoder (
    input [3:0] addr,
    output [15:0] row_sel
);
    assign row_sel = 16'b1 << addr;
endmodule
