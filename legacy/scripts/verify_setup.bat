@echo off
REM Verification Script for AXI4-Lite UVM Testbench Setup
REM This script checks if all files are in place and the environment is ready

echo.
echo ===============================================
echo AXI4-Lite UVM Testbench - Setup Verification
echo ===============================================
echo.

setlocal enabledelayedexpansion

set PASSED=0
set FAILED=0

REM Check RTL files
echo Checking RTL files...
if exist "rtl\axi4_lite_if.sv" (
    echo [OK] rtl\axi4_lite_if.sv
    set /a PASSED+=1
) else (
    echo [FAIL] rtl\axi4_lite_if.sv NOT FOUND
    set /a FAILED+=1
)

if exist "rtl\axi4_lite_master.sv" (
    echo [OK] rtl\axi4_lite_master.sv
    set /a PASSED+=1
) else (
    echo [FAIL] rtl\axi4_lite_master.sv NOT FOUND
    set /a FAILED+=1
)

if exist "rtl\axi4_lite_slave.sv" (
    echo [OK] rtl\axi4_lite_slave.sv
    set /a PASSED+=1
) else (
    echo [FAIL] rtl\axi4_lite_slave.sv NOT FOUND
    set /a FAILED+=1
)

REM Check UVM files
echo.
echo Checking UVM testbench files...
if exist "uvm_tb\axi4_lite_pkg.sv" (
    echo [OK] uvm_tb\axi4_lite_pkg.sv
    set /a PASSED+=1
) else (
    echo [FAIL] uvm_tb\axi4_lite_pkg.sv NOT FOUND
    set /a FAILED+=1
)

if exist "uvm_tb\axi4_lite_transaction.sv" (
    echo [OK] uvm_tb\axi4_lite_transaction.sv
    set /a PASSED+=1
) else (
    echo [FAIL] uvm_tb\axi4_lite_transaction.sv NOT FOUND
    set /a FAILED+=1
)

if exist "uvm_tb\axi4_lite_tb.sv" (
    echo [OK] uvm_tb\axi4_lite_tb.sv
    set /a PASSED+=1
) else (
    echo [FAIL] uvm_tb\axi4_lite_tb.sv NOT FOUND
    set /a FAILED+=1
)

if exist "uvm_tb\tests\axi4_lite_test.sv" (
    echo [OK] uvm_tb\tests\axi4_lite_test.sv
    set /a PASSED+=1
) else (
    echo [FAIL] uvm_tb\tests\axi4_lite_test.sv NOT FOUND
    set /a FAILED+=1
)

REM Check build scripts
echo.
echo Checking build scripts...
if exist "scripts\compile.bat" (
    echo [OK] scripts\compile.bat
    set /a PASSED+=1
) else (
    echo [FAIL] scripts\compile.bat NOT FOUND
    set /a FAILED+=1
)

if exist "Makefile" (
    echo [OK] Makefile
    set /a PASSED+=1
) else (
    echo [FAIL] Makefile NOT FOUND
    set /a FAILED+=1
)

REM Check documentation
echo.
echo Checking documentation files...
if exist "README.md" (
    echo [OK] README.md
    set /a PASSED+=1
) else (
    echo [FAIL] README.md NOT FOUND
    set /a FAILED+=1
)

if exist "BUILD_GUIDE.md" (
    echo [OK] BUILD_GUIDE.md
    set /a PASSED+=1
) else (
    echo [FAIL] BUILD_GUIDE.md NOT FOUND
    set /a FAILED+=1
)

if exist "ARCHITECTURE.md" (
    echo [OK] ARCHITECTURE.md
    set /a PASSED+=1
) else (
    echo [FAIL] ARCHITECTURE.md NOT FOUND
    set /a FAILED+=1
)

REM Summary
echo.
echo ===============================================
echo Summary: !PASSED! files OK, !FAILED! files missing
echo ===============================================
echo.

if !FAILED! EQU 0 (
    echo.
    echo ✓ All files present and ready!
    echo.
    echo Next steps:
    echo 1. Navigate to scripts folder: cd scripts
    echo 2. Run build script: compile.bat
    echo 3. Check logs folder for results
    echo.
) else (
    echo.
    echo ✗ Some files are missing. Please check the file structure.
    echo.
)

endlocal
pause
