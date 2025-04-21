/*
 * File: uart_rx_scoreboard.sv
 * Description: UVM Scoreboard for UART RX
 */

class uart_rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_rx_scoreboard)

  // Analysis exports
  uvm_analysis_imp #(uart_rx_seq_item, uart_rx_scoreboard) act_export;

  // Queue to hold expected data
  uart_rx_seq_item exp_queue[$];

  // Virtual interface for access to error flags
  virtual uart_rx_if vif;

  // Error tracking
  int pass_count = 0;
  int fail_count = 0;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    act_export = new("act_export", this);
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_rx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found");
  endfunction

  // Add expected item to queue
  function void add_to_expected_queue(uart_rx_seq_item item);
    exp_queue.push_back(item);
  endfunction

  // Process received item from DUT
  function void write(uart_rx_seq_item item);
    uart_rx_seq_item exp_item;

    if (exp_queue.size() == 0) begin
      `uvm_error("SCB", "Received unexpected data");
      fail_count++;
      return;
    end

    exp_item = exp_queue.pop_front();

    if (item.data === exp_item.data) begin
      `uvm_info("SCB", $sformatf("PASS: Test %0d correctly received 0x%h (%b)",
                        vif.test_num, item.data, item.data), UVM_LOW);
      pass_count++;
    end else begin
      `uvm_error("SCB", $sformatf("FAIL: Test %0d expected 0x%h but received 0x%h",
                       vif.test_num, exp_item.data, item.data));
      `uvm_info("SCB", $sformatf("  Binary expected: %b", exp_item.data), UVM_LOW);
      `uvm_info("SCB", $sformatf("  Binary received: %b", item.data), UVM_LOW);
      fail_count++;
    end
  endfunction

  // Report phase - show results
  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("\n=== Scoreboard Results ==="), UVM_LOW);
    `uvm_info("SCB", $sformatf("Tests Passed: %0d", pass_count), UVM_LOW);
    `uvm_info("SCB", $sformatf("Tests Failed: %0d", fail_count), UVM_LOW);

    if (exp_queue.size() > 0) begin
      `uvm_warning("SCB", $sformatf("%0d expected items not received", exp_queue.size()));
    end
  endfunction
endclass
