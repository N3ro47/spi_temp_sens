module top
  (
    input btn_0,
    input sys_clk_pin,
    input phy_miso_eink,
    input phy_miso_adc,
    input phy_miso_temp,

    output led_0,
    output phy_sck_eink,
    output phy_mosi_eink,
    output phy_sck_adc,
    output phy_mosi_adc,
    output phy_sck_temp,
    output phy_mosi_temp,
    output phy_temp_cs,
    output phy_eink_cs,
    output phy_adc_cs,
    output phy_eink_dc,
    output [2:0]led
  );

wire clk_scaled;
wire dummy_dc_temp;

wire [15:0]bcd_reg;
reg [23:0]in_bytes_count;
reg [23:0]out_bytes_count;

reg [32007:0]in_bytes;
wire [31:0]out_bytes;

wire led_inter;

reg start_temp_trans;
reg start_eink_trans;
reg start_adc_trans;

wire trans_temp_done;
wire trans_eink_done;
wire trans_adc_done;

localparam check_con     = 3'b000;
localparam set_options   = 3'b001;
localparam chk_options   = 3'b010;
localparam eink_init     = 3'b011;
localparam read_temp     = 3'b100;
localparam read_adc      = 3'b110;
localparam display_temp  = 3'b101;

localparam eink_xaddr    = 3'b000;
localparam eink_yaddr    = 3'b001;
localparam eink_data_s   = 3'b010;
localparam eink_refr_0   = 3'b011;
localparam eink_refr_1   = 3'b111;

reg [2:0] cur_state;
reg [2:0] eink_data_state;
reg led_reg;
reg en_dis;

wire[31999:0] eink_data;

assign led_0 = led_reg;

wire adv_sm;

initial begin
  in_bytes_count    =     2'b01;
  out_bytes_count   =     2'b01;
  in_bytes          =     8'h01;
  led_reg           =     1'b0;
  cur_state         =     eink_init;
  en_dis            =     1'b0;
  eink_data_state   =     eink_xaddr;
end

reg [23:0]temp_data;
reg [15:0]adc_data;

assign led = cur_state;

always @(posedge adv_sm) begin
  case (cur_state)
    check_con:
      begin
        if (out_bytes[7:0] == 8'h03) begin
          cur_state   <= set_options;
          in_bytes_count        <= 3;
          out_bytes_count       <= 0;
          in_bytes[7:0]         <= 8'h03;
          in_bytes[15:8]        <= 8'h81;
          in_bytes[23:16]       <= 8'h80;
        end
        led_reg     <= ~led_reg;
        start_temp_trans = ~start_temp_trans;
      end
    set_options:
      begin
          in_bytes_count        <= 3;
          out_bytes_count       <= 0;
          in_bytes[7:0]         <= 8'h03;
          in_bytes[15:8]        <= 8'h81;
          in_bytes[23:16]       <= 8'h80;
          led_reg               <= 1'b1;
          cur_state             <= chk_options;
          start_temp_trans = ~start_temp_trans;
      end
    chk_options:
      begin
          in_bytes_count        <= 2'b01;
          out_bytes_count       <= 2'b10;
          in_bytes[7:0]         <= 8'h00;
          if (out_bytes[15:8] == 8'h81 && out_bytes[7:0] == 8'h03) begin
            cur_state <= eink_init;
            en_dis    <= 1'b1;
          end
          start_temp_trans = ~start_temp_trans;
      end           // Initialisation of temp sensor done
    read_temp:
      begin
          start_temp_trans = ~start_temp_trans;
          in_bytes_count        <= 2'b01;
          out_bytes_count       <= 2'b10;
          in_bytes[7:0]         <= 8'h0C;
          if (out_bytes[15:8] == 8'h81 && out_bytes[7:0] == 8'h03) begin
            cur_state <= read_temp;
          end
      end
    read_adc:
      begin
          temp_data             <= out_bytes[23:0];
          in_bytes_count        <= 2'b00;
          out_bytes_count       <= 2'b10;

          cur_state             <= eink_init;
          start_adc_trans       <= ~start_adc_trans;
      end
    eink_init:
      begin
        case (eink_data_state) 
          eink_xaddr:
          begin
            temp_data             <= out_bytes[15:0];

            led_reg               <= 1'b0;
            in_bytes_count        <= 2;
            out_bytes_count       <= 0;

            in_bytes[7:0]         <= 8'h4E;
            in_bytes[15:8]        <= 8'h01;

            eink_data_state       <= eink_yaddr;
            start_eink_trans = ~start_eink_trans;

          end
          eink_yaddr:
          begin 
            in_bytes_count        <= 3;
            out_bytes_count       <= 0;

            in_bytes[7:0]         <= 8'h4F;
            in_bytes[15:8]        <= 8'h00;
            in_bytes[23:16]       <= 8'h00;

            eink_data_state       <= eink_data_s;
            start_eink_trans = ~start_eink_trans;

          end
          eink_data_s:
          begin
            in_bytes_count        <= 4001;
            out_bytes_count       <= 0;

            in_bytes[7:0]         <= 8'h24;
            in_bytes[32007:8]     <= eink_data;

            start_eink_trans = ~start_eink_trans;

            eink_data_state       <= eink_refr_0;
          end
          eink_refr_0:
          begin
            in_bytes_count        <= 2;
            out_bytes_count       <= 0;

            in_bytes[7:0]         <= 8'h22;
            in_bytes[15:8]        <= 8'hF7;


            start_eink_trans = ~start_eink_trans;

            eink_data_state       <= eink_refr_1;
          end
          eink_refr_1:
          begin
            in_bytes_count        <= 1;
            out_bytes_count       <= 0;

            in_bytes[7:0]         <= 8'h20;

            eink_data_state       <= eink_xaddr;


            cur_state             <= read_temp;
            led_reg               <= 1'b1;

          end
        endcase
      end
  endcase
end

presc#(.VALUE(127))     pre0
          (
            .clk_in_p(sys_clk_pin),
            .clk_out_p(clk_scaled)
          );

timer#(.time_ms(400))   tim_sb
          (
            .clk_in(sys_clk_pin),
            .sig_out(adv_sm)
          );

spi       temp_spi
          (
            .sck_in(clk_scaled),
            .miso(phy_miso_temp),
            .sck_out(phy_sck_temp),
            .mosi(phy_mosi_temp),
            .cs(phy_temp_cs),
            .dc(dummy_dc_temp),
            .in_bytes_count(in_bytes_count[2:0]),
            .out_bytes_count(out_bytes_count[2:0]),
            .in_bytes(in_bytes[31:0]),
            .out_bytes(out_bytes),
            .start_trans(start_temp_trans),
            .trans_done(trans_temp_done)
          );

eink_data  e_data
          (
            .bcd_values(bcd_reg),
            .data(eink_data)
          );

spi #(.BUFFER_BYTES(4001)) eink_spi 
          (
            .sck_in(clk_scaled),
            .miso(phy_miso_eink),
            .sck_out(phy_sck_eink),
            .mosi(phy_mosi_eink),
            .cs(phy_eink_cs),
            .dc(phy_eink_dc),
            .in_bytes_count(in_bytes_count),
            .out_bytes_count(out_bytes_count),
            .in_bytes(in_bytes),
            .out_bytes(out_bytes),
            .start_trans(start_eink_trans),
            .trans_done(trans_eink_done)
          );

bcd_register reg0
          (
            .spi_data(out_bytes[27:4]),
            .new_data_triger(trans_temp_done),
            .bcd_values(bcd_reg)
          );

endmodule
