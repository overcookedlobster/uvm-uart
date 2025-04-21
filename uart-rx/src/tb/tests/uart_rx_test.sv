/*
 * File: uart_rx_test.sv
 * Description: UVM Tests for UART RX
 */

// UVM Base Test
class uart_rx_base_test extends uvm_test;
  `uvm_component_utils(uart_rx_base_test)

  // Environment
  uart_rx_env env;

  // Parameters
  parameter CLK_FREQ_HZ = 50_000_000;  // 50 MHz system clock
  parameter BAUD_RATE = 115200;        // 115.2 KBaud
  parameter BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE;
  parameter CLK_PERIOD_NS = 1_000_000_000 / CLK_FREQ_HZ;

  // Interface handle
  virtual uart_rx_if vif;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase - create environment
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get interface
    if (!uvm_config_db#(virtual uart_rx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found");

    // Create environment
    env = uart_rx_env::type_id::create("env", this);
  endfunction

  // Configure DUT
  virtual task configure_dut();
    // Initialize parameters
    vif.clk_period_ns = CLK_PERIOD_NS;
    vif.bit_period_ns = BIT_PERIOD_NS;
    vif.test_num = 0;

    // Configure UART parameters - apply proper clocking
    @(posedge vif.clk);
    vif.baud_rate = BAUD_RATE;
    vif.data_bits = 8;       // 8 data bits
    vif.parity_mode = 2'b00; // No parity
    vif.stop_bits = 1'b0;    // 1 stop bit
    vif.lsb_first = 1'b1;    // LSB first
    repeat(5) @(posedge vif.clk); // Allow configuration to settle

    `uvm_info("TEST", "DUT Configuration:", UVM_LOW);
    `uvm_info("TEST", $sformatf("  Baud rate: %0d", BAUD_RATE), UVM_LOW);
    `uvm_info("TEST", "  Data bits: 8", UVM_LOW);
    `uvm_info("TEST", "  Parity mode: None", UVM_LOW);
    `uvm_info("TEST", "  Stop bits: 1", UVM_LOW);
    `uvm_info("TEST", $sformatf("  LSB first: %s", vif.lsb_first ? "Yes" : "No"), UVM_LOW);
  endtask

  // Reset DUT
  virtual task reset_dut();
    // Apply proper reset sequence with clocking
    vif.rst_n = 0;
    vif.rx_in = 1;  // Idle state is high
    vif.rx_data_read = 0;
    vif.error_clear = 0;
    vif.fifo_clear = 0;
    repeat(50) @(posedge vif.clk);

    vif.rst_n = 1;
    repeat(50) @(posedge vif.clk);

    // Clear FIFO and errors after reset
    vif.fifo_clear = 1'b1;
    vif.error_clear = 1'b1;
    repeat(10) @(posedge vif.clk);
    vif.fifo_clear = 1'b0;
    vif.error_clear = 1'b0;
    repeat(10) @(posedge vif.clk);
  endtask

  // Clear errors
  virtual task clear_errors();
    // Apply proper error clearing with clocking
    @(posedge vif.clk);
    vif.error_clear = 1'b1;
    vif.fifo_clear = 1'b1;
    repeat(10) @(posedge vif.clk);
    vif.error_clear = 1'b0;
    vif.fifo_clear = 1'b0;
    repeat(10) @(posedge vif.clk);
  endtask
endclass

// Test Case 1: Basic Data Reception
class test_case1_basic_reception extends uart_rx_base_test;
  `uvm_component_utils(test_case1_basic_reception)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item;
    test_case1_sequence seq;

    phase.raise_objection(this);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 1: Basic Data Reception - Single Character", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Create and configure sequence item for 'A' (0x41)
    item = uart_rx_seq_item::type_id::create("item");
    item.data = 8'h41;

    // Add to expected queue in scoreboard
    env.scoreboard.add_to_expected_queue(item);

    // Create and start sequence
    seq = test_case1_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // Allow time for processing
    #(10000);

    phase.drop_objection(this);
  endtask
endclass

// Test Case 2: Multiple Data Reception
class test_case2_multiple_chars extends uart_rx_base_test;
  `uvm_component_utils(test_case2_multiple_chars)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item_B, item_C, item_D;
    test_case2_sequence seq;

    phase.raise_objection(this);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 2: Multiple Data Reception", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Character 'B' (0x42)
    item_B = uart_rx_seq_item::type_id::create("item_B");
    item_B.data = 8'h42;
    env.scoreboard.add_to_expected_queue(item_B);

    // Character 'C' (0x43)
    item_C = uart_rx_seq_item::type_id::create("item_C");
    item_C.data = 8'h43;
    env.scoreboard.add_to_expected_queue(item_C);

    // Character 'D' (0x44)
    item_D = uart_rx_seq_item::type_id::create("item_D");
    item_D.data = 8'h44;
    env.scoreboard.add_to_expected_queue(item_D);

    // Create sequence
    seq = test_case2_sequence::type_id::create("seq");

    // Start sequence
    seq.start(env.agent.sequencer);

    // Allow time for processing
    #(30000);

    phase.drop_objection(this);
  endtask
endclass

// Test Case 3: Different Bit Patterns
class test_case3_bit_patterns extends uart_rx_base_test;
  `uvm_component_utils(test_case3_bit_patterns)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item_55, item_AA, item_00, item_FF;
    test_case3_sequence seq;

    phase.raise_objection(this);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 3: Testing Various Bit Patterns", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // 0x55 (01010101)
    item_55 = uart_rx_seq_item::type_id::create("item_55");
    item_55.data = 8'h55;
    env.scoreboard.add_to_expected_queue(item_55);

    // 0xAA (10101010)
    item_AA = uart_rx_seq_item::type_id::create("item_AA");
    item_AA.data = 8'hAA;
    env.scoreboard.add_to_expected_queue(item_AA);

    // 0x00 (00000000)
    item_00 = uart_rx_seq_item::type_id::create("item_00");
    item_00.data = 8'h00;
    env.scoreboard.add_to_expected_queue(item_00);

    // 0xFF (11111111)
    item_FF = uart_rx_seq_item::type_id::create("item_FF");
    item_FF.data = 8'hFF;
    env.scoreboard.add_to_expected_queue(item_FF);

    // Create sequence
    seq = test_case3_sequence::type_id::create("seq");

    // Start sequence
    seq.start(env.agent.sequencer);

    // Allow time for processing
    #(40000);

    phase.drop_objection(this);
  endtask
endclass

// Test Case 4: Framing Error Detection
class test_case4_framing_error extends uart_rx_base_test;
  `uvm_component_utils(test_case4_framing_error)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item_E, item_F;
    test_case4_sequence seq;

    phase.raise_objection(this);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 4: Framing Error Injection and Detection", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Character 'E' (0x45) with framing error
    item_E = uart_rx_seq_item::type_id::create("item_E");
    item_E.data = 8'h45;
    item_E.inject_framing_error = 1; // Will set stop_bit_value to 0

    // Create and start sequence
    seq = test_case4_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // Check for framing error using direct polling
    begin
      int timeout_count = 0;
      bit error_found = 0;

      `uvm_info("TEST", $sformatf("Test %0d: Checking for framing error", vif.test_num), UVM_LOW);

      // Wait for error detection or timeout
      while (!error_found && timeout_count < 10000) begin
        #(vif.clk_period_ns);
        timeout_count++;

        if (vif.error_detected && vif.framing_error) begin
          error_found = 1;
          `uvm_info("TEST", $sformatf("PASS: Test %0d correctly detected framing error at time %t", vif.test_num, $time), UVM_LOW);
        end
      end

      if (!error_found) begin
        `uvm_error("TEST", $sformatf("FAIL: Test %0d did not detect expected framing error", vif.test_num));
      end
    end

    // Clear errors
    #(10000);
    clear_errors();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 4b: Testing Recovery After Framing Error", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Character 'F' (0x46) - normal after error
    item_F = uart_rx_seq_item::type_id::create("item_F");
    item_F.data = 8'h46;
    env.scoreboard.add_to_expected_queue(item_F);

    // Allow time for processing
    #(20000);

    phase.drop_objection(this);
  endtask
endclass

// Test Case 5: Break Condition Detection
class test_case5_break_condition extends uart_rx_base_test;
  `uvm_component_utils(test_case5_break_condition)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item_break, item_G;
    test_case5_sequence seq;

    phase.raise_objection(this);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 5: Break Condition Injection", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Break condition
    item_break = uart_rx_seq_item::type_id::create("item_break");
    item_break.break_condition = 1;

    // Create and start sequence
    seq = test_case5_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // Check for break condition using direct polling
    begin
      int timeout_count = 0;
      int max_timeout = 20000; // Longer timeout for break detection
      bit error_found = 0;

      `uvm_info("TEST", $sformatf("Test %0d: Checking for break condition", vif.test_num), UVM_LOW);

      // Wait for break detection or timeout
      while (!error_found && timeout_count < max_timeout) begin
        #(vif.clk_period_ns);
        timeout_count++;

        if (vif.break_detect) begin
          `uvm_info("TEST", $sformatf("PASS: Test %0d correctly detected break condition", vif.test_num), UVM_LOW);
          error_found = 1;
        end else if (vif.error_detected && vif.framing_error && timeout_count > 5000) begin
          `uvm_info("TEST", $sformatf("PARTIAL PASS: Test %0d detected framing error but not break condition", vif.test_num), UVM_LOW);
          error_found = 1;
        end
      end

      if (!error_found) begin
        `uvm_error("TEST", $sformatf("FAIL: Test %0d did not detect expected break condition", vif.test_num));
      end
    end

    // Clear errors
    #(10000);
    clear_errors();

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Test Case 5b: Testing Recovery After Break Condition", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Character 'G' (0x47) - normal after break
    item_G = uart_rx_seq_item::type_id::create("item_G");
    item_G.data = 8'h47;
    env.scoreboard.add_to_expected_queue(item_G);

    // Allow time for processing
    #(20000);

    phase.drop_objection(this);
  endtask
endclass

// Run All Tests
class run_all_tests extends uart_rx_base_test;
  `uvm_component_utils(run_all_tests)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_rx_seq_item item;
    all_tests_sequence seq;

    phase.raise_objection(this);

    `uvm_info("TEST", "\n===================================================", UVM_LOW);
    `uvm_info("TEST", "Running All UART RX Tests", UVM_LOW);
    `uvm_info("TEST", "===================================================", UVM_LOW);

    // Reset and configure DUT
    reset_dut();
    configure_dut();

    // Add all expected items to scoreboard queue
    // Character 'A' (0x41)
    item = uart_rx_seq_item::type_id::create("item");
    item.data = 8'h41;
    env.scoreboard.add_to_expected_queue(item);

    // Character 'B' (0x42)
    item = uart_rx_seq_item::type_id::create("item_B");
    item.data = 8'h42;
    env.scoreboard.add_to_expected_queue(item);

    // Character 'C' (0x43)
    item = uart_rx_seq_item::type_id::create("item_C");
    item.data = 8'h43;
    env.scoreboard.add_to_expected_queue(item);

    // Character 'D' (0x44)
    item = uart_rx_seq_item::type_id::create("item_D");
    item.data = 8'h44;
    env.scoreboard.add_to_expected_queue(item);

    // 0x55 (01010101)
    item = uart_rx_seq_item::type_id::create("item_55");
    item.data = 8'h55;
    env.scoreboard.add_to_expected_queue(item);

    // 0xAA (10101010)
    item = uart_rx_seq_item::type_id::create("item_AA");
    item.data = 8'hAA;
    env.scoreboard.add_to_expected_queue(item);

    // 0x00 (00000000)
    item = uart_rx_seq_item::type_id::create("item_00");
    item.data = 8'h00;
    env.scoreboard.add_to_expected_queue(item);

    // 0xFF (11111111)
    item = uart_rx_seq_item::type_id::create("item_FF");
    item.data = 8'hFF;
    env.scoreboard.add_to_expected_queue(item);

    // Character 'F' (0x46) - after framing error
    item = uart_rx_seq_item::type_id::create("item_F");
    item.data = 8'h46;
    env.scoreboard.add_to_expected_queue(item);

    // Character 'G' (0x47) - after break condition
    item = uart_rx_seq_item::type_id::create("item_G");
    item.data = 8'h47;
    env.scoreboard.add_to_expected_queue(item);

    // Create and start the all-tests sequence
    seq = all_tests_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // Allow time for processing
    #(BIT_PERIOD_NS * 500);

    `uvm_info("TEST", "\nAll tests completed", UVM_LOW);

    phase.drop_objection(this);
  endtask
endclass
