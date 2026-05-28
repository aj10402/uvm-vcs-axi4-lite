module axi4_lite_tb_top;

    import uvm_pkg::*;
    import axi4_lite_pkg::*;
    `include "uvm_macros.svh"

    logic ACLK;
    logic ARESETN;

    // Instantiate the interface
    axi4_lite_if #(
        .ADDRESS(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi4_if (
        .ACLK(ACLK),
        .ARESETN(ARESETN)
    );

    // Instantiate DUT - Slave (Primary DUT for testing)
    axi4_lite_slave #(
        .ADDRESS(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_slave (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .S_ARADDR(axi4_if.ARADDR),
        .S_ARVALID(axi4_if.ARVALID),
        .S_RREADY(axi4_if.RREADY),
        .S_AWADDR(axi4_if.AWADDR),
        .S_AWVALID(axi4_if.AWVALID),
        .S_WDATA(axi4_if.WDATA),
        .S_WSTRB(axi4_if.WSTRB),
        .S_WVALID(axi4_if.WVALID),
        .S_BREADY(axi4_if.BREADY),
        .S_ARREADY(axi4_if.ARREADY),
        .S_RDATA(axi4_if.RDATA),
        .S_RRESP(axi4_if.RRESP),
        .S_RVALID(axi4_if.RVALID),
        .S_AWREADY(axi4_if.AWREADY),
        .S_WREADY(axi4_if.WREADY),
        .S_BRESP(axi4_if.BRESP),
        .S_BVALID(axi4_if.BVALID)
    );

    // Instantiate Assertions Module
    axi4_lite_assertions u_assertions (
        .aclk(ACLK),
        .aresetn(ARESETN),
        .awvalid(axi4_if.AWVALID),
        .awready(axi4_if.AWREADY),
        .awaddr(axi4_if.AWADDR),
        .wvalid(axi4_if.WVALID),
        .wready(axi4_if.WREADY),
        .wdata(axi4_if.WDATA),
        .wstrb(axi4_if.WSTRB),
        .bvalid(axi4_if.BVALID),
        .bready(axi4_if.BREADY),
        .bresp(axi4_if.BRESP),
        .arvalid(axi4_if.ARVALID),
        .arready(axi4_if.ARREADY),
        .araddr(axi4_if.ARADDR),
        .rvalid(axi4_if.RVALID),
        .rready(axi4_if.RREADY),
        .rdata(axi4_if.RDATA),
        .rresp(axi4_if.RRESP)
    );

    // Clock Generation
    initial begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end

    // Reset Generation and Control
    // Initial reset at time 0
    initial begin
        ARESETN = 1'b0;
        #20 ARESETN = 1'b1;
    end

    // Task to trigger reset (can be called from tests)
    task trigger_reset(int duration_ns);
        `uvm_info("TESTBENCH", $sformatf("Triggering reset for %0d ns", duration_ns), UVM_MEDIUM)
        ARESETN = 1'b0;
        #(duration_ns);
        ARESETN = 1'b1;
        `uvm_info("TESTBENCH", "Reset release", UVM_MEDIUM)
    endtask

    // UVM event-based reset control — avoids fragile $root hierarchical paths
    initial begin
        uvm_event reset_req_ev, reset_done_ev;
        int reset_dur_ns;
        reset_req_ev  = uvm_event_pool::get_global_pool().get("reset_trigger");
        reset_done_ev = uvm_event_pool::get_global_pool().get("reset_done");
        forever begin
            reset_req_ev.wait_trigger();
            if (!uvm_config_db #(int)::get(null, "", "reset_duration_ns", reset_dur_ns))
                reset_dur_ns = 100;
            reset_req_ev.reset();
            ARESETN = 1'b0;
            #(reset_dur_ns);
            ARESETN = 1'b1;
            reset_done_ev.trigger();
            reset_done_ev.reset();
        end
    end

    // UVM Configuration and Run
    initial begin
        // Pass the virtual interface to the UVM test
        uvm_config_db #(virtual axi4_lite_if #(.ADDRESS(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)))::set(null, "*", "vif", axi4_if);

        // Run the UVM test
        run_test();
    end

    // Dumping for simulation
    initial begin
        `ifdef VCD_DUMP
            $dumpfile("sim.vcd");
            $dumpvars(0, axi4_lite_tb_top);
        `endif
    end

endmodule
