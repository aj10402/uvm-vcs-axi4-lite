# Quick Reference

## Core Structure

- `rtl/axi4_lite_if.sv` - AXI4-Lite interface
- `rtl/axi4_lite_slave.sv` - DUT
- `uvm_tb/axi4_lite_master_agent.sv` - active master agent
- `uvm_tb/axi4_lite_monitor.sv` - passive protocol-aware monitor
- `uvm_tb/axi4_lite_scoreboard.sv` - reference model checks
- `uvm_tb/axi4_lite_coverage.sv` - functional coverage
- `uvm_tb/tests/axi4_lite_test.sv` - regression test classes

## Official Commands

Compile:

```bash
cd scripts
./compile.sh
```

Run regression:

```bash
./run_regression.sh
```

Run a specific test:

```bash
./simv +UVM_TESTNAME=axi4_lite_back_to_back_test -l logs/axi4_lite_back_to_back_test.log
```

## Required Regression Test Names

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## Useful Log Checks

```bash
grep "SCOREBOARD" logs/*.log
grep "MONITOR" logs/*.log
grep "AXI4_LITE_ASSERT" logs/*.log
```
