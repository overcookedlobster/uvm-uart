class uart_tx_agent extends uvm_agent;
  `uvm_component_utils(uart_tx_agent)

  uart_tx_driver driver;
  uart_tx_monitor monitor;
  uvm_sequencer #(uart_tx_item) sequencer;

  function new(string name = "uart_tx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Buat komponen
    monitor = uart_tx_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      driver = uart_tx_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(uart_tx_item)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass
