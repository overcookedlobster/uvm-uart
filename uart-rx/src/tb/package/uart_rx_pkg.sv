/*
 * File: uart_rx_pkg.sv
 * Description: Package containing all UVM components for UART RX verification
 */

package uart_rx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include all the UVM components in order to resolve dependencies
  `include "../sequence_items/uart_rx_seq_item.sv"
  `include "../components/uart_rx_sequencer.sv"
  `include "../components/uart_rx_driver.sv"
  `include "../components/uart_rx_monitor.sv"
  `include "../components/uart_rx_scoreboard.sv"
  `include "../components/uart_rx_agent.sv"
  `include "../components/uart_rx_env.sv"
  `include "../sequences/uart_rx_sequences.sv"
  `include "../tests/uart_rx_test.sv"

endpackage
