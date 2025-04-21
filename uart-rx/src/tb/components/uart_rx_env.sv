/*
 * File: uart_rx_env.sv
 * Description: UVM Environment for UART RX
 */

class uart_rx_env extends uvm_env;
  `uvm_component_utils(uart_rx_env)

  // Components
  uart_rx_agent agent;
  uart_rx_scoreboard scoreboard;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase - create components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create agent and scoreboard
    agent = uart_rx_agent::type_id::create("agent", this);
    scoreboard = uart_rx_scoreboard::type_id::create("scoreboard", this);

    // Set agent to active mode
    uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
  endfunction

  // Connect phase - connect components
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect monitor to scoreboard
    agent.monitor.actual_port.connect(scoreboard.act_export);
  endfunction
endclass
