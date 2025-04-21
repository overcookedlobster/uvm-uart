# UART Core with UVM Verification

This repository contains UART (Universal Asynchronous Receiver/Transmitter) cores with comprehensive UVM (Universal Verification Methodology) testbenches. The project includes separate, fully-tested implementations for both transmitter (TX) and receiver (RX) components.

## Repository Structure

```
.
├── README.md
├── uart-rx/    # UART Receiver implementation and verification
└── uart-tx/    # UART Transmitter implementation and verification
```

## Components

### UART-RX
A complete, configurable UART receiver implementation with robust error detection and flow control. The receiver includes features like:
- Multi-bit data reception (5-9 bits)
- Configurable parity (none, odd, even, mark)
- Baud rate generator
- Error detection (framing, parity, break condition)
- FIFO buffer

See the [UART-RX README](uart-rx/README.md) for detailed information.

### UART-TX
A flexible UART transmitter implementation with configurable parameters and flow control. The transmitter includes:
- Multi-bit data transmission
- Configurable parity
- One or two stop bits
- Flow control (CTS)
- Baud rate generator

See the [UART-TX README](uart-tx/README.md) for detailed information.

## Getting Started

Each component has its own Vivado TCL scripts for simulation and waveform viewing:

```bash
# For UART-RX
cd uart-rx
vivado -mode batch -source scripts/run_sim.tcl
vivado -source scripts/view_wave.tcl  # To view waveforms

# For UART-TX
cd uart-tx
vivado -mode batch -source scripts/run_sim.tcl
vivado -source scripts/view_wave.tcl  # To view waveforms
```

Refer to each component's README for specific configuration options and detailed usage instructions.
