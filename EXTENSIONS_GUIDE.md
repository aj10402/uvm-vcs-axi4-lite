# Extension Guide

This guide describes how to extend the current single-DUT architecture without reintroducing old multi-agent patterns.

## Current Baseline

- DUT: `rtl/axi4_lite_slave.sv`
- Stimulus: active master agent (`sequencer + master driver`)
- Observation: one passive monitor
- Checking: scoreboard + coverage consume the same monitor stream

## 1. Add a New Test Class

Create a new test in `uvm_tb/tests/` that reuses the existing environment.

```systemverilog
class axi4_lite_my_test extends axi4_lite_base_test;
    `uvm_component_utils(axi4_lite_my_test)

    function new(string name = "axi4_lite_my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_run_phase phase);
        axi4_lite_stress_sequence seq;
        phase.raise_objection(this);

        seq = axi4_lite_stress_sequence::type_id::create("seq");
        seq.num_transactions = 100;
        seq.start(env.master_agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass
```

If adding a new file, include it from `uvm_tb/axi4_lite_pkg.sv`.

## 2. Add a New Sequence

Create sequence classes in `uvm_tb/axi4_lite_sequence.sv` or a new file included by the package.
Use `axi4_lite_transaction` fields that exist in the model (`awaddr`, `araddr`, `wdata`, `wstrb`, `bresp`, `rresp`, `rdata`).

## 3. Extend Coverage

Coverage should continue sampling monitor-observed transactions only.
Do not sample stimulus-only objects from driver/sequencer.

Example pattern:

```systemverilog
class my_cov extends axi4_lite_coverage;
    `uvm_component_utils(my_cov)

    // Add additional coverpoints/crosses using tr.<real_field>
endclass
```

## 4. Extend Scoreboard Safely

Extend by overriding `write(...)` and/or helper functions, because the scoreboard is connected through `uvm_analysis_imp`.
Do not introduce `master_fifo.get(txn)` unless you explicitly add and connect such a FIFO path.

## 5. Add Regression Tests

Keep `scripts/run_regression.sh` test names synchronized with classes in `uvm_tb/tests/axi4_lite_test.sv`.

Current regression set:

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## 6. Build and Run

Compile with VCS:

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
./simv +UVM_TESTNAME=axi4_lite_write_read_test -l logs/axi4_lite_write_read_test.log
```

## 7. Legacy Policy

- Active flow uses only the current single-DUT architecture.
- Deprecated files/scripts are isolated under `legacy/`.
- Do not reference legacy build commands or old class names in new docs/tests.
