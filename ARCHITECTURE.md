# AXI4-Lite UVM Architecture

## Final Verification Scope

This repository verifies one DUT only:

- `rtl/axi4_lite_slave.sv` (AXI4-Lite slave)
- `rtl/axi4_lite_if.sv` (interface)

There is no slave agent/driver in the active verification path.

## UVM Components

- Active master agent
: `sequencer + master driver + passive monitor`
- Scoreboard
: reference memory model with WSTRB-aware writes and read-data checking
- Coverage
: samples the same observed monitor transactions used by scoreboard
- Assertions module
: protocol checks in `uvm_tb/axi4_lite_assertions.sv`

## Single Data Flow

`sequence -> sequencer -> master driver -> DUT -> passive monitor -> scoreboard + coverage`

## Transaction Model

Stimulus fields (randomized in sequences):

- `trans_type`
- `awaddr`
- `wdata`
- `wstrb`
- `araddr`

Observed fields (captured by monitor):

- `awready`, `wready`, `bvalid`, `bresp`
- `arready`, `rvalid`, `rdata`, `rresp`

## Monitor Correlation Model

The passive monitor independently tracks AXI4-Lite channels:

- AW handshake
- W handshake
- B handshake
- AR handshake
- R handshake

It correlates completed write/read transactions via FIFO ordering, which is valid for this simple AXI4-Lite DUT model.

## Scoreboard Model

- Keeps reference memory
- Applies writes with WSTRB byte enables
- Compares read data to expected memory contents
- Reports mismatches with address/expected/actual/response context

## Reset Behavior

- Initial reset is driven in top-level testbench
- Reset test sequence also applies runtime reset and verifies post-reset behavior

## Official Build/Run

- Compile: `scripts/compile.sh`
- Regression: `scripts/run_regression.sh`
- Simulator flow: VCS `simv` with UVM 1.2

## Regression Tests

Required and implemented:

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## Legacy Artifacts

Deprecated files are moved under `legacy/` and are not part of active verification flow.
