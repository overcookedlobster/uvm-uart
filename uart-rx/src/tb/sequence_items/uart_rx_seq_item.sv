/*
 * File: uart_rx_seq_item.sv
 * Description: UVM Sequence Item for UART RX
 */

`include "uvm_macros.svh"
import uvm_pkg::*;
class uart_rx_seq_item extends uvm_sequence_item;
  // Transaction data
  rand bit [7:0] data;
  rand bit stop_bit_value = 1;  // Default to valid stop bit
  rand bit break_condition = 0; // Default not a break condition

  // Control flags
  rand bit inject_framing_error = 0;

  // Utility and Field macros
  `uvm_object_utils_begin(uart_rx_seq_item)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(stop_bit_value, UVM_ALL_ON)
    `uvm_field_int(break_condition, UVM_ALL_ON)
    `uvm_field_int(inject_framing_error, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "uart_rx_seq_item");
    super.new(name);
  endfunction

  // Constraints
  constraint stop_bit_c {
    inject_framing_error == 1 -> stop_bit_value == 0;
    inject_framing_error == 0 -> stop_bit_value == 1;
  }

  constraint break_c {
    break_condition == 1 -> inject_framing_error == 0;
  }
endclass
