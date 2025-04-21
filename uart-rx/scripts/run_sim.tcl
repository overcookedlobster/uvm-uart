# File: run_sim.tcl
# Description: TCL script to run simulation in Vivado (non-project mode)
# Using an include-aware approach for UVM files

# Create logs directory if it doesn't exist
puts "Setting up logs directory..."
if {![file exists logs]} {
    file mkdir logs
}

# Clean up previous workspace
puts "Cleaning up old workspace..."
close_sim -quiet

# Move existing files to logs directory before running new simulation
foreach f [glob -nocomplain webtalk*.jou webtalk*.log xvlog*.log xvlog*.pb xelab*.log xelab*.pb xsim*.jou xsim*.log *.vcd tr_db.log wave.tcl *.wdb] {
    if {[file exists $f]} {
        puts "Moving $f to logs/"
        file rename -force $f logs/
    }
}

# Remove simulation directory
if {[file exists xsim.dir]} {
    puts "Removing xsim.dir directory"
    file delete -force xsim.dir
}

# Define source files
set rtl_files {
    ./src/rtl/uart_bit_sampler.sv
    ./src/rtl/uart_error_manager.sv
    ./src/rtl/uart_input_filter.sv
    ./src/rtl/uart_rx_fifo.sv
    ./src/rtl/uart_rx_shift_register.sv
    ./src/rtl/uart_rx_state_machine.sv
    ./src/rtl/uart_rx_top.sv
}

# Instead of trying to compile files individually, pass just the package, interface and top
# to the compiler, and let it handle the includes automatically
set tb_files {
    ./src/tb/interface/uart_rx_if.sv
    ./src/tb/top/uart_rx_uvm_tb.sv
}

# Create wave.tcl file for signal display
set fp [open "wave.tcl" w]
puts $fp "log_wave -r /*"
puts $fp "add_wave {{/uart_rx_uvm_tb/clk}}"
puts $fp "add_wave {{/uart_rx_uvm_tb/vif}}"
puts $fp "add_wave {{/uart_rx_uvm_tb/dut/*}}"
puts $fp "run 10 ms"
puts $fp "exit"
close $fp

# Compile RTL files
puts "Compiling RTL files..."
foreach file $rtl_files {
    puts "Compiling $file"
    if {[catch {exec xvlog -sv $file} result]} {
        puts "ERROR: Failed to compile $file"
        puts $result
        exit 1
    }
}

# Create a temporary wrapper file to import UVM before including your package
set fp [open "temp_uvm_wrapper.sv" w]
puts $fp "`include \"uvm_macros.svh\""
puts $fp "import uvm_pkg::*;"
puts $fp "`include \"./src/tb/package/uart_rx_pkg.sv\""
close $fp

# Compile the wrapper file first
puts "Compiling UVM package wrapper..."
if {[catch {exec xvlog -sv -L uvm temp_uvm_wrapper.sv} result]} {
    puts "ERROR: Failed to compile UVM wrapper"
    puts $result
    exit 1
}

# Compile testbench files
puts "Compiling testbench files..."
foreach file $tb_files {
    puts "Compiling $file"
    if {[catch {exec xvlog -sv -L uvm $file} result]} {
        puts "ERROR: Failed to compile $file"
        puts $result
        exit 1
    }
}

# Elaborate the design
puts "Elaborating design..."
if {[catch {exec xelab -L uvm -debug typical uart_rx_uvm_tb -s uart_rx_sim} result]} {
    puts "ERROR: Failed to elaborate design"
    puts $result
    exit 1
}

# Run simulation using xsim
puts "Running simulation..."
if {[catch {exec xsim uart_rx_sim -tclbatch wave.tcl} result]} {
    puts "ERROR: Failed to run simulation"
    puts $result
    exit 1
}

# Clean up temp file
file delete -force temp_uvm_wrapper.sv

# Move generated files to logs directory
puts "Moving generated files to logs directory..."
foreach f [glob -nocomplain webtalk*.jou webtalk*.log xvlog*.log xvlog*.pb xelab*.log xelab*.pb xsim*.jou xsim*.log *.vcd tr_db.log vivado*.jou vivado*.log] {
    if {[file exists $f]} {
        puts "Moving $f to logs/"
        file rename -force $f logs/
    }
}

# Copy the .wdb file to logs directory but keep a copy in the main directory
if {[file exists uart_rx_sim.wdb]} {
    file copy -force uart_rx_sim.wdb logs/
    puts "Simulation completed! Waveform file uart_rx_sim.wdb is available in both the main directory and logs/"
    puts "To view the waveform, use: vivado -source scripts/view_wave.tcl"
} else {
    puts "Warning: Waveform file uart_rx_sim.wdb was not generated."
}

# Clean up xsim.dir after simulation
if {[file exists xsim.dir]} {
    puts "Moving xsim.dir to logs directory"
    if {[file exists logs/xsim.dir]} {
        puts "Removing existing logs/xsim.dir"
        file delete -force logs/xsim.dir
    }
    file rename -force xsim.dir logs/
}

puts "Simulation complete!"
