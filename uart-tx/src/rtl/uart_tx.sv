/*
 * File: uart_tx.sv
 * Description: UART transmitter module
 */

module uart_tx #(
  parameter int DATA_BITS = 8,
  parameter bit PARITY_EN = 1'b1,
  parameter bit PARITY_TYPE = 1'b0,  // 0=even, 1=odd
  parameter int STOP_BITS = 1
) (
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  tick,        // Baud rate tick
  input  logic                  tx_start,    // Start transmission
  input  logic                  cts,         // Clear to Send (flow control)
  input  logic [DATA_BITS-1:0]  tx_data,     // Parallel input data
  output logic                  tx_out,      // Serial output data
  output logic                  tx_busy,     // Transmitter busy
  output logic                  tx_done      // Transmission complete
);

  // States
  typedef enum logic [2:0] {
    S_IDLE,
    S_START_BIT,
    S_DATA_BITS,
    S_PARITY_BIT,
    S_STOP_BIT1,
    S_STOP_BIT2
  } state_t;

  // Internal signals
  state_t current_state;
  logic [3:0] bit_count;
  logic [DATA_BITS-1:0] tx_shift_reg;
  logic [DATA_BITS-1:0] tx_data_latch;
  logic parity_value;
  logic flow_paused;
  logic tx_start_pending;

  // State machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= S_IDLE;
      tx_out <= 1'b1;  // Idle high
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
      bit_count <= 0;
      tx_shift_reg <= '0;
      tx_data_latch <= '0;
      parity_value <= 1'b0;
      flow_paused <= 1'b0;
      tx_start_pending <= 1'b0;
    end else begin
      // Default assignment
      tx_done <= 1'b0;

      // Latch tx_start signal on rising edge
      if (tx_start && !tx_busy && cts) begin
        tx_start_pending <= 1'b1;
        tx_data_latch <= tx_data;  // Latch data immediately
      end

      // Check flow control
      if (!cts && !flow_paused && current_state != S_IDLE) begin
        flow_paused <= 1'b1;
      end
      else if (cts && flow_paused) begin
        flow_paused <= 1'b0;
      end

      // Process state machine if not paused by flow control
      if (!flow_paused) begin
        case (current_state)
          S_IDLE: begin
            tx_out <= 1'b1;  // Line idle high
            tx_busy <= 1'b0;

            // Start transmission on tick if there is a pending request
            if (tick && tx_start_pending) begin
              tx_start_pending <= 1'b0;
              tx_shift_reg <= tx_data_latch;  // Load latched data
              parity_value <= PARITY_TYPE ? ~(^tx_data_latch) : ^tx_data_latch; // Calculate parity
              current_state <= S_START_BIT;
              tx_busy <= 1'b1;
            end
          end

          S_START_BIT: begin
            // Output start bit (always low)
            tx_out <= 1'b0;

            // Wait for tick to move to data state
            if (tick) begin
              current_state <= S_DATA_BITS;
              bit_count <= 0;
            end
          end

          S_DATA_BITS: begin
            // Output current data bit (LSB first)
            tx_out <= tx_shift_reg[0];

            // Handle tick
            if (tick) begin
              // Shift data for next bit
              tx_shift_reg <= tx_shift_reg >> 1;

              // Check if all data bits have been sent
              if (bit_count == DATA_BITS-1) begin
                // Move to next state
                current_state <= PARITY_EN ? S_PARITY_BIT : S_STOP_BIT1;
                bit_count <= 0; // Reset for next transmission
              end else begin
                // Increment counter
                bit_count <= bit_count + 1'b1;
              end
            end
          end

          S_PARITY_BIT: begin
            // Output parity bit
            tx_out <= parity_value;

            if (tick) begin
              current_state <= S_STOP_BIT1;
            end
          end

          S_STOP_BIT1: begin
            // Output stop bit (always high)
            tx_out <= 1'b1;

            if (tick) begin
              if (STOP_BITS == 1) begin
                current_state <= S_IDLE;
                tx_done <= 1'b1;
              end else begin
                current_state <= S_STOP_BIT2;
              end
            end
          end

          S_STOP_BIT2: begin
            // Output second stop bit (always high)
            tx_out <= 1'b1;

            if (tick) begin
              current_state <= S_IDLE;
              tx_done <= 1'b1;
            end
          end

          default: current_state <= S_IDLE;
        endcase
      end
    end
  end

endmodule

