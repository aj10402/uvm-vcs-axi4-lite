# Build Guide (VCS Official Flow)

This project uses one official simulator flow: VCS compile to `simv`, then run tests using `simv` or `run_regression.sh`.

## Prerequisites

- Synopsys VCS installed and available on `PATH`
- Bash shell available to run `scripts/compile.sh` and `scripts/run_regression.sh`

## Compile

```bash
cd scripts
./compile.sh
```

`compile.sh` performs VCS compile/elaboration with:

- `-sverilog -full64 +warn=all`
- `-ntb_opts uvm-1.2`
- source list for RTL, UVM TB, assertions, and tests
- top module: `axi4_lite_tb_top`
- output executable: `simv`

## Run One Test

From workspace root after compile:

```bash
./simv +UVM_TESTNAME=axi4_lite_write_read_test -l logs/axi4_lite_write_read_test.log
```

## Run Full Regression

```bash
cd scripts
./run_regression.sh
```

Regression executes:

- `axi4_lite_write_read_test`
- `axi4_lite_partial_write_test`
- `axi4_lite_stress_test`
- `axi4_lite_back_to_back_test`
- `axi4_lite_reset_test`

## Troubleshooting

- If UVM package lookup fails, verify VCS installation and keep `-ntb_opts uvm-1.2` in `scripts/compile.sh`.
- If class-not-found errors appear, ensure `uvm_tb/axi4_lite_pkg.sv` includes all class files.
- If a test hangs, inspect `logs/*.log` for handshake or response-order assertion failures.
