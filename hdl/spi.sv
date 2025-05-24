module spi
#(
  parameter BUFFER_BYTES = 4
)
(
  input reg sck_in,

  input wire miso,
  output reg sck_out,
  output reg mosi,
  output reg cs,
  output reg dc,

  input wire [$clog2(BUFFER_BYTES):0]in_bytes_count,
  input wire [$clog2(BUFFER_BYTES):0]out_bytes_count,

  input wire [(BUFFER_BYTES*8) - 1:0]in_bytes,
  output reg [(BUFFER_BYTES*8) - 1:0]out_bytes,

  input wire start_trans,
  output reg trans_done
  );


  localparam idle         = 3'b000;
  localparam trans_write  = 3'b001;
  localparam trans_read   = 3'b010;
  localparam trans_beg    = 3'b011;
  localparam trans_end    = 3'b100;
  localparam trans_inter  = 3'b101;

  reg [2:0] cur_state;

  reg [2:0] bit_counter;

  wire end_req;
  reg old_start;

  reg [2:0] next_state;

  reg [19:0] in_bytes_counter;
  reg [19:0] out_bytes_counter;

  reg en_out;

  initial begin
    dc            <= 1'b0;
    cs            <= 1'b1;
    sck_out       <= 1'b1;
    mosi          <= 1'b0;

    out_bytes     <= 32'h00000000;

    old_start     <= 1'b0;

    bit_counter   <= 3'b111;

    cur_state     <= idle;
    next_state    <= idle;

    in_bytes_counter  <= 0;
    out_bytes_counter <= 0;

    trans_done    <= 1'b1;

    en_out        <= 1'b1;
  end

  assign sck_out = ((en_out == 1'b0) ? sck_in : 1'b1);

always @(posedge sck_in) begin
  case (cur_state)
  idle :
    begin
      if (old_start != start_trans) begin
        old_start     <= start_trans;
        next_state    <= trans_beg;

        in_bytes_counter    <= in_bytes_count;
        out_bytes_counter   <= out_bytes_count;

        trans_done          <= 1'b0;
      end

      cs <= 1'b1;
    end
  trans_beg :
      begin
        cs          <= 1'b0;
        dc          <= 1'b0;
        en_out      <= 1'b0;

        next_state  = trans_write;
      end
  trans_write :
    begin
      if (in_bytes_counter == 0) begin
        if (out_bytes_counter == 0) begin
          bit_counter = 3'b111;

          next_state = trans_end;
        end else begin
          bit_counter = 3'b111;

          next_state = trans_read;
        end
      end else begin
        if (in_bytes_counter <= in_bytes_count - 1) begin
          dc <= 1'b1;
        end
        if (bit_counter == 3'b000) begin
          bit_counter = 3'b111;

          in_bytes_counter = in_bytes_counter - 1;

          if (in_bytes_counter == 0) begin
            bit_counter = 3'b111;
  
            next_state = trans_read;
          end
        end else begin
          bit_counter = bit_counter - 1;
        end
      end
    end
  trans_read :
    begin
      out_bytes[(out_bytes_counter - 1)*8 + bit_counter] <= miso;
      if (out_bytes_counter == 2'b00) begin
        next_state  = trans_end;
      end else begin
        if (bit_counter == 3'b000) begin
          bit_counter = 3'b111;
          out_bytes_counter = out_bytes_counter - 1;
        end else begin
          bit_counter = bit_counter - 1;
        end
      end
    end
  trans_end :
     begin
       if (sck_in == 1'b1) begin
         next_state = idle;

         en_out     <= 1'b1;
         trans_done <= 1'b1;
         dc         <= 1'b0;
       end
     end
  endcase

  cur_state <= next_state;
end

always @(negedge sck_in) begin
  if (cur_state == trans_write) begin
    mosi <= in_bytes[(in_bytes_count - in_bytes_counter)*8 + bit_counter];
  end
end

endmodule
