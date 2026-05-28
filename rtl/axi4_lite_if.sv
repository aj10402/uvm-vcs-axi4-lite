interface axi4_lite_if #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32
) (
    input bit ACLK,
    input bit ARESETN
);

    // Write Address Channel
    logic [ADDRESS-1:0] AWADDR;
    logic AWVALID;
    logic AWREADY;

    // Write Data Channel
    logic [DATA_WIDTH-1:0] WDATA;
    logic [3:0] WSTRB;
    logic WVALID;
    logic WREADY;

    // Write Response Channel
    logic [1:0] BRESP;
    logic BVALID;
    logic BREADY;

    // Read Address Channel
    logic [ADDRESS-1:0] ARADDR;
    logic ARVALID;
    logic ARREADY;

    // Read Data Channel
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0] RRESP;
    logic RVALID;
    logic RREADY;

    // Clocking blocks for testbench
    clocking cb_master @(posedge ACLK);
        output AWADDR, AWVALID, WDATA, WSTRB, WVALID, BREADY;
        output ARADDR, ARVALID, RREADY;
        input AWREADY, WREADY, BRESP, BVALID;
        input ARREADY, RDATA, RRESP, RVALID;
    endclocking

    // Modport for Master
    modport master (
        clocking cb_master
    );

    // Modport for Monitor
    modport monitor (
        input ACLK,
        input ARESETN,
        input AWADDR, AWVALID, AWREADY,
        input WDATA, WSTRB, WVALID, WREADY,
        input BRESP, BVALID, BREADY,
        input ARADDR, ARVALID, ARREADY,
        input RDATA, RRESP, RVALID, RREADY
    );

endinterface
