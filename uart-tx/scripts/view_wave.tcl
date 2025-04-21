# File: view_wave.tcl
# Description: Script to open waveform viewer in Vivado
# Usage: vivado -mode gui -source scripts/view_wave.tcl

# Set script variables
set project_dir [pwd]
set log_dir [file join $project_dir "logs"]

# Create logs directory if it doesn't exist
if {![file exists $log_dir]} {
    puts "Creating logs directory"
    file mkdir $log_dir
}

# Set Vivado preferences to store logs in logs directory
set_param messaging.defaultLimit 1000

# Define a function to move Vivado generated files to logs
proc move_logs_to_directory {} {
    global log_dir
    # Move any Vivado logs that might have been created to logs directory
    foreach f [glob -nocomplain [file join [pwd] "vivado*.jou"] [file join [pwd] "vivado*.log"] [file join [pwd] "*.jou"] [file join [pwd] "*.log"]] {
        if {[file exists $f]} {
            puts "Moving log file $f to logs directory"
            file copy -force $f $log_dir
            file delete -force $f
        }
    }
}

# Try to move any existing logs before continuing
move_logs_to_directory

# Check if waveform file exists
set wdb_file [file join $project_dir "uart_tx_sim.wdb"]
if {![file exists $wdb_file]} {
    # Try logs directory
    set wdb_file [file join $log_dir "uart_tx_sim.wdb"]
    if {![file exists $wdb_file]} {
        puts "ERROR: Waveform file not found in either location!"
        return 1
    }
}

# Open the waveform database
puts "Opening waveform database: $wdb_file"
open_wave_database $wdb_file

# Add commonly viewed signals
add_wave /uart_tx_uvm_tb/clk
add_wave /uart_tx_uvm_tb/rst_n
add_wave /uart_tx_uvm_tb/vif/tx_data
add_wave /uart_tx_uvm_tb/vif/tx_start
add_wave /uart_tx_uvm_tb/vif/cts
add_wave /uart_tx_uvm_tb/vif/tx_out
add_wave /uart_tx_uvm_tb/vif/tx_busy
add_wave /uart_tx_uvm_tb/vif/tx_done
add_wave /uart_tx_uvm_tb/dut/*

# Adjust zoom to see the entire simulation
zoom fit

puts "Waveform viewer launched successfully!"

# Make sure any newly generated files are moved to logs
after 2000 {move_logs_to_directory}

# Clean up any xsim directories that may have been created
after 3000 {
    if {[file exists xsim.dir]} {
        puts "Moving new xsim.dir to logs directory"
        if {[file exists [file join $log_dir "xsim.dir"]]} {
            puts "Removing existing logs/xsim.dir"
            file delete -force [file join $log_dir "xsim.dir"]
        }
        file rename -force xsim.dir $log_dir
    }
}
