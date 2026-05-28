// Base Sequence
class axi4_lite_base_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_base_sequence)

    function new(string name = "axi4_lite_base_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        txn = axi4_lite_transaction::type_id::create("txn");
        start_item(txn);
        assert(txn.randomize());
        finish_item(txn);
    endtask

endclass

// Write-then-Read Test Sequence
// Writes to known addresses, then reads them back for verification
class axi4_lite_write_read_pairing_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_write_read_pairing_sequence)

    rand int num_pairs = 5;

    function new(string name = "axi4_lite_write_read_pairing_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        logic [31:0] test_addr;
        logic [31:0] test_data;

        `uvm_info("SEQ", 
            $sformatf("Write-Read Pairing: %0d write-then-read pairs", num_pairs), 
            UVM_MEDIUM)

        repeat(num_pairs) begin
            // Randomize address and data
            test_addr = $urandom() & 32'h0000007C;  // Keep in 0x00-0x7C range
            test_addr = test_addr & 32'hFFFFFFFC;  // Align to word boundary
            test_data = $urandom();

            // WRITE transaction
            txn = axi4_lite_transaction::type_id::create("write_txn");
            start_item(txn);
            assert(txn.randomize() with {
                txn.trans_type == axi4_lite_transaction::WRITE;
                txn.awaddr == test_addr;
                txn.wdata == test_data;
                txn.wstrb == 4'b1111;  // Full word write
            });
            finish_item(txn);
            #100;  // Wait for write B-channel response and scoreboard update before reading

            // READ transaction immediately after - should see the same data
            txn = axi4_lite_transaction::type_id::create("read_txn");
            start_item(txn);
            assert(txn.randomize() with {
                txn.trans_type == axi4_lite_transaction::READ;
                txn.araddr == test_addr;  // SAME address
            });
            finish_item(txn);
            // Scoreboard verifies read data matches written data
            #10;
        end

        `uvm_info("SEQ", "Write-Read Pairing sequence complete", UVM_MEDIUM)
    endtask

endclass

// Partial Write Test - using WSTRB for byte-enable
class axi4_lite_partial_write_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_partial_write_sequence)

    rand int num_writes = 4;

    function new(string name = "axi4_lite_partial_write_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;

        `uvm_info("SEQ", "Testing partial writes with WSTRB...", UVM_MEDIUM)

        // Write full word to address 0
        txn = axi4_lite_transaction::type_id::create("write_full");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::WRITE;
            txn.awaddr == 32'h00;
            txn.wdata == 32'hFFFF0000;
            txn.wstrb == 4'b1111;  // Write all bytes
        });
        finish_item(txn);
        // finish_item blocks until the driver calls item_done() after B-channel completes,
        // so the full AXI write (AW+W+B) is already done before #10 runs.
        // #10 is just extra idle time between writes — not a timing dependency.
        #10;

        // Write only lower 2 bytes (byte enables: 0x3)
        txn = axi4_lite_transaction::type_id::create("write_byte01");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::WRITE;
            txn.awaddr == 32'h04;
            txn.wdata == 32'h00000055;
            txn.wstrb == 4'b0011;  // Byte enables for bytes 0-1
        });
        finish_item(txn);
        #10;

        // Write only upper 2 bytes (byte enables: 0xC)
        txn = axi4_lite_transaction::type_id::create("write_byte23");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::WRITE;
            txn.awaddr == 32'h08;
            txn.wdata == 32'hAA000000;
            txn.wstrb == 4'b1100;  // Byte enables for bytes 2-3
        });
        finish_item(txn);
        #10;

        // Read back to verify partial writes
        #20;
        for (int i = 0; i < 3; i++) begin
            txn = axi4_lite_transaction::type_id::create($sformatf("read_verify_%0d", i));
            start_item(txn);
            assert(txn.randomize() with {
                txn.trans_type == axi4_lite_transaction::READ;
                txn.araddr == 32'h00 + (i * 4);
            });
            finish_item(txn);
            #10;
        end

        `uvm_info("SEQ", "Partial write sequence complete", UVM_MEDIUM)
    endtask

endclass

// Stress Test - alternating writes and reads
class axi4_lite_stress_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_stress_sequence)

    rand int num_transactions = 20;

    function new(string name = "axi4_lite_stress_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        logic [31:0] ref_mem[32];

        // Initialize reference
        for (int i = 0; i < 32; i++) ref_mem[i] = 32'h0;

        `uvm_info("SEQ", $sformatf("Stress test with %0d random transactions...", num_transactions), UVM_MEDIUM)

        repeat(num_transactions) begin
            txn = axi4_lite_transaction::type_id::create("stress_txn");
            start_item(txn);
            
            if (txn.randomize()) begin
                // Track reference memory for writes
                if (txn.trans_type == axi4_lite_transaction::WRITE) begin
                    // Update reference with WSTRB
                    for (int i = 0; i < 4; i++) begin
                        if (txn.wstrb[i]) begin
                            ref_mem[txn.awaddr[6:2]][i*8 +: 8] = txn.wdata[i*8 +: 8];
                        end
                    end
                end
            end
            
            finish_item(txn);
            #10;
        end

        `uvm_info("SEQ", "Stress test sequence complete", UVM_MEDIUM)
    endtask

endclass

// Back-to-back Test - no delays between transactions
class axi4_lite_back_to_back_sequence extends uvm_sequence #(axi4_lite_transaction);

    `uvm_object_utils(axi4_lite_back_to_back_sequence)

    rand int num_transactions = 20;

    function new(string name = "axi4_lite_back_to_back_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;

        `uvm_info("SEQ",
            $sformatf("Back-to-back test: %0d consecutive transactions...", num_transactions),
            UVM_MEDIUM)

        repeat(num_transactions) begin
            txn = axi4_lite_transaction::type_id::create("b2b_txn");
            start_item(txn);
            assert(txn.randomize() with {
                txn.awaddr[31:7] == 0;  // Keep within 0x00-0x7C byte address range
                txn.araddr[31:7] == 0;
            });
            finish_item(txn);
            // No delay - back-to-back transactions
        end

        `uvm_info("SEQ", "Back-to-back test sequence complete", UVM_MEDIUM)
    endtask

endclass

// Reset Test - verify reset behavior
class axi4_lite_reset_sequence extends uvm_sequence #(axi4_lite_transaction);

    `uvm_object_utils(axi4_lite_reset_sequence)

    function new(string name = "axi4_lite_reset_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;

        `uvm_info("SEQ", "Reset test: Write data, reset, verify memory cleared...", UVM_MEDIUM)

        // Write some data
        txn = axi4_lite_transaction::type_id::create("pre_reset_write");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::WRITE;
            txn.awaddr == 32'h00;
            txn.wdata == 32'hAAAAAAAA;
            txn.wstrb == 4'b1111;
        });
        finish_item(txn);
        #10;

        // Read to verify write worked
        txn = axi4_lite_transaction::type_id::create("pre_reset_read");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::READ;
            txn.araddr == 32'h00;
        });
        finish_item(txn);
        #50;  // Wait for read to complete

        // Trigger reset via UVM event — no $root hierarchical path dependency
        `uvm_info("SEQ", "Asserting reset pulse (100ns)...", UVM_MEDIUM)
        begin
            uvm_event reset_req_ev, reset_done_ev;
            reset_req_ev  = uvm_event_pool::get_global_pool().get("reset_trigger");
            reset_done_ev = uvm_event_pool::get_global_pool().get("reset_done");
            uvm_config_db #(int)::set(null, "", "reset_duration_ns", 100);
            reset_req_ev.trigger();
            reset_done_ev.wait_trigger();
        end
        `uvm_info("SEQ", "Reset released, memory should be cleared", UVM_MEDIUM)

        // Wait for reset to settle
        #100;

        // Read after reset to verify memory cleared (should read 0x00000000)
        txn = axi4_lite_transaction::type_id::create("post_reset_read");
        start_item(txn);
        assert(txn.randomize() with {
            txn.trans_type == axi4_lite_transaction::READ;
            txn.araddr == 32'h00;
        });
        finish_item(txn);
        #50;

        `uvm_info("SEQ", "Reset test sequence complete", UVM_MEDIUM)
    endtask

endclass

// Write-only Test Sequence
class axi4_lite_write_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_write_sequence)

    int num_writes = 5;

    function new(string name = "axi4_lite_write_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        repeat(num_writes) begin
            txn = axi4_lite_transaction::type_id::create("txn");
            start_item(txn);
            assert(txn.randomize() with {txn.trans_type == axi4_lite_transaction::WRITE;});
            finish_item(txn);
            #10;
        end
    endtask

endclass

class axi4_lite_read_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_read_sequence)

    int num_reads = 5;

    function new(string name = "axi4_lite_read_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        repeat(num_reads) begin
            txn = axi4_lite_transaction::type_id::create("txn");
            start_item(txn);
            assert(txn.randomize() with {txn.trans_type == axi4_lite_transaction::READ;});
            finish_item(txn);
            #10;
        end
    endtask

endclass

class axi4_lite_write_read_sequence extends uvm_sequence #(axi4_lite_transaction);
    
    `uvm_object_utils(axi4_lite_write_read_sequence)

    int num_transactions = 10;

    function new(string name = "axi4_lite_write_read_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_lite_transaction txn;
        repeat(num_transactions) begin
            txn = axi4_lite_transaction::type_id::create("txn");
            start_item(txn);
            assert(txn.randomize());
            finish_item(txn);
            #10;
        end
    endtask

endclass
