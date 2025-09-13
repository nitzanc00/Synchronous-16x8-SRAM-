module col_decoder (
    input [2:0] addr,
    output [7:0] col_sel
);
    assign col_sel = 8'b1 << addr;
endmodule