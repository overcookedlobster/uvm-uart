/*
 * File: uart_rx_state_machine.sv
 * Description: State machine for UART receiver operation
 */

module uart_rx_state_machine (
  input  logic        clk,             // System clock
  input  logic        rst_n,           // Active-low reset
  input  logic        bit_valid,       // Valid bit indication from bit sampler
  input  logic        bit_sample,      // Sampled bit value from bit sampler
  input  logic        start_detected,  // Start bit detection from bit sampler
  input  logic [3:0]  data_bits,       // Configuration: number of data bits (5-9)
  input  logic [1:0]  parity_mode,     // Configuration: 0=none, 1=odd, 2=even, 3=mark
  input  logic        stop_bits,       // Configuration: 0=1 stop bit, 1=2 stop bits
  input  logic        error_clear,     // Clear error flags signal

  output logic        frame_active,    // Indicates active frame reception
  output logic        sample_enable,   // Enable signal for shift register
  output logic [3:0]  bit_count,       // Current bit position
  output logic        is_data_bit,     // Indicates current bit is a data bit
  output logic        is_parity_bit,   // Indicates current bit is a parity bit
  output logic        is_stop_bit,     // Indicates current bit is a stop bit
  output logic        frame_complete,  // Pulse indicating frame reception complete
  output logic        frame_error,     // Indicates stop bit error
  output logic        parity_error     // Indicates parity error
);

  // State machine definition
  typedef enum logic [2:0] {
    IDLE,           // Waiting for start bit
    DATA_BITS,      // Receiving data bits
    PARITY_BIT,     // Receiving parity bit (if enabled)
    STOP_BIT_1,     // Receiving first stop bit
    STOP_BIT_2,     // Receiving second stop bit (if enabled)
    COMPLETE        // Frame reception complete
  } uart_state_t;

  // State and control registers
  uart_state_t state, next_state;
  logic [3:0] bit_position;
  logic parity_expected;
  logic parity_accumulator;
  logic frame_err_reg, parity_err_reg;
  logic frame_complete_reg;

  //----------------------------------------------------------------------------
  // State Register Update
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end
    else begin
      state <= next_state;
    end
  end

  //----------------------------------------------------------------------------
  // Bit Position Counter
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_position <= '0;
    end
    else if (state == IDLE || next_state == IDLE) begin
      bit_position <= '0;
    end
    else if (state == DATA_BITS && bit_valid) begin
      bit_position <= bit_position + 1'b1;
    end
  end

  //----------------------------------------------------------------------------
  // Parity Calculation - Accumulate parity
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_accumulator <= 1'b0;
    end
    else if (state == IDLE || next_state == IDLE) begin
      parity_accumulator <= 1'b0;
    end
    else if (state == DATA_BITS && bit_valid) begin
      // XOR current bit with running parity to accumulate parity
      parity_accumulator <= parity_accumulator ^ bit_sample;
    end
  end

  //----------------------------------------------------------------------------
  // Error Detection
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_err_reg <= 1'b0;
      parity_err_reg <= 1'b0;
    end
    else begin
      // Clear errors on external request only
      if (error_clear) begin
        frame_err_reg <= 1'b0;
        parity_err_reg <= 1'b0;
      end
      else begin
        // Detect frame error (stop bit not high)
        if ((state == STOP_BIT_1 || state == STOP_BIT_2) && bit_valid) begin
          // Set frame error if stop bit is not 1
          if (!bit_sample) begin
            frame_err_reg <= 1'b1;
          end
        end

        // Detect parity error
        if (state == PARITY_BIT && bit_valid) begin
          // Set parity error if received parity doesn't match expected
          if (bit_sample != parity_expected) begin
            parity_err_reg <= 1'b1;
          end
        end
      end
    end
  end

  //----------------------------------------------------------------------------
  // Frame Completion Flag
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_complete_reg <= 1'b0;
    end
    else begin
      frame_complete_reg <= (next_state == COMPLETE);
    end
  end

  //----------------------------------------------------------------------------
  // Next State Logic
  //----------------------------------------------------------------------------
  always_comb begin
    // Default: stay in current state
    next_state = state;

    case (state)
      IDLE: begin
        if (start_detected)
          next_state = DATA_BITS;
      end

      DATA_BITS: begin
        if (bit_valid && bit_position >= (data_bits - 1))
          next_state = (parity_mode == 2'b00) ? STOP_BIT_1 : PARITY_BIT;
      end

      PARITY_BIT: begin
        if (bit_valid)
          next_state = STOP_BIT_1;
      end

      STOP_BIT_1: begin
        if (bit_valid)
          next_state = stop_bits ? STOP_BIT_2 : COMPLETE;
      end

      STOP_BIT_2: begin
        if (bit_valid)
          next_state = COMPLETE;
      end

      COMPLETE: begin
        next_state = IDLE;  // Always return to IDLE after COMPLETE
      end
    endcase
  end

  //----------------------------------------------------------------------------
  // Expected Parity Calculation
  //----------------------------------------------------------------------------
  always_comb begin
    case (parity_mode)
      2'b01:   parity_expected = ~parity_accumulator; // Odd parity
      2'b10:   parity_expected = parity_accumulator;  // Even parity
      2'b11:   parity_expected = 1'b1;                // Mark parity
      default: parity_expected = 1'b0;                // Space parity
    endcase
  end

  //----------------------------------------------------------------------------
  // Output Assignments
  //----------------------------------------------------------------------------
  assign frame_active   = (state != IDLE && state != COMPLETE);
  assign sample_enable  = (state == DATA_BITS && bit_valid);
  assign bit_count      = bit_position;
  assign is_data_bit    = (state == DATA_BITS);
  assign is_parity_bit  = (state == PARITY_BIT);
  assign is_stop_bit    = (state == STOP_BIT_1 || state == STOP_BIT_2);
  assign frame_complete = frame_complete_reg;
  assign frame_error    = frame_err_reg;
  assign parity_error   = parity_err_reg;

endmodule
