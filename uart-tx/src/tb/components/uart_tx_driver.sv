class uart_tx_driver extends uvm_driver #(uart_tx_item);
  `uvm_component_utils(uart_tx_driver)

  virtual uart_tx_if vif;
  int CYCLES_PER_BIT;

  function new(string name = "uart_tx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get interface from config database
    if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Failed to get virtual interface from config database")
    end

    // Get the CYCLES_PER_BIT parameter from the config database
    if (!uvm_config_db#(int)::get(this, "", "CYCLES_PER_BIT", CYCLES_PER_BIT)) begin
      `uvm_fatal(get_type_name(), "Failed to get CYCLES_PER_BIT from config database")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Initialize signals
    vif.tx_start = 0;
    vif.cts = 1;
    vif.tx_data = 8'h00;

    forever begin
      uart_tx_item item;

      // Get the next item from the sequencer
      seq_item_port.get_next_item(item);

      `uvm_info(get_type_name(), $sformatf("Mengirim item: tx_data=0x%h, tx_start=%b, cts=%b, test_id=%0d",
                                          item.tx_data, item.tx_start, item.cts, item.test_id), UVM_HIGH)

      // Drive sinyal berdasarkan test case
      case(item.test_id)
        0: drive_basic_transmission(item);
        1: drive_flow_control_test(item);
        2: drive_multiple_transmission(item);
        3: drive_cts_during_transmission(item);
        4: drive_different_patterns(item);
        default: drive_basic_transmission(item);
      endcase

      // Inform the sequencer that the item is done
      seq_item_port.item_done(item);
    end
  endtask

  // Test Case 1: Basic Transmission
  virtual task drive_basic_transmission(uart_tx_item item);
    // Drive tx_data and enable tx_start
    vif.tx_data = item.tx_data;
    vif.cts = item.cts;

    vif.tx_start = 1;
    repeat(40) @(posedge vif.clk);
    vif.tx_start = 0;

    // Wait for transmission to complete
    wait(vif.tx_done);
    repeat(10) @(posedge vif.clk);

    // Send response back to sequencer
    item.tx_busy = vif.tx_busy;
    item.tx_done = vif.tx_done;
    seq_item_port.put_response(item);
  endtask

  // Test Case 2: Flow Control Test
  virtual task drive_flow_control_test(uart_tx_item item);
    // Drive tx_data dan CTS
    vif.tx_data = item.tx_data;
    vif.cts = item.cts;

    // Ensure the device is in idle state
    wait(!vif.tx_busy);
    repeat(10) @(posedge vif.clk);

    // Enable tx_start
    vif.tx_start = 1;
    repeat(5) @(posedge vif.clk);
    vif.tx_start = 0;

    // If CTS is not active, ensure transmission does not start
    if (item.cts == 0) begin
      repeat(20) @(posedge vif.clk);

      // Check tx_start_pending
      if (vif.tx_start_pending)
        `uvm_error(get_type_name(), "tx_start_pending aktif meskipun CTS tidak aktif")

      // Verify transmission does not start
      if (vif.tx_busy)
        `uvm_error(get_type_name(), "Transmisi dimulai meskipun CTS tidak aktif")
    end
    else begin
      // Wait for transmission to complete
      wait(vif.tx_done);
      repeat(10) @(posedge vif.clk);
    end

    // Send response back to sequencer
    item.tx_busy = vif.tx_busy;
    item.tx_done = vif.tx_done;
    seq_item_port.put_response(item);
  endtask

  // Test Case 3: Sequential Transmission
  virtual task drive_multiple_transmission(uart_tx_item item);
    // Drive tx_data and enable tx_start
    vif.tx_data = item.tx_data;
    vif.cts = item.cts;

    `uvm_info(get_type_name(), $sformatf("Mengirim transmisi dengan data: 0x%h", item.tx_data), UVM_MEDIUM)

    vif.tx_start = 1;
    repeat(5) @(posedge vif.clk);
    vif.tx_start = 0;

    // Wait for transmission to complete
    wait(vif.tx_done);
    repeat(10) @(posedge vif.clk);

    // Send response back to sequencer
    item.tx_busy = vif.tx_busy;
    item.tx_done = vif.tx_done;
    seq_item_port.put_response(item);
  endtask

  // Test Case 4: CTS Deactivated During Transmission
  virtual task drive_cts_during_transmission(uart_tx_item item);
    // Drive tx_data and enable tx_start
    vif.tx_data = item.tx_data;
    vif.cts = item.cts;

    vif.tx_start = 1;
    repeat(5) @(posedge vif.clk);
    vif.tx_start = 0;

    // Wait for transmission to start
    wait(vif.tx_busy);
    repeat(10) @(posedge vif.clk);

    // Disable CTS during transmission
    vif.cts = 0;
    `uvm_info(get_type_name(), "CTS deactivated during transmission", UVM_MEDIUM)
    repeat(20) @(posedge vif.clk);

    // Enable CTS again
    vif.cts = 1;
    `uvm_info(get_type_name(), "CTS reactivated", UVM_MEDIUM)

    // Tunggu transmisi kelar
    wait(vif.tx_done);
    repeat(10) @(posedge vif.clk);

    // Send response back to sequencer
    item.tx_busy = vif.tx_busy;
    item.tx_done = vif.tx_done;
    seq_item_port.put_response(item);
  endtask

  // Test Case 5: diff pattern
  virtual task drive_different_patterns(uart_tx_item item);
    // Drive tx_data and enable tx_start
    vif.tx_data = item.tx_data;
    vif.cts = item.cts;

    vif.tx_start = 1;
    repeat(5) @(posedge vif.clk);
    vif.tx_start = 0;

    // Wait for transmission to complete
    wait(vif.tx_done);
    repeat(10) @(posedge vif.clk);

    // Kirim respons balik
    item.tx_busy = vif.tx_busy;
    item.tx_done = vif.tx_done;
    seq_item_port.put_response(item);
  endtask
endclass
