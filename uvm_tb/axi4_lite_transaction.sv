class axi4_lite_transaction extends uvm_sequence_item;
    
    `uvm_object_utils(axi4_lite_transaction)

    // Transaction type - stimulus field
    typedef enum {WRITE, READ} trans_type_e;
    rand trans_type_e trans_type;

    // Write address channel - stimulus fields
    rand logic [ADDRESS_WIDTH-1:0] awaddr;
    // Write data channel - stimulus fields  
    rand logic [DATA_WIDTH-1:0] wdata;
    rand logic [3:0] wstrb;
    // Read address channel - stimulus fields
    rand logic [ADDRESS_WIDTH-1:0] araddr;

    // Protocol control signals - set by post_randomize, not randomized
    logic awvalid;
    logic wvalid;
    logic bready;
    logic arvalid;
    logic rready;

    // Response signals - observed by monitor, not stimulus
    logic awready;  // Observed
    logic wready;   // Observed
    logic [1:0] bresp;    // Observed
    logic bvalid;   // Observed
    logic arready;  // Observed
    logic [DATA_WIDTH-1:0] rdata;  // Observed
    logic [1:0] rresp;    // Observed
    logic rvalid;   // Observed

    // Constraints for stimulus fields
    constraint addr_alignment {
        // Word-aligned addresses (32-bit accesses)
        awaddr[1:0] == 2'b00;
        araddr[1:0] == 2'b00;
    }

    constraint addr_range {
        // Keep within 32 registers (0x00 to 0x7C)
        awaddr < 32'h80;
        araddr < 32'h80;
    }

    constraint wstrb_realistic {
        // Realistic byte enable patterns
        wstrb inside {
            4'b0001,  // Byte 0 only
            4'b0010,  // Byte 1 only
            4'b0100,  // Byte 2 only
            4'b1000,  // Byte 3 only
            4'b0011,  // Bytes 0-1 (half word)
            4'b1100,  // Bytes 2-3 (half word)
            4'b1111   // All bytes (full word)
        };
    }

    constraint data_stimulus {
        // Reasonable data patterns for testing
        wdata inside {
            32'h00000000,  // All zeros
            32'hFFFFFFFF,  // All ones
            32'hAAAAAAAA,  // Alternating pattern
            32'h55555555,  // Inverse alternating
            [32'h00000001 : 32'hFFFFFFFE]  // Any other value
        };
    }

    function new(string name = "axi4_lite_transaction");
        super.new(name);
    endfunction

    function void post_randomize();
        // Set protocol control signals based on transaction type
        if (trans_type == WRITE) begin
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;
            arvalid = 1'b0;
            rready = 1'b0;
        end
        else if (trans_type == READ) begin
            awvalid = 1'b0;
            wvalid = 1'b0;
            bready = 1'b0;
            arvalid = 1'b1;
            rready = 1'b1;
        end
    endfunction

    function string convert2string();
        string s;
        s = super.convert2string();
        s = {s, $sformatf("\n=== AXI4-Lite Transaction ===\n")};
        s = {s, $sformatf("Type: %s\n", trans_type.name())};

        if (trans_type == WRITE) begin
            s = {s, $sformatf("WRITE: AWADDR=0x%h, WDATA=0x%h, WSTRB=0x%h\n", awaddr, wdata, wstrb)};
            s = {s, $sformatf("WRITE: AWVALID=%b, WVALID=%b, BREADY=%b\n", awvalid, wvalid, bready)};
            s = {s, $sformatf("WRITE: AWREADY=%b, WREADY=%b, BRESP=0x%h, BVALID=%b\n", awready, wready, bresp, bvalid)};
        end
        else if (trans_type == READ) begin
            s = {s, $sformatf("READ: ARADDR=0x%h\n", araddr)};
            s = {s, $sformatf("READ: ARVALID=%b, RREADY=%b\n", arvalid, rready)};
            s = {s, $sformatf("READ: ARREADY=%b, RDATA=0x%h, RRESP=0x%h, RVALID=%b\n", arready, rdata, rresp, rvalid)};
        end

        return s;
    endfunction

endclass
