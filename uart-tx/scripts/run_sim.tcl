# File: run_sim.tcl
# Description: TCL script to run simulation in Vivado (non-project mode)

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
    puts "Moving $f to logs/"
    file rename -force $f logs/
}

# Remove simulation directory
if {[file exists xsim.dir]} {
    puts "Removing xsim.dir directory"
    file delete -force xsim.dir
}

# Define source files
set rtl_files {
    ./src/rtl/baudrate_gen.sv
    ./src/rtl/uart_tx.sv
}

set tb_files {
    ./src/tb/package/uart_tx_pkg.sv
    ./src/tb/interface/uart_tx_if.sv
    ./src/tb/top/uart_tx_uvm_tb.sv
}

# Create wave.tcl file for signal display BEFORE running simulation
set fp [open "wave.tcl" w]
puts $fp "log_wave -r /*"
puts $fp "add_wave {{/uart_tx_uvm_tb/clk}}"
puts $fp "add_wave {{/uart_tx_uvm_tb/rst_n}}"
puts $fp "add_wave {{/uart_tx_uvm_tb/vif}}"
puts $fp "add_wave {{/uart_tx_uvm_tb/dut}}"
puts $fp "run 10 ms"
puts $fp "exit"
close $fp

# Compile RTL and testbench files
puts "Compiling design files..."
foreach file [concat $rtl_files $tb_files] {
    puts "Compiling $file"
    exec xvlog -sv -L uvm $file
}

# Elaborate the design (important to initialize the simulation)
puts "Elaborating design..."
exec xelab -L uvm -debug typical uart_tx_uvm_tb -s uart_tx_sim

# Run simulation using xsim
puts "Running simulation..."
exec xsim -R uart_tx_sim -tclbatch wave.tcl

# Wait a bit for processes to complete
after 1000

# Move generated files to logs directory
puts "Moving generated files to logs directory..."
foreach f [glob -nocomplain webtalk*.jou webtalk*.log xvlog*.log xvlog*.pb xelab*.log xelab*.pb xsim*.jou xsim*.log *.vcd tr_db.log wave.tcl vivado*.jou vivado*.log] {
    puts "Moving $f to logs/"
    file rename -force $f logs/
}

# Copy the .wdb file to logs directory but keep a copy in the main directory for easy access
puts "Copying waveform file to logs directory..."
if {[file exists uart_tx_sim.wdb]} {
    file copy -force uart_tx_sim.wdb logs/
    puts "Simulation completed! Waveform file uart_tx_sim.wdb is available in both the main directory and logs/"
    puts "To view the waveform, use: vivado -source scripts/view_wave.tcl"
} else {
    puts "Warning: Waveform file uart_tx_sim.wdb was not generated."
}

# Clean up xsim.dir after simulation
if {[file exists xsim.dir]} {
    puts "Moving xsim.dir to logs directory"
    # First check if logs/xsim.dir exists and delete it if it does
    if {[file exists logs/xsim.dir]} {
        puts "Removing existing logs/xsim.dir"
        file delete -force logs/xsim.dir
    }
    file rename -force xsim.dir logs/
}

puts "Cleanup completed!"

