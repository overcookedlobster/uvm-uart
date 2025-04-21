/*
 * File: uart_rx_uvm_tb.sv
 * Description: Top module for UVM UART RX testbench
 */

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_rx_pkg::*;

module uart_rx_uvm_tb;
  // Parameters
  parameter CLK_FREQ_HZ = 50_000_000;  // 50 MHz system clock
  parameter BAUD_RATE = 115200;        // 115.2 KBaud
  parameter CLK_PERIOD_NS = 1_000_000_000 / CLK_FREQ_HZ;  // Clock period in ns
  parameter MAX_DATA_BITS = 9;
  parameter FIFO_DEPTH = 16;

  // Clock generation
  bit clk;
  initial begin
    clk = 0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // Interface instance
  uart_rx_if vif(clk);

  // DUT instantiation
  uart_rx_top #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .DEFAULT_BAUD_RATE(BAUD_RATE),
    .MAX_DATA_BITS(MAX_DATA_BITS),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk(clk),
    .rst_n(vif.rst_n),
    .rx_in(vif.rx_in),
    .rx_data(vif.rx_data),
    .rx_data_valid(vif.rx_data_valid),
    .rx_data_read(vif.rx_data_read),
    .frame_active(vif.frame_active),
    .fifo_full(vif.fifo_full),
    .fifo_empty(vif.fifo_empty),
    .fifo_almost_full(vif.fifo_almost_full),
    .fifo_count(vif.fifo_count),
    .error_detected(vif.error_detected),
    .framing_error(vif.framing_error),
    .parity_error(vif.parity_error),
    .break_detect(vif.break_detect),
    .timeout_detect(vif.timeout_detect),
    .overflow_error(vif.overflow_error),
    .error_clear(vif.error_clear),
    .fifo_clear(vif.fifo_clear),
    .baud_rate(vif.baud_rate),
    .data_bits(vif.data_bits),
    .parity_mode(vif.parity_mode),
    .stop_bits(vif.stop_bits),
    .lsb_first(vif.lsb_first)
  );

  // VCD dump file handling
  initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_uvm_tb);
  end

  // Initial values for interface signals
  initial begin
    vif.rst_n = 0;
    vif.rx_in = 1;  // Idle state is high
    vif.rx_data_read = 0;
    vif.error_clear = 0;
    vif.fifo_clear = 0;
    vif.test_num = 0;

    // Clear any FIFO configuration signals we might have missed
    vif.baud_rate = BAUD_RATE;
    vif.data_bits = 8;
    vif.parity_mode = 2'b00;
    vif.stop_bits = 0;
    vif.lsb_first = 1;
  end

  // Monitor signals of interest
  always @(posedge vif.frame_active) $display("Frame active at time %t (Test %0d)", $time, vif.test_num);
  always @(negedge vif.frame_active) $display("Frame inactive at time %t (Test %0d)", $time, vif.test_num);
  always @(posedge vif.rx_data_valid) $display("Data valid at time %t: 0x%h (Test %0d)", $time, vif.rx_data, vif.test_num);
  always @(posedge vif.error_detected) $display("ERROR detected at time %t: framing=%b, parity=%b, break=%b, timeout=%b, overflow=%b (Test %0d)",
                                          $time, vif.framing_error, vif.parity_error, vif.break_detect,
                                          vif.timeout_detect, vif.overflow_error, vif.test_num);
  always @(posedge vif.break_detect) begin
    $display("*** BREAK CONDITION DETECTED at time %t (Test %0d) ***", $time, vif.test_num);
  end

  // Start UVM test
  initial begin
    // Set virtual interface in config DB
    uvm_config_db#(virtual uart_rx_if)::set(null, "*", "vif", vif);

    // Run either all tests or a specific test
    run_test("run_all_tests");
  end
endmodule
