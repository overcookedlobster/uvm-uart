/*
 * File: uart_rx_shift_register.sv
 * Description: Shift register for collecting serial data in UART receiver
 */

module uart_rx_shift_register #(
  parameter MAX_DATA_BITS = 9
)(
  input  logic                     clk,             // System clock
  input  logic                     rst_n,           // Active-low reset
  input  logic                     sample_enable,   // From state machine - enable bit sampling
  input  logic                     bit_sample,      // Sampled bit value from bit sampler
  input  logic [3:0]               bit_count,       // Current bit position from state machine
  input  logic                     is_data_bit,     // Indicates current bit is a data bit
  input  logic                     frame_complete,  // Pulse indicating frame reception complete
  input  logic [3:0]               data_bits,       // Configuration: number of data bits (5-9)
  input  logic                     lsb_first,       // Configuration: 0=MSB first, 1=LSB first

  output logic [MAX_DATA_BITS-1:0] rx_data,         // Received data (up to MAX_DATA_BITS bits)
  output logic                     data_valid       // Indicates data is valid to read
);

  // Internal shift register to accumulate bits
  logic [MAX_DATA_BITS-1:0] shift_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset state
      shift_reg <= '0;
      rx_data <= '0;
      data_valid <= 1'b0;
    end
    else begin
      // Default behavior - data_valid is one-cycle pulse
      data_valid <= 1'b0;

      // Process incoming bits during active frame
      if (sample_enable && is_data_bit) begin
        if (lsb_first) begin
          // Properly update the shift register preserving all other bits
          // Create a mask with a 1 only at the position we want to update
          // Then clear that bit and set it to the new value
          shift_reg[bit_count] <= bit_sample;
        end
        else begin
          // MSB first mode - calculate the correct bit position
          shift_reg[data_bits-1-bit_count] <= bit_sample;
        end
      end

      // When frame is complete, output the data with valid signal
      if (frame_complete) begin
        // Apply the mask to only include valid data bits
        rx_data <= shift_reg & ((1'b1 << data_bits) - 1'b1);
        data_valid <= 1'b1;
      end
    end
  end
endmodule
