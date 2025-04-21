package uart_tx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Urutan include file sabi buat resolve dependencies
  `include "../sequence_items/uart_tx_item.sv"
  `include "../sequences/uart_tx_sequences.sv"
  `include "../components/uart_tx_driver.sv"
  `include "../components/uart_tx_monitor.sv"
  `include "../components/uart_tx_scoreboard.sv"
  `include "../components/uart_tx_agent.sv"
  `include "../components/uart_tx_env.sv"
  `include "../tests/uart_tx_test.sv"

endpackage : uart_tx_pkg
