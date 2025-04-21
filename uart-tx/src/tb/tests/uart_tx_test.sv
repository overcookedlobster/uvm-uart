/*
 * File: uart_tx_test.sv
 * Description: UVM Test for UART TX
 */

class uart_tx_test extends uvm_test;
  `uvm_component_utils(uart_tx_test)

  uart_tx_env env;

  function new(string name = "uart_tx_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create environment
    env = uart_tx_env::type_id::create("env", this);

    // Set up configuration parameters
    uvm_config_db#(int)::set(this, "*", "DATA_BITS", 8);
    uvm_config_db#(bit)::set(this, "*", "PARITY_EN", 1);
    uvm_config_db#(bit)::set(this, "*", "PARITY_TYPE", 0);  // 0=even, 1=odd
    uvm_config_db#(int)::set(this, "*", "STOP_BITS", 1);
    uvm_config_db#(int)::set(this, "*", "CYCLES_PER_BIT", 50_000_000 / 115200);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    // Print test topology
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    uart_tx_all_tests_seq all_tests_seq;

    phase.raise_objection(this);

    // Create and start sequence
    all_tests_seq = uart_tx_all_tests_seq::type_id::create("all_tests_seq");
    all_tests_seq.start(env.agent.sequencer);

    // Allow time for all transactions to complete
    #10000;

    `uvm_info(get_type_name(), "All tests completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server server = uvm_report_server::get_server();

    if (server.get_severity_count(UVM_FATAL) +
        server.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info(get_type_name(), "*** TEST FAILED ***", UVM_LOW)
    end
    else begin
      `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_LOW)
    end
  endfunction
endclass

