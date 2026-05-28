#!/bin/bash

# AXI4-Lite UVM Testbench VCS Build and Run Script

# Set work directory
LOG_DIR="logs"

# Create directories if they don't exist
mkdir -p $LOG_DIR

# Compile and elaborate with VCS
echo "=== Compiling AXI4-Lite Design and Testbench with VCS ==="

vcs -sverilog -full64 +warn=all \
    -ntb_opts uvm-1.2 \
    +incdir+. \
    axi4_lite_if.sv \
    axi4_lite_slave.sv \
    axi4_lite_assertions.sv \
    axi4_lite_pkg.sv \
    axi4_lite_test.sv \
    axi4_lite_tb.sv \
    -top axi4_lite_tb_top \
    -o simv \
    2>&1 | tee $LOG_DIR/compile.log

# Check compilation status
if [ $? -ne 0 ]; then
    echo "Compilation failed! Check logs/compile.log for details."
    exit 1
fi

echo "=== Compilation successful ==="

# Run simulation
echo "=== Running Simulation ==="

./simv +UVM_TESTNAME=axi4_lite_write_read_test -l $LOG_DIR/sim.log

echo "=== Simulation completed ==="
echo "Check logs/sim.log for results"
