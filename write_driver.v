module write_driver #(
  parameter Rows = 16, // Number of rows in SRAM (parameterized)
  parameter Cols = 8   // Number of columns in SRAM (parameterized)
)
(
  input we_n,       // active-low write enable
  input [Rows-1:0]  row_sel,    // One-hot row selection signal
  input [Cols-1:0]  col_sel,    // One-hot column selection signal
  input  din,                   // Data bit to write
  output do_write,   // Write pulse: high when writing
  output data_bit     // Actual data bit to store in memory cell
);
  assign do_write = (~we_n) & (|row_sel) & (|col_sel);
  assign data_bit = din;
endmodule