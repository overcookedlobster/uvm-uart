/*
 * File: uart_error_manager.sv
 * Description: Error detection and management for UART receiver
 */

module uart_error_manager #(
  parameter CLK_FREQ_HZ    = 100_000_000,  // Default 100 MHz system clock
  parameter TIMEOUT_BIT_PERIODS = 3,       // Timeout in bit periods (idle time)
  parameter BREAK_MIN_BIT_PERIODS = 11     // Minimum bit periods for break detection
) (
  input  logic        clk,             // System clock
  input  logic        rst_n,           // Active-low reset

  // Error inputs from state machine
  input  logic        frame_error,     // Stop bit error from state machine
  input  logic        parity_error,    // Parity error from state machine
  input  logic        frame_active,    // Active frame indicator
  input  logic        bit_valid,       // Valid bit indication
  input  logic        rx_filtered,     // Filtered RX input

  // Configuration
  input  logic [31:0] baud_rate,       // Current baud rate setting
  input  logic        error_clear,     // Clear error flags

  // Error outputs
  output logic        error_detected,  // Any error detected
  output logic        framing_error,   // Framing error status
  output logic        parity_err,      // Parity error status
  output logic        break_detect,    // Break condition detected
  output logic        timeout_detect   // Timeout detected
);

  // Calculated timeout in clock cycles
  logic [31:0] timeout_cycles;
  logic [31:0] idle_counter;
  logic        prev_frame_active;
  logic        prev_rx;

  // Break detection - looking for sustained low signal
  logic [31:0] break_counter;       // Count of consecutive low cycles

  // Calculate timeout based on baud rate
  // Number of clock cycles in one bit period = CLK_FREQ_HZ / baud_rate
  // Total timeout = bit period * TIMEOUT_BIT_PERIODS
  assign timeout_cycles = (CLK_FREQ_HZ / baud_rate) * TIMEOUT_BIT_PERIODS;

  // Error detection and latching
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      framing_error <= 1'b0;
      parity_err <= 1'b0;
      break_detect <= 1'b0;
      timeout_detect <= 1'b0;
      error_detected <= 1'b0;

      idle_counter <= '0;
      prev_frame_active <= 1'b0;
      prev_rx <= 1'b1;  // Idle high state
      break_counter <= '0;
    end
    else begin
      // Previous state tracking
      prev_frame_active <= frame_active;
      prev_rx <= rx_filtered;

      // Clear errors on external request
      if (error_clear) begin
        framing_error <= 1'b0;
        parity_err <= 1'b0;
        break_detect <= 1'b0;
        timeout_detect <= 1'b0;
        error_detected <= 1'b0;
        break_counter <= '0;
        idle_counter <= '0;  // Also reset idle counter when clearing errors
      end

      // ------------------------------------------------------------------------
      // Framing Error Detection - Directly from state machine
      // ------------------------------------------------------------------------
      if (frame_error) begin
        framing_error <= 1'b1;
      end

      // ------------------------------------------------------------------------
      // Parity Error Detection - Directly from state machine
      // ------------------------------------------------------------------------
      if (parity_error) begin
        parity_err <= 1'b1;
      end

      // ------------------------------------------------------------------------
      // BREAK DETECTION
      // ------------------------------------------------------------------------
      // Count consecutive low cycles
      if (!rx_filtered) begin
        // Line is low - increment counter
        if (break_counter < 32'hFFFFFFFF) begin // Prevent overflow
          break_counter <= break_counter + 1'b1;
        end

        // Calculate threshold based on clock frequency and baud rate
        // BREAK_MIN_BIT_PERIODS * (CLK_FREQ_HZ / baud_rate) is the number of
        // clock cycles equivalent to the minimum break duration
        if (break_counter >= ((CLK_FREQ_HZ / baud_rate) * BREAK_MIN_BIT_PERIODS)) begin
          break_detect <= 1'b1;

          // Break condition takes precedence over framing error
          // since a break will always cause a framing error
          framing_error <= 1'b0;
        end
      end
      else begin
        // Reset counter when line goes high (end of break condition)
        break_counter <= '0;
      end

      // ------------------------------------------------------------------------
      // Timeout Detection
      // ------------------------------------------------------------------------
      // Reset counter when we're in a frame or see any activity
      if (frame_active || (prev_rx != rx_filtered)) begin
        idle_counter <= '0;
        timeout_detect <= 1'b0;  // Clear timeout when activity is detected
      end else begin
        // Increment counter in idle state
        if (idle_counter < timeout_cycles && rx_filtered) begin
          idle_counter <= idle_counter + 1'b1;
        end

        // Only detect timeout if we're truly idle for a very long time
        // and ONLY if we're not already detecting another type of error
        if (idle_counter >= (timeout_cycles - 1) &&
            !framing_error && !parity_err && !break_detect && rx_filtered) begin
          timeout_detect <= 1'b1;
        end
      end

      // Setting error_detected when any error is active
      error_detected <= framing_error || parity_err || break_detect || timeout_detect;
    end
  end
endmodule
