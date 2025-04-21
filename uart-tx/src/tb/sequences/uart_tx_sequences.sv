// Sequence basic
class uart_tx_base_seq extends uvm_sequence #(uart_tx_item);
  `uvm_object_utils(uart_tx_base_seq)

  function new(string name = "uart_tx_base_seq");
    super.new(name);
  endfunction

  // bakal di-override sequence specific
  virtual task body();
  endtask
endclass

// Test Case 1: Transmisi b aja
class uart_tx_basic_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_basic_seq)

  function new(string name = "uart_tx_basic_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_tx_item tx_item;

    `uvm_info(get_type_name(), "\n\n*** RUNNING TEST CASE 1: BASIC TRANSMISSION ***\n", UVM_MEDIUM)

    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'h55;
      tx_start == 1;
      cts == 1;
      test_id == 0;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    finish_item(tx_item);
    get_response(tx_item);
  endtask
endclass

// Test Case 2: Flow Control Test
class uart_tx_flow_control_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_flow_control_seq)

  function new(string name = "uart_tx_flow_control_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_tx_item tx_item;

    `uvm_info(get_type_name(), "\n\n*** RUNNING TEST CASE 2: FLOW CONTROL TEST ***\n", UVM_MEDIUM)

    // CTS ga aktif
    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'hAA;
      tx_start == 1;
      cts == 0;  // CTS tidak aktif
      test_id == 1;
    }) begin
      `uvm_error(get_type_name(), "Randomisasi gagal")
    end
    finish_item(tx_item);
    get_response(tx_item);

    // CTS aktif
    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'hAA;
      tx_start == 1;
      cts == 1;  // CTS aktif
      test_id == 1;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    finish_item(tx_item);
    get_response(tx_item);
  endtask
endclass

// Test Case 3: Multiple Transmissions
class uart_tx_multi_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_multi_seq)

  function new(string name = "uart_tx_multi_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_tx_item tx_item;

    `uvm_info(get_type_name(), "\n\n*** RUNNING TEST CASE 3: MULTIPLE TRANSMISSIONS ***\n", UVM_MEDIUM)

    // 3 transaksi random data
    for (int i = 0; i < 3; i++) begin
      tx_item = uart_tx_item::type_id::create("tx_item");
      start_item(tx_item);
      if (!tx_item.randomize() with {
        tx_start == 1;
        cts == 1;
        use_random_data == 1;
        test_id == 2;
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      `uvm_info(get_type_name(), $sformatf("Starting transmission %0d with data: 0x%h", i, tx_item.tx_data), UVM_MEDIUM)
      finish_item(tx_item);
      get_response(tx_item);
    end
  endtask
endclass

// Test Case 4: CTS Deasserted tengah Transmission
class uart_tx_cts_during_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_cts_during_seq)

  function new(string name = "uart_tx_cts_during_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_tx_item tx_item;

    `uvm_info(get_type_name(), "\n\n*** RUNNING TEST CASE 4: CTS DEASSERTED DURING TRANSMISSION ***\n", UVM_MEDIUM)

    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'h33;
      tx_start == 1;
      cts == 1;  // CTS awalnya aktif
      test_id == 3;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    finish_item(tx_item);
    get_response(tx_item);
  endtask
endclass

// Test Case 5: diff patterns
class uart_tx_patterns_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_patterns_seq)

  function new(string name = "uart_tx_patterns_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_tx_item tx_item;

    `uvm_info(get_type_name(), "\n\n*** RUNNING TEST CASE 5: DIFFERENT DATA PATTERNS ***\n", UVM_MEDIUM)

    // patt 1: all nol
    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'h00;
      tx_start == 1;
      cts == 1;
      test_id == 4;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    `uvm_info(get_type_name(), "Testing all zeros: 0x00", UVM_MEDIUM)
    finish_item(tx_item);
    get_response(tx_item);

    // patt 2: all satu
    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'hFF;
      tx_start == 1;
      cts == 1;
      test_id == 4;
    }) begin
      `uvm_error(get_type_name(), "Randomisasi gagal")
    end
    `uvm_info(get_type_name(), "Testing semua satu: 0xFF", UVM_MEDIUM)
    finish_item(tx_item);
    get_response(tx_item);

    // patt 3: bergantian
    tx_item = uart_tx_item::type_id::create("tx_item");
    start_item(tx_item);
    if (!tx_item.randomize() with {
      tx_data == 8'hA5;
      tx_start == 1;
      cts == 1;
      test_id == 4;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    `uvm_info(get_type_name(), "Testing alternating pattern: 0xA5", UVM_MEDIUM)
    finish_item(tx_item);
    get_response(tx_item);
  endtask
endclass

// Running all test cases sequentially
class uart_tx_all_tests_seq extends uart_tx_base_seq;
  `uvm_object_utils(uart_tx_all_tests_seq)

  uart_tx_basic_seq basic_seq;
  uart_tx_flow_control_seq flow_control_seq;
  uart_tx_multi_seq multi_seq;
  uart_tx_cts_during_seq cts_during_seq;
  uart_tx_patterns_seq patterns_seq;

  function new(string name = "uart_tx_all_tests_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "\n\n*** RUNNING ALL TEST CASES SEQUENTIALLY ***\n", UVM_MEDIUM)

    // Buat semua sequence
    basic_seq = uart_tx_basic_seq::type_id::create("basic_seq");
    flow_control_seq = uart_tx_flow_control_seq::type_id::create("flow_control_seq");
    multi_seq = uart_tx_multi_seq::type_id::create("multi_seq");
    cts_during_seq = uart_tx_cts_during_seq::type_id::create("cts_during_seq");
    patterns_seq = uart_tx_patterns_seq::type_id::create("patterns_seq");

    // Jalankan secara berurutan
    basic_seq.start(m_sequencer);
    flow_control_seq.start(m_sequencer);
    multi_seq.start(m_sequencer);
    cts_during_seq.start(m_sequencer);
    patterns_seq.start(m_sequencer);

    `uvm_info(get_type_name(), "\n\n*** ALL TEST CASES COMPLETED ***\n", UVM_LOW)
  endtask
endclass
