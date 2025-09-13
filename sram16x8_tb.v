// sram16x8_tb.v
`timescale 1ns/1ps

module sram16x8_tb;

  reg         clk;
  reg         rst_n;    // active-low
  reg         we_n;     // active-low write enable
  reg  [6:0]  addr;
  reg         din;
  wire        dout;
  reg expA, expB;

  sram16x8 dut (
    .clk (clk),
    .rst_n(rst_n),
    .we_n(we_n),
    .addr(addr),
    .din (din),
    .dout(dout)
  );

  // 10ns period
  initial clk = 0;  // initializing clk = 0
  always #5 clk = ~clk; // change clk every 5ns

  // For VCD (waves)
  initial begin
    $dumpfile("sram16x8.vcd");
    $dumpvars(0, sram16x8_tb);
  end
  
  // Function for making address
  function [6:0] make_addr(input [3:0] row, input [2:0] col); 
    make_addr = {row, col};
  endfunction


  // reset all values in memory
  task do_reset;
  begin
    rst_n = 0; we_n = 1; addr = 0; din = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
  end
  endtask

  // Active-low write: drive we_n=0 for one rising edge
  task write_bit(input [3:0] row, input [2:0] col, input bit val);
  begin
    @(negedge clk);
    addr = make_addr(row, col);
    din  = val;
    we_n = 0;           // enable write (active-low)
    @(posedge clk);     // write happens here
    @(negedge clk);
    we_n = 1;           // disable write
  end
  endtask

  // Synchronous read: set addr, wait one rising edge, then sample dout
  task read_bit(input [3:0] row, input [2:0] col, input bit exp);
  begin
    @(negedge clk);
    addr = make_addr(row, col);
    we_n = 1;           // no write
    @(posedge clk);     // data will be registered here
    #1;                 // small settle
    if (dout !== exp) begin
      $display("READ MISMATCH t=%0t row=%0d col=%0d got=%0b exp=%0b", $time, row, col, dout, exp);
      $fatal(1);
    end else begin
      $display("READ OK t=%0t row=%0d col=%0d val=%0b", $time, row, col, dout);
    end
  end
  endtask

  integer r, c;

  initial begin
    $display("=== SRAM 16x8 Sync TB START ===");
    do_reset();

    // 1) After reset all zeros
    $display("[Phase 1] Reset state = 0");
    for (r = 0; r < 16; r = r + 1)
      for (c = 0; c < 8; c = c + 1)
        read_bit(r, c, 1'b0);

    // 2) Write checkerboard pattern val = (r ^ c) & 1
    $display("[Phase 2] Write checkerboard");
    for (r = 0; r < 16; r = r + 1)
      for (c = 0; c < 8; c = c + 1)
        write_bit(r, c, ((r ^ c) & 1));

    // 3) Read-back & verify checkerboard
    $display("[Phase 3] Read-back & check");
    for (r = 0; r < 16; r = r + 1)
      for (c = 0; c < 8; c = c + 1)
        read_bit(r, c, ((r ^ c) & 1));

    // 4) A couple of overwrite examples (already existed)
    $display("[Phase 4] Overwrite examples");
    write_bit(4'd0,  3'd0, 1'b1);
    write_bit(4'd15, 3'd7, 1'b0);
    read_bit (4'd0,  3'd0, 1'b1);
    read_bit (4'd15, 3'd7, 1'b0);

    // 4a) SHORT Overwrite test (last write wins)
    $display("[Phase 4a] Overwrite (last write wins)");
    write_bit(4'd2, 3'd3, 1'b0);  read_bit(4'd2, 3'd3, 1'b0);
    write_bit(4'd2, 3'd3, 1'b1);  read_bit(4'd2, 3'd3, 1'b1);
    write_bit(4'd2, 3'd3, 1'b0);  read_bit(4'd2, 3'd3, 1'b0);

    // 5) Timing consistency: 1-cycle latency, no mid-cycle glitch
    $display("[Phase 5] Timing consistency");
    // Choose A=(0,1), B=(0,2). Expected values come from checkerboard.
    expA = (4'd0 ^ 3'd1) & 1;    // = 1
    expB = (4'd0 ^ 3'd2) & 1;    // = 0

    // Set A and read on next posedge → expect expA
    @(negedge clk); we_n = 1; addr = make_addr(4'd0, 3'd1);
    @(posedge clk); #1;
    if (dout !== expA) begin
      $display("TIMING ERR(1) t=%0t got=%0b exp=%0b", $time, dout, expA);
      $fatal(1);
    end

    // Mid-cycle change to B; dout must still be the old value (expA)
    @(negedge clk); addr = make_addr(4'd0, 3'd2); #1;
    if (dout !== expA) begin
      $display("GLITCH ERR   t=%0t mid-cycle dout=%0b exp(old)=%0b", $time, dout, expA);
      $fatal(1);
    end

    // On the next posedge, dout should update to expB
    @(posedge clk); #1;
    if (dout !== expB) begin
      $display("TIMING ERR(2) t=%0t got=%0b exp=%0b", $time, dout, expB);
      $fatal(1);
    end else begin
      $display("TIMING OK     t=%0t A->B no-glitch, 1-cycle latency", $time);
    end

    $display("=== SRAM 16x8 Sync TB DONE (PASS) ===");
    $finish;
  end

endmodule
