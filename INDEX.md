# Project Index

## Workspace

`c:\Users\Ahmed\Desktop\UVM CODE VCS\`

## RTL

- `rtl/axi4_lite_if.sv`
- `rtl/axi4_lite_slave.sv`

## UVM Testbench

- `uvm_tb/axi4_lite_pkg.sv`
- `uvm_tb/axi4_lite_transaction.sv`
- `uvm_tb/axi4_lite_sequence.sv`
- `uvm_tb/axi4_lite_master_driver.sv`
- `uvm_tb/axi4_lite_monitor.sv`
- `uvm_tb/axi4_lite_sequencer.sv`
- `uvm_tb/axi4_lite_master_agent.sv`
- `uvm_tb/axi4_lite_scoreboard.sv`
- `uvm_tb/axi4_lite_coverage.sv`
- `uvm_tb/axi4_lite_env.sv`
- `uvm_tb/axi4_lite_assertions.sv`
- `uvm_tb/axi4_lite_tb.sv`
- `uvm_tb/tests/axi4_lite_test.sv`

## Scripts

- `scripts/compile.sh` (official compile flow)
- `scripts/run_regression.sh` (official regression flow)
- `legacy/scripts/compile.bat` (legacy convenience wrapper)

## Documentation

- `README.md`
- `ARCHITECTURE.md`
- `BUILD_GUIDE.md`
- `QUICK_REFERENCE.md`
- `EXTENSIONS_GUIDE.md`
- `BUILD_SUMMARY.md`

## Final Verification Architecture

Single-DUT flow:

`sequence -> sequencer -> master driver -> DUT -> passive monitor -> scoreboard + coverage`

No slave agent and no slave driver are part of the verification path.
