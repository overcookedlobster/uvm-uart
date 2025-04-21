/*
 * File: uart_bit_sampler.sv
 * Description: Bit sampling module for UART receiver
 */

module uart_bit_sampler (
  input  logic clk,           // System clock
  input  logic rst_n,         // Active-low reset
  input  logic tick_16x,      // 16x oversampling tick
  input  logic rx_filtered,   // Filtered serial input
  input  logic falling_edge,  // Falling edge detection from input filter
  input  logic frame_complete, // Signal indicating frame is complete (from state machine)
  input  logic error_clear,   // Signal to clear errors
  output logic bit_sample,    // Sampled bit value
  output logic bit_valid,     // Indicates a valid bit has been sampled
  output logic start_detected // Indicates start bit has been detected
);

  // States for the bit sampler state machine
  typedef enum logic [1:0] {
    IDLE,           // Waiting for start bit
    START_BIT,      // Processing potential start bit
    BIT_SAMPLING    // Sampling data/stop bits
  } state_t;

  // Internal registers
  state_t     state, next_state;
  logic [3:0] tick_counter;      // Counts 16x ticks (0-15) within a bit
  logic       start_bit_valid;   // Internal flag for valid start bit

  // State machine and counter logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      tick_counter <= 4'd0;
      start_bit_valid <= 1'b0;
    end
    else begin
      state <= next_state;

      // Tick counter management
      if (tick_16x) begin
        case (state)
          IDLE: begin
            tick_counter <= 4'd0;
            if (falling_edge) begin
              // Reset counter when falling edge detected
              tick_counter <= 4'd1;  // Start from 1 since we're consuming the current tick
            end
          end

          START_BIT, BIT_SAMPLING: begin
            if (tick_counter == 4'd15) begin
              tick_counter <= 4'd0;
            end else begin
              tick_counter <= tick_counter + 4'd1;
            end
          end

          default: tick_counter <= 4'd0;
        endcase
      end

      // Start bit validation (check if still low at middle of bit)
      if (state == START_BIT && tick_16x && tick_counter == 4'd7 && !rx_filtered) begin
        start_bit_valid <= 1'b1;
      end else if (state == IDLE) begin
        start_bit_valid <= 1'b0;
      end
    end
  end

  // Next state logic
  always_comb begin
    next_state = state; // Default: stay in current state

    case (state)
      IDLE: begin
        if (falling_edge) begin
          next_state = START_BIT;
        end
      end

      START_BIT: begin
        if (tick_16x && tick_counter == 4'd15) begin
          if (start_bit_valid) begin
            next_state = BIT_SAMPLING;
          end else begin
            next_state = IDLE; // Invalid start bit, return to IDLE
          end
        end
      end

      BIT_SAMPLING: begin
        // Return to IDLE when frame is complete or errors are cleared
        if (frame_complete || error_clear) begin
          next_state = IDLE;
        end
        // Also return to IDLE if we detect a new falling edge
        // This helps recover from stuck states
        else if (falling_edge && rx_filtered) begin
          next_state = IDLE;
        end
      end

      default: next_state = IDLE;
    endcase
  end

  // Output generation logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_sample <= 1'b1;       // Default to idle level (high)
      bit_valid <= 1'b0;
      start_detected <= 1'b0;
    end
    else begin
      // Default values
      bit_valid <= 1'b0;
      start_detected <= 1'b0;

      if (tick_16x) begin
        // Sample at the middle of the bit (tick 7)
        if (tick_counter == 4'd7) begin
          bit_sample <= rx_filtered;

          case (state)
            START_BIT: begin
              // Signal start bit detection if valid
              if (!rx_filtered) begin
                start_detected <= 1'b1;
              end
            end

            BIT_SAMPLING: begin
              // Signal valid bit for data bits sampling
              bit_valid <= 1'b1;
            end

            default: begin
              // No valid bits in IDLE state
            end
          endcase
        end
      end
    end
  end

endmodule
