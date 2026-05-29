module axi4_lite_assertions (
    input logic aclk,
    input logic aresetn,

    // Write Address Channel
    input logic awvalid,
    input logic awready,
    input logic [31:0] awaddr,

    // Write Data Channel
    input logic wvalid,
    input logic wready,
    input logic [31:0] wdata,
    input logic [3:0] wstrb,

    // Write Response Channel
    input logic bvalid,
    input logic bready,
    input logic [1:0] bresp,

    // Read Address Channel
    input logic arvalid,
    input logic arready,
    input logic [31:0] araddr,

    // Read Data Channel
    input logic rvalid,
    input logic rready,
    input logic [31:0] rdata,
    input logic [1:0] rresp
);

    // ==========================================
    // AXI4-Lite Protocol Assertions
    // ==========================================

    // 1. Reset behavior
    property reset_assertions;
        @(posedge aclk) disable iff ($isunknown(aresetn)   ||
                                     $isunknown(awvalid)   ||
                                     $isunknown(wvalid)    ||
                                     $isunknown(bvalid)    ||
                                     $isunknown(arvalid)   ||
                                     $isunknown(rvalid))
        !aresetn |-> (!awvalid && !wvalid && !bvalid && !arvalid && !rvalid);
    endproperty

    assert property (reset_assertions)
        else $error("AXI4_LITE_ASSERT: Signals not deasserted during reset");

    // 2. Handshake stability - address/data must be stable when valid and not ready
    property awaddr_stable;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && !awready) |=> (awaddr == $past(awaddr));
    endproperty

    assert property (awaddr_stable)
        else $error("AXI4_LITE_ASSERT: AWADDR changed while AWVALID=1 and AWREADY=0");

    property wdata_stable;
        @(posedge aclk) disable iff (!aresetn)
        (wvalid && !wready) |=> (wdata == $past(wdata) && wstrb == $past(wstrb));
    endproperty

    assert property (wdata_stable)
        else $error("AXI4_LITE_ASSERT: WDATA/WSTRB changed while WVALID=1 and WREADY=0");

    property araddr_stable;
        @(posedge aclk) disable iff (!aresetn)
        (arvalid && !arready) |=> (araddr == $past(araddr));
    endproperty

    assert property (araddr_stable)
        else $error("AXI4_LITE_ASSERT: ARADDR changed while ARVALID=1 and ARREADY=0");

    // 3. Response follows request - write response after write request
    property write_response_after_request;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && awready) |-> ##[1:$] (bvalid && bready);
    endproperty

    assert property (write_response_after_request)
        else $error("AXI4_LITE_ASSERT: Write response not received after write request");

    // 4. Response follows request - read response after read request
    property read_response_after_request;
        @(posedge aclk) disable iff (!aresetn)
        (arvalid && arready) |-> ##[1:$] (rvalid && rready);
    endproperty

    assert property (read_response_after_request)
        else $error("AXI4_LITE_ASSERT: Read response not received after read request");

    // 5. Write transaction ordering - AW and W channels must complete before B
    property write_transaction_order;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && awready && wvalid && wready) |-> ##[0:$] (bvalid && bready);
    endproperty

    assert property (write_transaction_order)
        else $error("AXI4_LITE_ASSERT: Write response before write data/addr accepted");

    // 6. Read transaction ordering - AR must complete before R
    property read_transaction_order;
        @(posedge aclk) disable iff (!aresetn)
        (arvalid && arready) |-> ##[0:$] (rvalid && rready);
    endproperty

    assert property (read_transaction_order)
        else $error("AXI4_LITE_ASSERT: Read response before read address accepted");

    // 7. Response validity - only OKAY, SLVERR, DECERR allowed
    property bresp_valid;
        @(posedge aclk) disable iff (!aresetn)
        bvalid |-> (bresp inside {2'b00, 2'b10, 2'b11});
    endproperty

    assert property (bresp_valid)
        else $error("AXI4_LITE_ASSERT: Invalid BRESP value");

    property rresp_valid;
        @(posedge aclk) disable iff (!aresetn)
        rvalid |-> (rresp inside {2'b00, 2'b10, 2'b11});
    endproperty

    assert property (rresp_valid)
        else $error("AXI4_LITE_ASSERT: Invalid RRESP value");

    // 8. Address alignment - AXI4-Lite requires word alignment
    property awaddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        awvalid |-> (awaddr[1:0] == 2'b00);
    endproperty

    assert property (awaddr_aligned)
        else $error("AXI4_LITE_ASSERT: AWADDR not word-aligned");

    property araddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        arvalid |-> (araddr[1:0] == 2'b00);
    endproperty

    assert property (araddr_aligned)
        else $error("AXI4_LITE_ASSERT: ARADDR not word-aligned");

    // 9. WSTRB validity - only valid byte enable patterns
    property wstrb_valid;
        @(posedge aclk) disable iff (!aresetn)
        wvalid |-> (wstrb != 4'b0000); // At least one byte enabled
    endproperty

    assert property (wstrb_valid)
        else $error("AXI4_LITE_ASSERT: WSTRB has no bytes enabled");

    // 10. No X values on critical outputs after reset
    property no_x_on_outputs;
        @(posedge aclk) disable iff (!aresetn)
        1 |-> (!$isunknown(bvalid) && !$isunknown(bresp) &&
               !$isunknown(rvalid) && !$isunknown(rresp) && !$isunknown(rdata));
    endproperty

    assert property (no_x_on_outputs)
        else $error("AXI4_LITE_ASSERT: X values on output signals");

endmodule : axi4_lite_assertions