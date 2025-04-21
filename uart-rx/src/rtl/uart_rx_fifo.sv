/*
 * File: uart_rx_fifo.sv
 * Description: FIFO buffer for UART receiver data
 */

module uart_rx_fifo #(
  parameter DATA_WIDTH = 8,             // Data width (8 for standard UART, 9 for 9-bit data)
  parameter FIFO_DEPTH = 16,            // FIFO depth (must be power of 2)
  parameter ALMOST_FULL_THRESHOLD = 12  // Almost full threshold value
) (
  input  logic                  clk,           // System clock
  input  logic                  rst_n,         // Active-low reset

  // Write interface
  input  logic [DATA_WIDTH-1:0] write_data,    // Data to write to FIFO
  input  logic                  write_en,      // Write enable

  // Read interface
  output logic [DATA_WIDTH-1:0] read_data,     // Data read from FIFO
  input  logic                  read_en,       // Read enable

  // Control and status
  input  logic                  fifo_clear,    // Clear/flush the FIFO
  output logic                  fifo_empty,    // FIFO empty flag
  output logic                  fifo_full,     // FIFO full flag
  output logic                  fifo_almost_full, // FIFO almost full flag
  output logic                  overflow,      // Overflow flag (write when full)
  output logic [$clog2(FIFO_DEPTH):0] data_count  // Number of entries in FIFO
);

  // Memory array to store FIFO data
  logic [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];

  // Pointers for read and write operations
  logic [$clog2(FIFO_DEPTH)-1:0] read_ptr;
  logic [$clog2(FIFO_DEPTH)-1:0] write_ptr;

  // Full/empty tracking
  logic [$clog2(FIFO_DEPTH):0] count;

  // Keep track of overflow condition
  logic overflow_r;

  // Debug - keep track of last written data
  logic [DATA_WIDTH-1:0] last_written_data;

  // Status flags
  assign fifo_empty = (count == 0);
  assign fifo_full = (count == FIFO_DEPTH);
  assign fifo_almost_full = (count > ALMOST_FULL_THRESHOLD);
  assign overflow = overflow_r;
  assign data_count = count;

  // Use a registered output to avoid timing issues
  logic [DATA_WIDTH-1:0] read_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_data_reg <= '0;
    end else if (read_en && !fifo_empty) begin
      read_data_reg <= fifo_mem[read_ptr];
    end
  end

  // Better read data logic - hold value when not empty
  assign read_data = fifo_empty ? '0 :
                    (read_en ? fifo_mem[read_ptr] : read_data_reg);

  // FIFO control logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_ptr <= '0;
      write_ptr <= '0;
      count <= '0;
      overflow_r <= 1'b0;
      last_written_data <= '0;
    end
    else if (fifo_clear) begin
      read_ptr <= '0;
      write_ptr <= '0;
      count <= '0;
      overflow_r <= 1'b0;
    end
    else begin
      // Update read pointer on read operation
      if (read_en && !fifo_empty) begin
        read_ptr <= read_ptr + 1'b1;

        // Debug: Show data being read
        $display("Time %t: Reading from FIFO: addr=%d, data=%h", $time, read_ptr, fifo_mem[read_ptr]);

        // Update count when reading (unless simultaneously writing)
        if (!(write_en && !fifo_full)) begin
          count <= count - 1'b1;
        end
      end

      // Handle write operation
      if (write_en && !fifo_full) begin
        // Debug: Show data being written
        $display("Time %t: Writing to FIFO: addr=%d, data=%h", $time, write_ptr, write_data);

        fifo_mem[write_ptr] <= write_data;
        last_written_data <= write_data;  // Save for debug
        write_ptr <= write_ptr + 1'b1;

        // Update count when writing (unless simultaneously reading)
        if (!(read_en && !fifo_empty)) begin
          count <= count + 1'b1;
        end
      end

      // Handle overflow condition
      if (write_en && fifo_full) begin
        overflow_r <= 1'b1;
        $display("Time %t: FIFO overflow detected!", $time);
      end
    end
  end

endmodule
