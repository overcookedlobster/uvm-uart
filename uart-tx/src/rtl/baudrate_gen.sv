/*
 * File: baudrate_gen.sv
 * Description: Configurable baud rate generator for UART communication
 */

module baudrate_gen #(
  parameter int CLK_FREQ_HZ = 50_000_000,
  parameter int BAUD_RATE = 9600,
  parameter int OVERSAMPLING = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  output logic tick,
  output logic tick_16x
);

  // Counter divider calculation
  localparam int BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE - 1;
  localparam int BAUD_DIV_16X = CLK_FREQ_HZ / (BAUD_RATE * OVERSAMPLING) - 1;

  // Counter width calculation
  localparam int BAUD_CNT_WIDTH = $clog2(BAUD_DIV + 1);
  localparam int BAUD_CNT_16X_WIDTH = $clog2(BAUD_DIV_16X + 1);

  // Baud rate counters
  logic [BAUD_CNT_WIDTH-1:0] baud_counter;
  logic [BAUD_CNT_16X_WIDTH-1:0] baud_counter_16x;

  // 1x tick baudgen
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_counter <= '0;
      tick <= 1'b0;
    end else if (enable) begin
      if (baud_counter == BAUD_DIV) begin
        baud_counter <= '0;
        tick <= 1'b1;
      end else begin
        baud_counter <= baud_counter + 1'b1;
        tick <= 1'b0;
      end
    end else begin
      // When disabled, reset counter and do not generate tick
      baud_counter <= '0;
      tick <= 1'b0;
    end
  end

  // 16x tick baudgen for RX module
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_counter_16x <= '0;
      tick_16x <= 1'b0;
    end else if (enable) begin
      if (baud_counter_16x == BAUD_DIV_16X) begin
        baud_counter_16x <= '0;
        tick_16x <= 1'b1;
      end else begin
        baud_counter_16x <= baud_counter_16x + 1'b1;
        tick_16x <= 1'b0;
      end
    end else begin
      // When disabled, reset counter and do not generate tick
      baud_counter_16x <= '0;
      tick_16x <= 1'b0;
    end
  end

  // Debug display
  initial begin
    $display("Baud Rate Generator Configuration:");
    $display("  CLK_FREQ_HZ = %0d", CLK_FREQ_HZ);
    $display("  BAUD_RATE = %0d", BAUD_RATE);
    $display("  OVERSAMPLING = %0d", OVERSAMPLING);
    $display("  BAUD_DIV = %0d", BAUD_DIV);
    $display("  BAUD_DIV_16X = %0d", BAUD_DIV_16X);
  end

endmodule

