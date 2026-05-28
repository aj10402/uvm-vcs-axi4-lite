class axi4_lite_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi4_lite_scoreboard)

    // Single analysis import from passive monitor - source of truth for all transactions
    uvm_analysis_imp #(axi4_lite_transaction, axi4_lite_scoreboard) monitor_imp;

    // Virtual interface used to observe runtime reset.
    virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif;

    // Reference memory model - matches DUT memory exactly
    logic [31:0] ref_memory [32];

    // Statistics
    int total_write_requests = 0;
    int total_write_responses = 0;
    int total_read_requests = 0;
    int total_read_responses = 0;
    int data_mismatches = 0;
    int response_errors = 0;

    function new(string name = "axi4_lite_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        monitor_imp = new("monitor_imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::get(this, "", "vif", vif)) begin
            `uvm_warning("NO_VIF", {"virtual interface may not be set for: ", get_full_name(), ". Runtime reset sync disabled."})
        end
        clear_ref_memory("build_phase initialization");
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        if (vif == null) begin
            return;
        end

        forever begin
            @(negedge vif.ARESETN);
            clear_ref_memory("runtime reset assertion observed");
            // Wait for reset deassertion before processing post-reset traffic.
            @(posedge vif.ARESETN);
        end
    endtask

    // Callback for monitor_imp analysis import
    function void write(axi4_lite_transaction txn);
        logic [31:0] expected_data;
        if (txn.trans_type == axi4_lite_transaction::WRITE) begin
            total_write_requests++;
            `uvm_info("SCOREBOARD",
                $sformatf("OBSERVED_WRITE[%0t]: addr=0x%h data=0x%h strb=0x%h",
                    $time, txn.awaddr, txn.wdata, txn.wstrb),
                UVM_MEDIUM)

            // Update reference memory with new write
            update_ref_memory(txn.awaddr[6:2], txn.wdata, txn.wstrb);

            // Check response
            if (txn.bresp != 2'b00) begin
                `uvm_error("SCOREBOARD",
                    $sformatf("WRITE_RESPONSE_ERROR[%0t]: addr=0x%h got resp=0x%h, expected 0x00 (OKAY)",
                        $time, txn.awaddr, txn.bresp))
                response_errors++;
            end else begin
                total_write_responses++;
                `uvm_info("SCOREBOARD",
                    $sformatf("WRITE_RESPONSE_OK[%0t]: addr=0x%h", $time, txn.awaddr),
                    UVM_HIGH)
            end
        end
        else if (txn.trans_type == axi4_lite_transaction::READ) begin
            total_read_requests++;
            `uvm_info("SCOREBOARD",
                $sformatf("OBSERVED_READ[%0t]: addr=0x%h", $time, txn.araddr),
                UVM_MEDIUM)

            // Get expected data from reference memory
            expected_data = ref_memory[txn.araddr[6:2]];

            // Verify data matches reference
            if (txn.rdata != expected_data) begin
                `uvm_error("SCOREBOARD",
                    $sformatf("READ_DATA_MISMATCH[%0t]: addr=0x%h expected=0x%h actual=0x%h",
                        $time, txn.araddr, expected_data, txn.rdata))
                data_mismatches++;
            end

            // Verify response
            if (txn.rresp != 2'b00) begin
                `uvm_error("SCOREBOARD",
                    $sformatf("READ_RESPONSE_ERROR[%0t]: addr=0x%h got resp=0x%h, expected 0x00 (OKAY)",
                        $time, txn.araddr, txn.rresp))
                response_errors++;
            end else begin
                // Success message
                total_read_responses++;
                `uvm_info("SCOREBOARD",
                    $sformatf("READ_OK[%0t]: addr=0x%h data=0x%h", $time, txn.araddr, txn.rdata),
                    UVM_HIGH)
            end
        end
    endfunction

    // Helper function to update reference memory respecting WSTRB byte enables
    function void update_ref_memory(logic [4:0] addr, logic [31:0] data, logic [3:0] strb);
        logic [31:0] old_value = ref_memory[addr];

        // Apply byte enables - only update bytes where strb bit is set
        for (int i = 0; i < 4; i++) begin
            if (strb[i]) begin
                ref_memory[addr][i*8 +: 8] = data[i*8 +: 8];
            end
        end

        `uvm_info("SCOREBOARD",
            $sformatf("MEM_UPDATE[%0t]: addr[0x%h] 0x%h -> 0x%h (strb=0x%h)",
                $time, addr, old_value, ref_memory[addr], strb),
            UVM_HIGH)
    endfunction

    function void clear_ref_memory(string reason);
        for (int i = 0; i < 32; i++) begin
            ref_memory[i] = 32'h0;
        end
        `uvm_info("SCOREBOARD", $sformatf("Reference memory cleared (%s)", reason), UVM_MEDIUM)
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCOREBOARD", "========== SCOREBOARD FINAL REPORT ==========", UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("Write Requests:  %0d", total_write_requests), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("Write Responses: %0d", total_write_responses), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("Read Requests:   %0d", total_read_requests), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("Read Responses:  %0d", total_read_responses), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", "", UVM_MEDIUM)
        `uvm_info("SCOREBOARD", "Error Summary:", UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("  Data Mismatches:    %0d", data_mismatches), UVM_MEDIUM)
        `uvm_info("SCOREBOARD", $sformatf("  Response Errors:    %0d", response_errors), UVM_MEDIUM)
        int total_errors = data_mismatches + response_errors;

        if (total_errors == 0 && (total_write_requests + total_read_requests) > 0) begin
            `uvm_info("SCOREBOARD", "", UVM_MEDIUM)
            `uvm_info("SCOREBOARD", "✓ ALL VERIFICATION CHECKS PASSED!", UVM_MEDIUM)
            `uvm_info("SCOREBOARD", "✓ Reference memory model matches DUT behavior", UVM_MEDIUM)
        end else begin
            `uvm_error("SCOREBOARD", "")
            `uvm_error("SCOREBOARD", "✗ VERIFICATION FAILED!")
            `uvm_error("SCOREBOARD", $sformatf("✗ Total errors: %0d", total_errors))
        end

        `uvm_info("SCOREBOARD", "==================================================", UVM_MEDIUM)
    endfunction

endclass
