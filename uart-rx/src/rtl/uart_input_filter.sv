/*
 * File: uart_input_filter.sv
 * Description: Input filtering and synchronization for UART receiver
 */

module uart_input_filter (
  input  logic clk,         // System clock
  input  logic rst_n,       // Active-low reset
  input  logic tick_16x,    // 16x oversampling tick
  input  logic rx_in,       // Raw serial input
  output logic rx_filtered, // Filtered serial input
  output logic falling_edge // Falling edge detection signal
);

  // Double-flop synchronizer for rx_in to prevent metastability
  logic rx_in_meta;         // First stage of synchronization
  logic rx_in_sync;         // Second stage of synchronization
  logic rx_in_prev;         // Previous filtered value for edge detection

  // Shift register for filtering
  logic [2:0] rx_in_history;  // Last 3 samples for majority voting

  // Double-flop synchronizer for rx_in - operates on every clock cycle
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Initialize to idle state (line high)
      rx_in_meta <= 1'b1;
      rx_in_sync <= 1'b1;
    end else begin
      // Two-stage synchronization
      rx_in_meta <= rx_in;
      rx_in_sync <= rx_in_meta;
    end
  end

  // History tracking and filtering - operates on tick_16x
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Initialize to idle state (line high)
      rx_in_history <= 3'b111;
      rx_filtered <= 1'b1;
      rx_in_prev <= 1'b1;
      falling_edge <= 1'b0;
    end else if (tick_16x) begin
      // Save previous filtered value for edge detection
      rx_in_prev <= rx_filtered;

      // Shift history register to track the last 3 samples
      rx_in_history <= {rx_in_history[1:0], rx_in_sync};

      // Majority vote filtering: output is high if 2 or more of the last 3 samples are high
      rx_filtered <= (rx_in_history[0] & rx_in_history[1]) |
                     (rx_in_history[1] & rx_in_sync) |
                     (rx_in_history[0] & rx_in_sync);

      // Detect falling edge - when previous filtered value was high and current is low
      falling_edge <= rx_in_prev & ~((rx_in_history[0] & rx_in_history[1]) |
                                    (rx_in_history[1] & rx_in_sync) |
                                    (rx_in_history[0] & rx_in_sync));
    end else begin
      // Clear edge detection signal after one clock cycle
      falling_edge <= 1'b0;
    end
  end

endmodule
