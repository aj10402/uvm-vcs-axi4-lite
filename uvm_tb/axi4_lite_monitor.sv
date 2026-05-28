class axi4_lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi4_lite_monitor)

    virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif;
    uvm_analysis_port #(axi4_lite_transaction) ap;

    // Typedefs for better organization
    typedef struct {
        logic [ADDRESS_WIDTH-1:0] addr;
        time timestamp;
    } addr_info;

    typedef struct {
        logic [DATA_WIDTH-1:0] data;
        logic [3:0] strb;
        time timestamp;
    } data_info;

    // Independent queues for each handshake
    addr_info write_addr_queue[$];
    data_info write_data_queue[$];
    addr_info read_addr_queue[$];

    // Statistics
    int write_addr_handshakes = 0;
    int write_data_handshakes = 0;
    int write_response_handshakes = 0;
    int read_addr_handshakes = 0;
    int read_data_handshakes = 0;
    int completed_writes = 0;
    int completed_reads = 0;

    function new(string name = "axi4_lite_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::get(this, "", "vif", vif))
            `uvm_warning("NO_VIF", {"virtual interface may not be set for: ", get_full_name()})
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info("MONITOR", "Starting AXI4-Lite protocol monitoring", UVM_MEDIUM)
        fork
            monitor_aw_channel();  // Write Address
            monitor_w_channel();   // Write Data
            monitor_b_channel();   // Write Response
            monitor_ar_channel();  // Read Address
            monitor_r_channel();   // Read Data
        join
    endtask

    // Monitor AW channel: AWVALID && AWREADY handshake
    task monitor_aw_channel();
        forever begin
            @(posedge vif.ACLK);
            if (vif.monitor.AWVALID && vif.monitor.AWREADY) begin
                addr_info aw_info;
                aw_info.addr = vif.monitor.AWADDR;
                aw_info.timestamp = $time;
                write_addr_queue.push_back(aw_info);
                write_addr_handshakes++;
                `uvm_info("MONITOR",
                    $sformatf("AW_HANDSHAKE[%0t]: addr=0x%h", $time, aw_info.addr),
                    UVM_HIGH)
            end
        end
    endtask

    // Monitor W channel: WVALID && WREADY handshake
    task monitor_w_channel();
        forever begin
            @(posedge vif.ACLK);
            if (vif.monitor.WVALID && vif.monitor.WREADY) begin
                data_info w_info;
                w_info.data = vif.monitor.WDATA;
                w_info.strb = vif.monitor.WSTRB;
                w_info.timestamp = $time;
                write_data_queue.push_back(w_info);
                write_data_handshakes++;
                `uvm_info("MONITOR",
                    $sformatf("W_HANDSHAKE[%0t]: data=0x%h strb=0x%h", $time, w_info.data, w_info.strb),
                    UVM_HIGH)
            end
        end
    endtask

    // Monitor B channel: BVALID && BREADY handshake - matches with AW+W
    task monitor_b_channel();
        forever begin
            @(posedge vif.ACLK);
            if (vif.monitor.BVALID && vif.monitor.BREADY) begin
                write_response_handshakes++;

                // Only emit complete write transaction if we have both address and data
                // This models the protocol requirement that AW, W, and B are logically tied
                if (write_addr_queue.size() > 0 && write_data_queue.size() > 0) begin
                    addr_info aw_info = write_addr_queue.pop_front();
                    data_info w_info = write_data_queue.pop_front();

                    axi4_lite_transaction write_txn = axi4_lite_transaction::type_id::create("write_txn");
                    write_txn.trans_type = axi4_lite_transaction::WRITE;
                    write_txn.awaddr = aw_info.addr;
                    write_txn.wdata = w_info.data;
                    write_txn.wstrb = w_info.strb;
                    write_txn.bresp = vif.monitor.BRESP;
                    write_txn.bvalid = 1'b1;

                    ap.write(write_txn);
                    completed_writes++;

                    `uvm_info("MONITOR",
                        $sformatf("WRITE_COMPLETE[%0t]: addr=0x%h data=0x%h strb=0x%h bresp=0x%h",
                            $time, write_txn.awaddr, write_txn.wdata, write_txn.wstrb, write_txn.bresp),
                        UVM_MEDIUM)
                end else begin
                    `uvm_error("MONITOR",
                        $sformatf("B_HANDSHAKE[%0t]: Write response without matching AW/W - AW_queue=%0d W_queue=%0d",
                            $time, write_addr_queue.size(), write_data_queue.size()))
                end
            end
        end
    endtask

    // Monitor AR channel: ARVALID && ARREADY handshake
    task monitor_ar_channel();
        forever begin
            @(posedge vif.ACLK);
            if (vif.monitor.ARVALID && vif.monitor.ARREADY) begin
                addr_info ar_info;
                ar_info.addr = vif.monitor.ARADDR;
                ar_info.timestamp = $time;
                read_addr_queue.push_back(ar_info);
                read_addr_handshakes++;
                `uvm_info("MONITOR",
                    $sformatf("AR_HANDSHAKE[%0t]: addr=0x%h", $time, ar_info.addr),
                    UVM_HIGH)
            end
        end
    endtask

    // Monitor R channel: RVALID && RREADY handshake - matches with AR
    task monitor_r_channel();
        forever begin
            @(posedge vif.ACLK);
            if (vif.monitor.RVALID && vif.monitor.RREADY) begin
                read_data_handshakes++;

                // Only emit complete read transaction if we have matching address
                if (read_addr_queue.size() > 0) begin
                    addr_info ar_info = read_addr_queue.pop_front();

                    axi4_lite_transaction read_txn = axi4_lite_transaction::type_id::create("read_txn");
                    read_txn.trans_type = axi4_lite_transaction::READ;
                    read_txn.araddr = ar_info.addr;
                    read_txn.rdata = vif.monitor.RDATA;
                    read_txn.rresp = vif.monitor.RRESP;

                    ap.write(read_txn);
                    completed_reads++;

                    `uvm_info("MONITOR",
                        $sformatf("READ_COMPLETE[%0t]: addr=0x%h data=0x%h rresp=0x%h (AR@%0t + R@%0t)",
                            $time, read_txn.araddr, read_txn.rdata, read_txn.rresp,
                            ar_info.timestamp, $time),
                        UVM_MEDIUM)
                end else begin
                    `uvm_error("MONITOR",
                        $sformatf("R_HANDSHAKE[%0t]: Read response without matching AR - AR_queue=%0d",
                            $time, read_addr_queue.size()))
                end
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("MONITOR", "========== MONITOR STATISTICS ==========", UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Write Address Handshakes:  %0d", write_addr_handshakes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Write Data Handshakes:     %0d", write_data_handshakes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Write Response Handshakes: %0d", write_response_handshakes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Read Address Handshakes:   %0d", read_addr_handshakes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Read Data Handshakes:      %0d", read_data_handshakes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Completed Writes:          %0d", completed_writes), UVM_MEDIUM)
        `uvm_info("MONITOR", $sformatf("Completed Reads:           %0d", completed_reads), UVM_MEDIUM)

        // Check for protocol issues
        if (write_addr_queue.size() > 0) begin
            `uvm_warning("MONITOR", $sformatf("Unmatched write addresses: %0d", write_addr_queue.size()))
        end
        if (write_data_queue.size() > 0) begin
            `uvm_warning("MONITOR", $sformatf("Unmatched write data: %0d", write_data_queue.size()))
        end
        if (read_addr_queue.size() > 0) begin
            `uvm_warning("MONITOR", $sformatf("Unmatched read addresses: %0d", read_addr_queue.size()))
        end

        `uvm_info("MONITOR", "==========================================", UVM_MEDIUM)
    endfunction

endclass
