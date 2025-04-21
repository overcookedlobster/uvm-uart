/*
 * File: uart_rx_top.sv
 * Description: Top-level module for UART receiver
 */

module uart_rx_top #(
  parameter CLK_FREQ_HZ = 50_000_000,   // System clock frequency in Hz
  parameter DEFAULT_BAUD_RATE = 115200,  // Default UART baud rate
  parameter MAX_DATA_BITS = 9,           // Maximum supported data bits
  parameter FIFO_DEPTH = 16,             // FIFO depth
  parameter TIMEOUT_BIT_PERIODS = 10      // Timeout in bit periods
) (
  // Clock and reset
  input  logic                  clk,             // System clock
  input  logic                  rst_n,           // Active-low reset

  // UART input
  input  logic                  rx_in,           // UART RX input signal

  // Receiver data interface
  output logic [MAX_DATA_BITS-1:0] rx_data,      // Received data
  output logic                  rx_data_valid,   // Data valid flag
  input  logic                  rx_data_read,    // Data read acknowledge

  // Status outputs
  output logic                  frame_active,    // Receiver busy (actively receiving)
  output logic                  fifo_full,       // FIFO full flag
  output logic                  fifo_empty,      // FIFO empty flag
  output logic                  fifo_almost_full,// FIFO almost full flag
  output logic [$clog2(FIFO_DEPTH):0] fifo_count,// FIFO data count

  // Error flags
  output logic                  error_detected,  // Any error detected
  output logic                  framing_error,   // Frame error flag
  output logic                  parity_error,    // Parity error flag
  output logic                  break_detect,    // Break condition detected
  output logic                  timeout_detect,  // Timeout detected
  output logic                  overflow_error,  // FIFO overflow error

  // Control inputs
  input  logic                  error_clear,     // Clear error flags
  input  logic                  fifo_clear,      // Clear FIFO

  // Configuration
  input  logic [31:0]           baud_rate,       // Configurable baud rate
  input  logic [3:0]            data_bits,       // Number of data bits (5-9)
  input  logic [1:0]            parity_mode,     // 0=none, 1=odd, 2=even, 3=mark
  input  logic                  stop_bits,       // 0=1 stop bit, 1=2 stop bits
  input  logic                  lsb_first        // 0=MSB first, 1=LSB first
);

  // Internal signals
  logic                tick_16x;         // 16x oversampling tick
  logic                rx_filtered;      // Filtered RX input
  logic                falling_edge;     // Falling edge detection
  logic                bit_sample;       // Sampled bit value
  logic                bit_valid;        // Valid bit indication
  logic                start_detected;   // Start bit detection
  logic                sample_enable;    // Enable signal for shift register
  logic [3:0]          bit_count;        // Current bit position
  logic                is_data_bit;      // Indicates current bit is a data bit
  logic                is_parity_bit;    // Indicates current bit is a parity bit
  logic                is_stop_bit;      // Indicates current bit is a stop bit
  logic                frame_complete;   // Frame reception complete
  logic                frame_error;      // Stop bit error
  logic                parity_err;       // Parity bit error
  logic [MAX_DATA_BITS-1:0] shift_data;  // Data from shift register
  logic                shift_data_valid; // Shift register data valid
  logic                auto_error_clear; // Register to hold auto-clear signal

  // Baud rate generator
  // Generates tick_16x (16x the baud rate)
  logic [31:0] baud_divider;
  logic [31:0] tick_counter;

  // Calculate baud divider - clock frequency divided by (16 * baud rate)
  assign baud_divider = CLK_FREQ_HZ / (16 * (baud_rate > 0 ? baud_rate : DEFAULT_BAUD_RATE));

  // Generate 16x tick
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_counter <= '0;
      tick_16x <= 1'b0;
    end
    else begin
      if (tick_counter >= baud_divider - 1) begin
        tick_counter <= '0;
        tick_16x <= 1'b1;
      end
      else begin
        tick_counter <= tick_counter + 1;
        tick_16x <= 1'b0;
      end
    end
  end

  // Input filter instance
  uart_input_filter input_filter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tick_16x(tick_16x),
    .rx_in(rx_in),
    .rx_filtered(rx_filtered),
    .falling_edge(falling_edge)
  );

  // Bit sampler instance
  uart_bit_sampler bit_sampler_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tick_16x(tick_16x),
    .rx_filtered(rx_filtered),
    .falling_edge(falling_edge),
    .frame_complete(frame_complete),
    .error_clear(error_clear),
    .bit_sample(bit_sample),
    .bit_valid(bit_valid),
    .start_detected(start_detected)
  );

  // State machine instance
  uart_rx_state_machine state_machine_inst (
    .clk(clk),
    .rst_n(rst_n),
    .bit_valid(bit_valid),
    .bit_sample(bit_sample),
    .start_detected(start_detected),
    .data_bits(data_bits),
    .parity_mode(parity_mode),
    .stop_bits(stop_bits),
    .frame_active(frame_active),
    .sample_enable(sample_enable),
    .bit_count(bit_count),
    .is_data_bit(is_data_bit),
    .is_parity_bit(is_parity_bit),
    .is_stop_bit(is_stop_bit),
    .frame_complete(frame_complete),
    .frame_error(frame_error),
    .parity_error(parity_err),
    .error_clear(error_clear || auto_error_clear)
  );

  // Shift register instance
  uart_rx_shift_register #(
    .MAX_DATA_BITS(MAX_DATA_BITS)
  ) shift_register_inst (
    .clk(clk),
    .rst_n(rst_n),
    .sample_enable(sample_enable),
    .bit_sample(bit_sample),
    .bit_count(bit_count),
    .is_data_bit(is_data_bit),
    .frame_complete(frame_complete),
    .data_bits(data_bits),
    .lsb_first(lsb_first),
    .rx_data(shift_data),
    .data_valid(shift_data_valid)
  );

  // Error manager instance
  uart_error_manager #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .TIMEOUT_BIT_PERIODS(TIMEOUT_BIT_PERIODS)
  ) error_manager_inst (
    .clk(clk),
    .rst_n(rst_n),
    .frame_error(frame_error),
    .parity_error(parity_err),
    .frame_active(frame_active),
    .bit_valid(bit_valid),
    .rx_filtered(rx_filtered),
    .baud_rate(baud_rate),
    .error_clear(error_clear),
    .error_detected(error_detected),
    .framing_error(framing_error),
    .parity_err(parity_error),
    .break_detect(break_detect),
    .timeout_detect(timeout_detect)
  );

  // FIFO instance
  uart_rx_fifo #(
    .DATA_WIDTH(MAX_DATA_BITS),
    .FIFO_DEPTH(FIFO_DEPTH),
    .ALMOST_FULL_THRESHOLD(FIFO_DEPTH-4)
  ) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .write_data(shift_data),
    .write_en(shift_data_valid),
    .read_data(rx_data),
    .read_en(rx_data_read),
    .fifo_clear(fifo_clear),
    .fifo_empty(fifo_empty),
    .fifo_full(fifo_full),
    .fifo_almost_full(fifo_almost_full),
    .overflow(overflow_error),
    .data_count(fifo_count)
  );

  // Generate rx_data_valid from FIFO empty status
  assign rx_data_valid = !fifo_empty;

  // Additional logic to clear errors when a new start bit is detected
  // This ensures errors don't prevent new data reception
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      auto_error_clear <= 1'b0;
    end
    else begin
      // Clear errors automatically when a new start bit is detected
      if (start_detected) begin
        auto_error_clear <= 1'b1;
      end else begin
        auto_error_clear <= 1'b0;
      end
    end
  end

endmodule
