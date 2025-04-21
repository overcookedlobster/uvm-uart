/*
 * File: uart_rx_sequences.sv
 * Description: UVM Sequences for UART RX
 */

// Base sequence
class uart_rx_sequence extends uvm_sequence #(uart_rx_seq_item);
  `uvm_object_utils(uart_rx_sequence)

  // Queue to hold items to send
  uart_rx_seq_item items[$];

  // Constructor
  function new(string name = "uart_rx_sequence");
    super.new(name);
  endfunction

  // Add item to the sequence
  function void add_item(uart_rx_seq_item item);
    items.push_back(item);
  endfunction

  // Task to send all items in the queue
  virtual task body();
    uart_rx_seq_item item;

    foreach (items[i]) begin
      item = items[i];
      `uvm_info("SEQ", $sformatf("Sending item %0d: data=0x%h", i, item.data), UVM_MEDIUM);

      // Send the item
      req = uart_rx_seq_item::type_id::create("req");
      start_item(req);
      req.copy(item);
      finish_item(req);
    end
  endtask
endclass

// Test Case 1: Basic Data Reception Sequence
class test_case1_sequence extends uart_rx_sequence;
  `uvm_object_utils(test_case1_sequence)

  function new(string name = "test_case1_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item;

    // Create and configure sequence item for 'A' (0x41)
    item = uart_rx_seq_item::type_id::create("item");
    item.data = 8'h41;

    // Add to sequence and send
    add_item(item);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass

// Test Case 2: Multiple Data Reception Sequence
class test_case2_sequence extends uart_rx_sequence;
  `uvm_object_utils(test_case2_sequence)

  function new(string name = "test_case2_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item_B, item_C, item_D;

    // Character 'B' (0x42)
    item_B = uart_rx_seq_item::type_id::create("item_B");
    item_B.data = 8'h42;
    add_item(item_B);

    // Character 'C' (0x43)
    item_C = uart_rx_seq_item::type_id::create("item_C");
    item_C.data = 8'h43;
    add_item(item_C);

    // Character 'D' (0x44)
    item_D = uart_rx_seq_item::type_id::create("item_D");
    item_D.data = 8'h44;
    add_item(item_D);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass

// Test Case 3: Different Bit Patterns Sequence
class test_case3_sequence extends uart_rx_sequence;
  `uvm_object_utils(test_case3_sequence)

  function new(string name = "test_case3_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item_55, item_AA, item_00, item_FF;

    // 0x55 (01010101)
    item_55 = uart_rx_seq_item::type_id::create("item_55");
    item_55.data = 8'h55;
    add_item(item_55);

    // 0xAA (10101010)
    item_AA = uart_rx_seq_item::type_id::create("item_AA");
    item_AA.data = 8'hAA;
    add_item(item_AA);

    // 0x00 (00000000)
    item_00 = uart_rx_seq_item::type_id::create("item_00");
    item_00.data = 8'h00;
    add_item(item_00);

    // 0xFF (11111111)
    item_FF = uart_rx_seq_item::type_id::create("item_FF");
    item_FF.data = 8'hFF;
    add_item(item_FF);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass

// Test Case 4: Framing Error Sequence
class test_case4_sequence extends uart_rx_sequence;
  `uvm_object_utils(test_case4_sequence)

  function new(string name = "test_case4_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item_E, item_F;

    // Character 'E' (0x45) with framing error
    item_E = uart_rx_seq_item::type_id::create("item_E");
    item_E.data = 8'h45;
    item_E.inject_framing_error = 1; // Will set stop_bit_value to 0
    add_item(item_E);

    // Character 'F' (0x46) - normal after error
    item_F = uart_rx_seq_item::type_id::create("item_F");
    item_F.data = 8'h46;
    add_item(item_F);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass

// Test Case 5: Break Condition Sequence
class test_case5_sequence extends uart_rx_sequence;
  `uvm_object_utils(test_case5_sequence)

  function new(string name = "test_case5_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item_break, item_G;

    // Break condition
    item_break = uart_rx_seq_item::type_id::create("item_break");
    item_break.break_condition = 1;
    add_item(item_break);

    // Character 'G' (0x47) - normal after break
    item_G = uart_rx_seq_item::type_id::create("item_G");
    item_G.data = 8'h47;
    add_item(item_G);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass

// All Tests Sequence
class all_tests_sequence extends uart_rx_sequence;
  `uvm_object_utils(all_tests_sequence)

  function new(string name = "all_tests_sequence");
    super.new(name);
  endfunction

  virtual task body();
    uart_rx_seq_item item;

    // Test 1: Basic Data Reception - Single Character
    item = uart_rx_seq_item::type_id::create("item");
    item.data = 8'h41; // 'A'
    add_item(item);

    // Test 2: Multiple Data Reception
    item = uart_rx_seq_item::type_id::create("item_B");
    item.data = 8'h42; // 'B'
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_C");
    item.data = 8'h43; // 'C'
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_D");
    item.data = 8'h44; // 'D'
    add_item(item);

    // Test 3: Different Bit Patterns
    item = uart_rx_seq_item::type_id::create("item_55");
    item.data = 8'h55;
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_AA");
    item.data = 8'hAA;
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_00");
    item.data = 8'h00;
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_FF");
    item.data = 8'hFF;
    add_item(item);

    // Test 4: Framing Error
    item = uart_rx_seq_item::type_id::create("item_E");
    item.data = 8'h45; // 'E'
    item.inject_framing_error = 1;
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_F");
    item.data = 8'h46; // 'F'
    add_item(item);

    // Test 5: Break Condition
    item = uart_rx_seq_item::type_id::create("item_break");
    item.break_condition = 1;
    add_item(item);

    item = uart_rx_seq_item::type_id::create("item_G");
    item.data = 8'h47; // 'G'
    add_item(item);

    // Run the parent sequence body to send all items
    super.body();
  endtask
endclass
