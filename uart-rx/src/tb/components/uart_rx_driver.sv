/*
 * File: uart_rx_driver.sv
 * Description: UVM Driver for UART RX
 */

class uart_rx_driver extends uvm_driver #(uart_rx_seq_item);
  `uvm_component_utils(uart_rx_driver)

  // Virtual interface reference
  virtual uart_rx_if vif;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase - get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_rx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found");
  endfunction

  // Run phase - drive UART signals based on transactions
  task run_phase(uvm_phase phase);
    // Initial values
    vif.rx_in = 1; // Idle state

    forever begin
      uart_rx_seq_item item;

      // Get the next item from the sequencer
      seq_item_port.get_next_item(item);

      // Process the item based on its type
      if (item.break_condition) begin
        drive_break_condition(item);
      end
      else if (item.inject_framing_error) begin
        drive_uart_char_with_error(item, 0); // 0 for framing error
      end else begin
        drive_uart_char(item);
      end

      // Signal item completion
      seq_item_port.item_done();
    end
  endtask

  // Task to drive a normal UART character
  task drive_uart_char(uart_rx_seq_item item);
    // Set expected data first
    vif.expected_data = item.data;
    `uvm_info("DRV", $sformatf("Sending char: 0x%h (%b)", item.data, item.data), UVM_MEDIUM);

    // Update test number for monitoring
    vif.test_num = vif.test_num + 1;

    // Clear errors before sending
    clear_all_errors();

    // Ensure we're in idle state before starting
    vif.rx_in = 1'b1;
    repeat(10) @(posedge vif.clk);

    // Start bit (low)
    vif.rx_in = 1'b0;
    $display("  Start bit: 0");
    #(vif.bit_period_ns);

    // Data bits (LSB first or MSB first)
    for (int i = 0; i < 8; i++) begin
      if (vif.lsb_first) begin
        vif.rx_in = item.data[i];
        $display("  Data bit %0d: %0b", i, item.data[i]);
      end else begin
        vif.rx_in = item.data[7-i];
        $display("  Data bit %0d: %0b", 7-i, item.data[7-i]);
      end
      #(vif.bit_period_ns);
    end

    // Stop bit
    vif.rx_in = 1'b1;
    $display("  Stop bit: 1");
    #(vif.bit_period_ns);

    // Add idle time between characters
    #(vif.bit_period_ns * 5);

    // Wait for signal to be captured by the DUT
    repeat(20) @(posedge vif.clk);
  endtask

  // Task to drive UART with framing error
  task drive_uart_char_with_error(uart_rx_seq_item item, bit stop_bit_value);
    `uvm_info("DRV", $sformatf("Sending char with %s stop bit: 0x%h (%b)",
                               stop_bit_value ? "correct" : "INVALID", item.data, item.data), UVM_MEDIUM);

    // Update test number for monitoring
    vif.test_num = vif.test_num + 1;

    // Clear errors before sending
    clear_all_errors();

    // Ensure we're in idle state before starting
    vif.rx_in = 1'b1;
    repeat(10) @(posedge vif.clk);

    // Start bit (low)
    vif.rx_in = 1'b0;
    $display("  Start bit: 0");
    #(vif.bit_period_ns);

    // Data bits (LSB first or MSB first)
    for (int i = 0; i < 8; i++) begin
      if (vif.lsb_first) begin
        vif.rx_in = item.data[i];
        $display("  Data bit %0d: %0b", i, item.data[i]);
      end else begin
        vif.rx_in = item.data[7-i];
        $display("  Data bit %0d: %0b", 7-i, item.data[7-i]);
      end
      #(vif.bit_period_ns);
    end

    // Stop bit with error injection
    vif.rx_in = stop_bit_value;
    $display("  Stop bit: %0b %s", stop_bit_value, stop_bit_value ? "" : "(ERROR INJECTED)");
    #(vif.bit_period_ns);

    // Return to idle state
    vif.rx_in = 1'b1;
    $display("  Return to idle state");

    // Add idle time between characters
    #(vif.bit_period_ns * 5);

    // Wait for signal to be captured by the DUT
    repeat(20) @(posedge vif.clk);
  endtask

  // Task to drive a break condition
  task drive_break_condition(uart_rx_seq_item item);
    `uvm_info("DRV", "Injecting break condition (extended low signal)", UVM_MEDIUM);

    // Update test number for monitoring
    vif.test_num = vif.test_num + 1;

    // Clear errors before sending
    clear_all_errors();

    // Ensure we start from idle
    vif.rx_in = 1'b1;
    #(vif.bit_period_ns * 2);

    // Start bit
    vif.rx_in = 1'b0;
    #(vif.bit_period_ns);

    // Hold line low for entire frame plus extra time
    vif.rx_in = 1'b0;
    #(vif.bit_period_ns * 15);

    // Return to idle
    vif.rx_in = 1'b1;
    #(vif.bit_period_ns * 5);

    // Wait for signal to be captured by the DUT
    repeat(20) @(posedge vif.clk);
  endtask

  // Task to clear all errors
  task clear_all_errors();
    $display("Forcing error clear at time %t", $time);

    // Clear errors and FIFO with clocking
    @(posedge vif.clk);
    vif.error_clear = 1'b1;
    vif.fifo_clear = 1'b1;
    repeat(10) @(posedge vif.clk);
    vif.error_clear = 1'b0;
    vif.fifo_clear = 1'b0;
    repeat(10) @(posedge vif.clk);

    // Force a complete reset if needed
    if (vif.error_detected) begin
      $display("Errors still present, performing full reset");
      @(posedge vif.clk);
      vif.rst_n = 0;
      repeat(20) @(posedge vif.clk);
      vif.rst_n = 1;
      repeat(20) @(posedge vif.clk);
    end
  endtask
endclass
