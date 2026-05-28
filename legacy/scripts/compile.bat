@echo off
REM AXI4-Lite UVM Testbench VCS Build and Run Script for Windows

setlocal enabledelayedexpansion

set WORK_DIR=work
set LOG_DIR=logs

REM Create directories if they don't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Compile and elaborate design with VCS
echo.
echo === Compiling AXI4-Lite Design and Testbench with VCS ===
echo.

vcs -sverilog -full64 +warn=all ^
    +incdir=.\rtl ^
    +incdir=.\uvm_tb ^
    rtl\axi4_lite_if.sv ^
    rtl\axi4_lite_slave.sv ^
    uvm_tb\axi4_lite_pkg.sv ^
    uvm_tb\axi4_lite_transaction.sv ^
    uvm_tb\axi4_lite_sequence.sv ^
    uvm_tb\axi4_lite_master_driver.sv ^
    uvm_tb\axi4_lite_monitor.sv ^
    uvm_tb\axi4_lite_sequencer.sv ^
    uvm_tb\axi4_lite_master_agent.sv ^
    uvm_tb\axi4_lite_scoreboard.sv ^
    uvm_tb\axi4_lite_coverage.sv ^
    uvm_tb\axi4_lite_env.sv ^
    uvm_tb\axi4_lite_assertions.sv ^
    uvm_tb\tests\axi4_lite_test.sv ^
    uvm_tb\axi4_lite_tb.sv ^
    -top axi4_lite_tb_top ^
    -o simv ^
    2>&1 | tee %LOG_DIR%\compile.log

if errorlevel 1 (
    echo.
    echo Compilation failed! Check %LOG_DIR%\compile.log for details.
    exit /b 1
)

echo.
echo === Compilation successful ===
echo.

REM Run simulation
echo === Running Simulation ===
echo.

simv +UVM_TESTNAME=axi4_lite_write_read_test -l %LOG_DIR%\sim.log

echo.
echo === Simulation completed ===
echo.
echo Check %LOG_DIR%\sim.log for results
echo.

endlocal
