# AXI4-Lite UVM Testbench

UVM verification environment for a single AXI4-Lite slave DUT using an active master agent, a protocol-aware passive monitor, reference-model scoreboard, functional coverage, assertions, and VCS regression.

## Final Architecture

- DUT: `rtl/axi4_lite_slave.sv`
- Interface: `rtl/axi4_lite_if.sv`
- One active UVM master agent: sequencer + driver + passive monitor
- Scoreboard and coverage consume the same observed monitor transactions
- No slave agent and no slave driver in the verification path

## Verification Data Flow

`sequence -> sequencer -> master driver -> DUT -> passive monitor -> scoreboard + coverage`

## Regression Tests

`uvm_tb/tests/axi4_lite_test.sv` includes the expected regression classes:

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## Official Build and Run Flow

Build with VCS:

```bash
cd scripts
./compile.sh
```

Run full regression:

```bash
./run_regression.sh
```

Run one test:

```bash
./simv +UVM_TESTNAME=axi4_lite_partial_write_test -l logs/axi4_lite_partial_write_test.log
```

## What Is Covered

- Protocol-aware monitor correlation of AW, W, B, AR, R handshakes
- Scoreboard reference memory update on writes with WSTRB byte enables
- Read-data compare against expected memory content
- Functional coverage on transaction type, addresses, WSTRB, write data, and responses
- Assertions for reset, ordering, alignment, and response validity
