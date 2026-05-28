# Makefile for AXI4-Lite UVM Testbench with VCS

.PHONY: clean compile run run-test help

# Compiler commands
VCS = vcs

# Directories
WORK_DIR = work
LOG_DIR = logs
RTL_DIR = rtl
TB_DIR = uvm_tb
TEST_DIR = $(TB_DIR)/tests

# Compiler flags
VCS_FLAGS = -sverilog -full64 +warn=all

# Source files (VCS compiles all together, no separate elaborate step)
RTL_SOURCES = \
	$(RTL_DIR)/axi4_lite_if.sv \
	$(RTL_DIR)/axi4_lite_slave.sv

TB_SOURCES = \
	$(TB_DIR)/axi4_lite_pkg.sv \
	$(TB_DIR)/axi4_lite_transaction.sv \
	$(TB_DIR)/axi4_lite_sequence.sv \
	$(TB_DIR)/axi4_lite_master_driver.sv \
	$(TB_DIR)/axi4_lite_monitor.sv \
	$(TB_DIR)/axi4_lite_sequencer.sv \
	$(TB_DIR)/axi4_lite_master_agent.sv \
	$(TB_DIR)/axi4_lite_scoreboard.sv \
	$(TB_DIR)/axi4_lite_coverage.sv \
	$(TB_DIR)/axi4_lite_env.sv \
	$(TEST_DIR)/axi4_lite_test.sv \
	$(TB_DIR)/axi4_lite_tb.sv

# Test name (can be overridden)
TEST_NAME ?= axi4_lite_write_read_test

help:
	@echo "AXI4-Lite UVM Testbench - VCS Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make compile      - Compile and elaborate design"
	@echo "  make run          - Compile and run default test"
	@echo "  make run-test     - Run specific test. Usage: make run-test TEST_NAME=test_name"
	@echo "  make clean        - Clean up generated files"
	@echo ""
	@echo "Example: make run-test TEST_NAME=axi4_lite_partial_write_test"
	@echo ""

$(LOG_DIR):
	mkdir -p $(LOG_DIR)

compile: $(LOG_DIR)
	@echo "=== Compiling AXI4-Lite Design and Testbench with VCS ==="
	$(VCS) $(VCS_FLAGS) \
		+incdir+$(RTL_DIR) \
		+incdir+$(TB_DIR) \
		$(RTL_SOURCES) $(TB_SOURCES) \
		-top axi4_lite_tb_top \
		-o simv \
		2>&1 | tee $(LOG_DIR)/compile.log
	@echo "=== Compilation complete ==="

run: compile
	@echo "=== Running simulation with test: $(TEST_NAME) ==="
	./simv +UVM_TESTNAME=$(TEST_NAME) -l $(LOG_DIR)/sim.log
	@echo "=== Simulation complete, check $(LOG_DIR)/sim.log ==="

run-test: compile
	@echo "=== Running simulation with test: $(TEST_NAME) ==="
	./simv +UVM_TESTNAME=$(TEST_NAME) -l $(LOG_DIR)/sim_$(TEST_NAME).log
	@echo "=== Simulation complete, check $(LOG_DIR)/sim_$(TEST_NAME).log ==="

clean:
	rm -rf work
	rm -rf $(LOG_DIR)
	rm -f simv simv.daidir *.log *.history
	@echo "=== Cleanup complete ==="
