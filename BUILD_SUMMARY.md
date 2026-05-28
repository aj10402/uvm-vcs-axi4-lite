# Build Summary

## Final State

The project is aligned to one architecture and one simulator flow.

## Architecture

- Single DUT: `rtl/axi4_lite_slave.sv`
- Active UVM master agent for stimulus
- Passive protocol-aware monitor for observation
- Scoreboard reference model with WSTRB-aware memory updates
- Functional coverage sampling the same monitor transactions as scoreboard

There is no slave agent/driver in the verification path.

## Build and Run Flow

Official flow:

1. `scripts/compile.sh` (VCS compile/elaboration to `simv`)
2. `scripts/run_regression.sh` (suite execution)

`compile.sh` includes `-ntb_opts uvm-1.2`.

## Regression Suite

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## Key Technical Consistency

- Sequence names used by tests exist in `uvm_tb/axi4_lite_sequence.sv`
- Coverage uses real transaction fields (`awaddr`, `araddr`, `wdata`, `wstrb`, `bresp`, `rresp`)
- Assertions module uses `$error` (no UVM macro dependency in plain module)
