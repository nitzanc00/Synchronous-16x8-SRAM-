module sense_amp (
  input  bitline_in,
  output dout
);
  assign dout = bitline_in; // digital abstraction of analog SA
endmodule