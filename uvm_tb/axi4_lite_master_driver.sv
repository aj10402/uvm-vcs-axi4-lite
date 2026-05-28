class axi4_lite_master_driver extends uvm_driver #(axi4_lite_transaction);
    
    `uvm_component_utils(axi4_lite_master_driver)

    virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)) vif;
    axi4_lite_transaction txn;

    function new(string name = "axi4_lite_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction

    task run_phase(uvm_phase phase);
        // Initialize all control signals to idle before driving transactions
        vif.cb_master.AWVALID <= 1'b0;
        vif.cb_master.WVALID <= 1'b0;
        vif.cb_master.ARVALID <= 1'b0;
        vif.cb_master.BREADY <= 1'b0;
        vif.cb_master.RREADY <= 1'b0;
        @(vif.cb_master);
        forever begin
            seq_item_port.get_next_item(txn);
            drive_txn();
            seq_item_port.item_done();
        end
    endtask

    task drive_txn();
        @(vif.cb_master);
        
        if (txn.trans_type == axi4_lite_transaction::WRITE) begin
            vif.cb_master.AWADDR <= txn.awaddr;
            vif.cb_master.AWVALID <= 1'b1;
            vif.cb_master.WDATA <= txn.wdata;
            vif.cb_master.WSTRB <= txn.wstrb;
            vif.cb_master.WVALID <= 1'b1;
            vif.cb_master.BREADY <= 1'b1;
            
            `uvm_info("DRIVER", $sformatf("WRITE: AWADDR=0x%h, WDATA=0x%h", txn.awaddr, txn.wdata), UVM_MEDIUM)
            
            // Wait for write address ready
            while (!vif.cb_master.AWREADY) @(vif.cb_master);
            @(vif.cb_master);
            vif.cb_master.AWVALID <= 1'b0;
            
            // Wait for write data ready
            while (!vif.cb_master.WREADY) @(vif.cb_master);
            @(vif.cb_master);
            vif.cb_master.WVALID <= 1'b0;
            
            // Wait for write response
            while (!vif.cb_master.BVALID) @(vif.cb_master);
            @(vif.cb_master);
            vif.cb_master.BREADY <= 1'b0;
        end
        else if (txn.trans_type == axi4_lite_transaction::READ) begin
            vif.cb_master.ARADDR <= txn.araddr;
            vif.cb_master.ARVALID <= 1'b1;
            vif.cb_master.RREADY <= 1'b1;
            
            `uvm_info("DRIVER", $sformatf("READ: ARADDR=0x%h", txn.araddr), UVM_MEDIUM)
            
            // Wait for read address ready
            while (!vif.cb_master.ARREADY) @(vif.cb_master);
            @(vif.cb_master);
            vif.cb_master.ARVALID <= 1'b0;
            
            // Wait for read data valid
            while (!vif.cb_master.RVALID) @(vif.cb_master);
            txn.rdata = vif.cb_master.RDATA;
            @(vif.cb_master);
            vif.cb_master.RREADY <= 1'b0;
        end
        else begin
            // IDLE - deassert all signals
            vif.cb_master.AWVALID <= 1'b0;
            vif.cb_master.WVALID <= 1'b0;
            vif.cb_master.ARVALID <= 1'b0;
            vif.cb_master.BREADY <= 1'b0;
            vif.cb_master.RREADY <= 1'b0;
        end
    endtask

endclass
