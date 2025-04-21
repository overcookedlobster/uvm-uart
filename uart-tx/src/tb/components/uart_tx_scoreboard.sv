class uart_tx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_tx_scoreboard)

  uvm_analysis_imp #(uart_tx_item, uart_tx_scoreboard) item_collected_export;

  // Counters to track test results
  int num_transactions = 0;
  int num_errors = 0;

  function new(string name = "uart_tx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
  endfunction

  // Receive transactions from monitor and analyze
  function void write(uart_tx_item item);
    num_transactions++;

    `uvm_info(get_type_name(),
             $sformatf("Transaction received #%0d: tx_data=0x%h",
                      num_transactions, item.tx_data),
             UVM_HIGH)
  endfunction

  // Report phase - print summary
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
             $sformatf("\n*** TEST SUMMARY ***\nTotal Transactions: %0d\nTotal Errors: %0d\n",
                      num_transactions, num_errors),
             UVM_LOW)
  endfunction
endclass

