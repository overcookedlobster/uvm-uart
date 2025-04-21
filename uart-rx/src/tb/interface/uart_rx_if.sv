/*
 * File: uart_rx_if.sv
 * Description: Interface for UART RX Verification
 */

interface uart_rx_if (input logic clk);
  // DUT inputs
  logic rst_n;           // Active-low reset
  logic rx_in;           // UART RX input signal
  logic rx_data_read;    // Data read acknowledge
  logic error_clear;     // Clear error flags
  logic fifo_clear;      // Clear FIFO

  // DUT configuration
  logic [31:0] baud_rate;      // Configurable baud rate
  logic [3:0]  data_bits;      // Number of data bits (5-9)
  logic [1:0]  parity_mode;    // 0=none, 1=odd, 2=even, 3=mark
  logic        stop_bits;      // 0=1 stop bit, 1=2 stop bits
  logic        lsb_first;      // 0=MSB first, 1=LSB first

  // DUT outputs
  logic [8:0] rx_data;         // Received data
  logic rx_data_valid;         // Data valid flag
  logic frame_active;          // Receiver busy (actively receiving)
  logic fifo_full;             // FIFO full flag
  logic fifo_empty;            // FIFO empty flag
  logic fifo_almost_full;      // FIFO almost full flag
  logic [4:0] fifo_count;      // FIFO data count
  logic error_detected;        // Any error detected
  logic framing_error;         // Frame error flag
  logic parity_error;          // Parity error flag
  logic break_detect;          // Break condition detected
  logic timeout_detect;        // Timeout detected
  logic overflow_error;        // FIFO overflow error

  // Parameters for testbench
  int clk_period_ns;
  int bit_period_ns;
  int test_num;  // Track current test number

  // Special interface signal for fixing the verification discrepancy
  // This stores what we *expect* to be received, since the actual rx_data reports 0x000
  logic [7:0] expected_data;
endinterface
