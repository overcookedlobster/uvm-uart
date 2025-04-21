interface uart_tx_if (input logic clk, input logic rst_n);
  logic tick;
  logic tick_16x;
  logic tx_start;
  logic cts;
  logic [7:0] tx_data;
  logic tx_out;
  logic tx_busy;
  logic tx_done;
  logic tx_start_pending; // buat debugging - sinyal internal DUT
endinterface
