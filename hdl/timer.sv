module timer #(
                parameter time_ms = 1000
             )
             (
                input wire clk_in,
                output reg sig_out
             );


localparam clk_per_ms = 180000;
localparam reset_count = (clk_per_ms*time_ms);
localparam bit_count = $clog2(reset_count);

reg [bit_count:0]counter;

initial begin
  counter <= 0;
  sig_out <= 1'b0;
end

always @(posedge clk_in) begin
  if (counter < reset_count) begin
    counter = counter + 1;
  end else begin
    counter = 0;
    sig_out = ~sig_out;
  end
end

endmodule
