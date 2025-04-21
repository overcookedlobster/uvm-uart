/*
 * File: uart_tx_uvm_tb.sv
 * Description: Top module for UVM UART TX testbench
 */

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_tx_pkg::*;

module uart_tx_uvm_tb;
  // Parameters
  localparam CLK_PERIOD = 20; // 50MHz clk
  localparam BAUD_RATE = 115200;

  // Signals
  logic clk;
  logic rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #(CLK_PERIOD * 5);
    rst_n = 1;
  end

  // Interface
  uart_tx_if vif(clk, rst_n);

  // Baudrate generator
  baudrate_gen #(
    .CLK_FREQ_HZ(50_000_000),
    .BAUD_RATE(BAUD_RATE),
    .OVERSAMPLING(16)
  ) baudgen (
    .clk(clk),
    .rst_n(rst_n),
    .enable(1'b1),
    .tick(vif.tick),
    .tick_16x(vif.tick_16x)
  );

  // DUT instance
  uart_tx #(
    .DATA_BITS(8),
    .PARITY_EN(1),
    .PARITY_TYPE(0),
    .STOP_BITS(1)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .tick(vif.tick),
    .tx_start(vif.tx_start),
    .cts(vif.cts),
    .tx_data(vif.tx_data),
    .tx_out(vif.tx_out),
    .tx_busy(vif.tx_busy),
    .tx_done(vif.tx_done)
  );

  // Access internal signals (for debugging)
  assign vif.tx_start_pending = dut.tx_start_pending;

  // Start UVM test
  initial begin
    // Set interface in config database
    uvm_config_db#(virtual uart_tx_if)::set(null, "*", "vif", vif);

    // Run test
    run_test("uart_tx_test");
  end

  // Timeout
  initial begin
    #(CLK_PERIOD * 1000000);
    $display("Testbench timeout - something went wrong!");
    $finish;
  end

  // Waveform dumping
  initial begin
    $dumpfile("uart_tx_uvm_tb.vcd");
    $dumpvars(0, uart_tx_uvm_tb);
  end
endmodule

