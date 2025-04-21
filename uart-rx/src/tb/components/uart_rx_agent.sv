/*
 * File: uart_rx_agent.sv
 * Description: UVM Agent for UART RX
 */

class uart_rx_agent extends uvm_agent;
  `uvm_component_utils(uart_rx_agent)

  // Components
  uart_rx_sequencer sequencer;
  uart_rx_driver    driver;
  uart_rx_monitor   monitor;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase - create components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    monitor = uart_rx_monitor::type_id::create("monitor", this);

    // Only create driver and sequencer in active mode
    if (get_is_active() == UVM_ACTIVE) begin
      driver = uart_rx_driver::type_id::create("driver", this);
      sequencer = uart_rx_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  // Connect phase - connect components
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect sequencer to driver in active mode
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass
