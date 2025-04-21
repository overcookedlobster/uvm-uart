/*
 * File: uart_rx_sequencer.sv
 * Description: UVM Sequencer for UART RX
 */

class uart_rx_sequencer extends uvm_sequencer #(uart_rx_seq_item);
  `uvm_component_utils(uart_rx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
