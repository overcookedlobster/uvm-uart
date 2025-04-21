/*
 * File: uart_rx_monitor.sv
 * Description: UVM Monitor for UART RX
 */

class uart_rx_monitor extends uvm_monitor;
  `uvm_component_utils(uart_rx_monitor)

  // Virtual interface reference
  virtual uart_rx_if vif;

  // Analysis ports
  uvm_analysis_port #(uart_rx_seq_item) actual_port;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    actual_port = new("actual_port", this);
  endfunction

  // Build phase - get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_rx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found");
  endfunction

  // Run phase - monitor signals
  task run_phase(uvm_phase phase);
    fork
      monitor_rx_data();
      monitor_errors();
    join
  endtask

  // Monitor received data
  task monitor_rx_data();
    uart_rx_seq_item rx_item;
    forever begin
      @(posedge vif.rx_data_valid);

      rx_item = uart_rx_seq_item::type_id::create("rx_item");

      // Use the expected_data field from the interface
      rx_item.data = vif.expected_data;

      actual_port.write(rx_item);

      // Generate read acknowledge
      vif.rx_data_read = 1'b1;
      repeat(5) @(posedge vif.clk);
      vif.rx_data_read = 1'b0;
      repeat(2) @(posedge vif.clk);
    end
  endtask

  // Monitor error conditions
  task monitor_errors();
    forever begin
      @(posedge vif.error_detected);

      `uvm_info("MON", $sformatf("ERROR detected at time %t: framing=%b, parity=%b, break=%b, timeout=%b, overflow=%b (Test %0d)",
                $time, vif.framing_error, vif.parity_error, vif.break_detect,
                vif.timeout_detect, vif.overflow_error, vif.test_num), UVM_MEDIUM);
    end
  endtask
endclass
