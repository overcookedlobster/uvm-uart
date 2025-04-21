class uart_tx_env extends uvm_env;
  `uvm_component_utils(uart_tx_env)

  uart_tx_agent agent;
  uart_tx_scoreboard scoreboard;

  function new(string name = "uart_tx_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Buat komponen
    agent = uart_tx_agent::type_id::create("agent", this);
    scoreboard = uart_tx_scoreboard::type_id::create("scoreboard", this);

    uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
  endfunction

  function void connect_phase(uvm_phase phase);
    // monitor ke scoreboard
    agent.monitor.item_collected_port.connect(scoreboard.item_collected_export);
  endfunction
endclass
