/*
 * File: uart_tx_monitor.sv
 * Description: UVM Monitor for UART TX
 */

class uart_tx_monitor extends uvm_monitor;
  `uvm_component_utils(uart_tx_monitor)

  virtual uart_tx_if vif;
  uvm_analysis_port #(uart_tx_item) item_collected_port;

  // Parameters
  int DATA_BITS;
  bit PARITY_EN;
  bit PARITY_TYPE;
  int STOP_BITS;
  int CYCLES_PER_BIT;

  function new(string name = "uart_tx_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get interface from config database
    if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Failed to get virtual interface from config database")
    end

    // Get parameters from config database
    if (!uvm_config_db#(int)::get(this, "", "DATA_BITS", DATA_BITS)) begin
      `uvm_fatal(get_type_name(), "Failed to get DATA_BITS from config database")
    end
    if (!uvm_config_db#(bit)::get(this, "", "PARITY_EN", PARITY_EN)) begin
      `uvm_fatal(get_type_name(), "Failed to get PARITY_EN from config database")
    end
    if (!uvm_config_db#(bit)::get(this, "", "PARITY_TYPE", PARITY_TYPE)) begin
      `uvm_fatal(get_type_name(), "Failed to get PARITY_TYPE from config database")
    end
    if (!uvm_config_db#(int)::get(this, "", "STOP_BITS", STOP_BITS)) begin
      `uvm_fatal(get_type_name(), "Failed to get STOP_BITS from config database")
    end
    if (!uvm_config_db#(int)::get(this, "", "CYCLES_PER_BIT", CYCLES_PER_BIT)) begin
      `uvm_fatal(get_type_name(), "Failed to get CYCLES_PER_BIT from config database")
    end
  endfunction

  // Calculate expected parity
  function logic expected_parity(logic [7:0] data);
    automatic logic parity = 1'b0;

    for (int i = 0; i < DATA_BITS; i++) begin
      parity ^= data[i];
    end

    return PARITY_TYPE ? ~parity : parity; // Inversion for odd parity
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      monitor_transactions();
      monitor_for_timeout();
    join
  endtask

  // Monitor for UART transactions
  virtual task monitor_transactions();
    uart_tx_item tx_item;
    logic [15:0] received_data;
    logic exp_parity;
    logic [7:0] collected_data;

    forever begin
      // Wait for start bit
      @(negedge vif.tx_out);

      // Create new transaction
      tx_item = uart_tx_item::type_id::create("tx_item");

      `uvm_info(get_type_name(), $sformatf("Start bit detected at %0t", $time), UVM_MEDIUM)

      // Sampling in the middle of start bit
      repeat (CYCLES_PER_BIT/2) @(posedge vif.clk);

      // Verify start bit is 0
      if (vif.tx_out != 0) begin
        `uvm_error(get_type_name(), $sformatf("Invalid start bit: %b at %0t", vif.tx_out, $time))
      end

      // Wait for end of start bit
      repeat (CYCLES_PER_BIT/2) @(posedge vif.clk);

      // Reset data
      received_data = '0;
      collected_data = '0;

      // Capture data bits
      for (int i = 0; i < DATA_BITS; i++) begin
        repeat(CYCLES_PER_BIT) @(posedge vif.clk);
        received_data[i] = vif.tx_out;
        collected_data[i] = vif.tx_out;
        `uvm_info(get_type_name(), $sformatf("Data bit %0d: %b at %0t", i, vif.tx_out, $time), UVM_HIGH)
      end

      // Capture parity bit if enabled
      if (PARITY_EN) begin
        repeat (CYCLES_PER_BIT) @(posedge vif.clk);
        exp_parity = expected_parity(vif.tx_data);
        `uvm_info(get_type_name(),
                 $sformatf("Parity bit: %b (Expected: %b) at %0t", vif.tx_out, exp_parity, $time),
                 UVM_MEDIUM)

        if (vif.tx_out != exp_parity) begin
          `uvm_error(get_type_name(),
                    $sformatf("Parity bit mismatch! Received: %b, Expected: %b at %0t",
                             vif.tx_out, exp_parity, $time))
        end
      end

      // Capture stop bit(s)
      for (int i = 0; i < STOP_BITS; i++) begin
        repeat (CYCLES_PER_BIT) @(posedge vif.clk);
        `uvm_info(get_type_name(), $sformatf("Stop bit %0d: %b at %0t", i, vif.tx_out, $time), UVM_HIGH)

        if (vif.tx_out != 1) begin
          `uvm_error(get_type_name(),
                    $sformatf("Invalid stop bit %0d: %b at %0t", i, vif.tx_out, $time))
        end
      end

      // Get transaction data
      tx_item.tx_data = collected_data;

      `uvm_info(get_type_name(),
               $sformatf("Data received: 0x%h, Expected: 0x%h at %0t",
                        collected_data, vif.tx_data, $time),
               UVM_MEDIUM)

      // Verify data
      if (collected_data != vif.tx_data) begin
        `uvm_error(get_type_name(),
                  $sformatf("Data mismatch! Received: 0x%h, Expected: 0x%h at %0t",
                           collected_data, vif.tx_data, $time))
      end
      else begin
        `uvm_info(get_type_name(), "Data successfully verified", UVM_MEDIUM)
      end

      // Send transaction to scoreboard
      item_collected_port.write(tx_item);
    end
  endtask

  // Monitor for timeout
  virtual task monitor_for_timeout();
    int timeout_counter = 0;
    bit transmission_in_progress = 0;

    forever begin
      @(posedge vif.clk);

      // Start counting when transmission begins
      if (vif.tx_busy && !transmission_in_progress) begin
        transmission_in_progress = 1;
        timeout_counter = 0;
        `uvm_info(get_type_name(), $sformatf("Transmission started at %0t", $time), UVM_MEDIUM)
      end

      // Stop counting when transmission ends
      if (!vif.tx_busy && transmission_in_progress) begin
        transmission_in_progress = 0;
        `uvm_info(get_type_name(),
                 $sformatf("Transmission completed after %0d cycles at %0t", timeout_counter, $time),
                 UVM_MEDIUM)
      end

      // Count during transmission
      if (transmission_in_progress) begin
        timeout_counter++;

        // Display status every 5000 clock cycles
        if (timeout_counter % 5000 == 0) begin
          `uvm_info(get_type_name(),
                   $sformatf("Still in transmission after %0d cycles at %0t",
                            timeout_counter, $time),
                   UVM_MEDIUM)
        end

        // Force error if stuck for too long
        if (timeout_counter > CYCLES_PER_BIT * 20) begin
          `uvm_error(get_type_name(),
                    $sformatf("Transmission seems stuck after %0d cycles at %0t! CYCLES_PER_BIT = %0d",
                             timeout_counter, $time, CYCLES_PER_BIT))
        end
      end
    end
  endtask
endclass

