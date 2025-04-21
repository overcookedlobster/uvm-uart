`include "uvm_macros.svh"
class uart_tx_item extends uvm_sequence_item;
  // data field
  rand bit [7:0] tx_data;
  rand bit tx_start;
  rand bit cts;

  // responz
  bit tx_out;
  bit tx_busy;
  bit tx_done;

  // konfigurasi
  rand bit use_random_data;
  rand byte test_id;

  // Constraint buat kontrol randomisasi
  constraint c_test_id {
    test_id inside {0, 1, 2, 3, 4}; // ID untuk test case
  }

  `uvm_object_utils_begin(uart_tx_item)
    `uvm_field_int(tx_data, UVM_ALL_ON)
    `uvm_field_int(tx_start, UVM_ALL_ON)
    `uvm_field_int(cts, UVM_ALL_ON)
    `uvm_field_int(tx_out, UVM_ALL_ON)
    `uvm_field_int(tx_busy, UVM_ALL_ON)
    `uvm_field_int(tx_done, UVM_ALL_ON)
    `uvm_field_int(use_random_data, UVM_ALL_ON)
    `uvm_field_int(test_id, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "uart_tx_item");
    super.new(name);
  endfunction
endclass

