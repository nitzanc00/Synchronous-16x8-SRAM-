module sram16x8 (
    input clk,
    input rst_n,     // active-low reset 
    input we_n,      // active-low write enable
    input [6:0] addr, // [6:3] row, [2:0] col
    input  din,       // 1-bit write data
    output dout       // 1-bit read data (registered, single-cycle)
);

// Split address
    wire [3:0] row_addr = addr[6:3];  
    wire [2:0] col_addr = addr[2:0];  

// Decoders
    wire [15:0] row_sel;
    wire [7:0] col_sel;
    row_decoder u_row_dec (.addr(row_addr), .row_sel(row_sel));
    col_decoder u_col_dec (.addr(col_addr), .col_sel(col_sel));

// Memory array: 16 rows × 8 columns (Each element in the array is 8 bits wide)
    reg [7:0] mem [0:15];

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) mem[i] = 8'h00; // sets 0 all 8 bits in row i
    end

 // Optional sync reset
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1) mem[i] <= 8'h00;
        end
    end
// Write driver
    wire do_write;
    wire data_bit;
    write_driver #(.Rows(16), .Cols(8)) u_wdrv (
        .we_n(we_n),
        .row_sel(row_sel),
        .col_sel(col_sel),
        .din(din),
        .do_write(do_write),
        .data_bit(data_bit)
  );

// WRITE (synchronous, write-first behavior)
    always @(posedge clk) begin
        if (rst_n && do_write) begin
            mem[row_addr][col_addr] <= data_bit;
        end
    end

 // READ path (select row/col, then register at clk → single-cycle latency)
    wire [7:0] selected_row = mem[row_addr];
    wire mux_out;
    mux8to1 u_mux (.din(selected_row), .sel(col_addr), .dout(mux_out));

    wire sa_out;
    sense_amp u_sa (.bitline_in(mux_out), .dout(sa_out));

    reg dout_r;
    always @(posedge clk) begin
        if (!rst_n) dout_r <= 1'b0;
        else dout_r <= sa_out; // registered → synchronous output
    end

    assign dout = dout_r;

endmodule
