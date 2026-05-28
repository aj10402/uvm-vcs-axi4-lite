module axi4_lite_slave #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32
)
(
    //global signals
    input ACLK,
    input ARESETN,
    //Read Address channel input
    input [ADDRESS-1:0] S_ARADDR,
    input S_ARVALID,
    //Read data channel inputs
    input S_RREADY,
    //write data channel inputs
    input [ADDRESS-1:0] S_AWADDR,
    input S_AWVALID,
    //write data channel inputs
    input [DATA_WIDTH-1:0] S_WDATA,
    input [3:0] S_WSTRB,
    input S_WVALID,
    //write response channel inputs
    input S_BREADY,
    //read address channel outputs
    output logic S_ARREADY,
    //read data channel outputs
    output logic [DATA_WIDTH-1:0] S_RDATA,
    output logic [1:0] S_RRESP,
    output logic S_RVALID,
    //Write address channel outputs
    output logic S_AWREADY,
    output logic S_WREADY,
    //write response channel outputs
    output logic [1:0] S_BRESP,
    output logic S_BVALID
);

localparam no_of_registers = 32;
logic [DATA_WIDTH-1:0] register [no_of_registers-1:0];

// Write channel state
logic [ADDRESS-1:0] write_addr_latched;
logic [DATA_WIDTH-1:0] write_data_latched;
logic [3:0] write_strb_latched;
logic write_addr_accepted;
logic write_data_accepted;

// Read channel state
logic [ADDRESS-1:0] read_addr_latched;
logic read_addr_accepted;

// Response state
logic write_response_pending;
logic read_response_pending;

// Write address channel: always ready to accept address
assign S_AWREADY = ~write_addr_accepted;

// Write data channel: always ready to accept data
assign S_WREADY = ~write_data_accepted;

// Read address channel: always ready to accept address
assign S_ARREADY = ~read_addr_accepted;

// Write response channel
assign S_BVALID = write_response_pending;
assign S_BRESP = 2'b00; // OKAY response

// Read data channel
assign S_RVALID = read_response_pending;
assign S_RRESP = 2'b00; // OKAY response
assign S_RDATA = read_response_pending ? register[read_addr_latched[6:2]] : '0;

integer i;

// Memory update logic with WSTRB support
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        for (i = 0; i < no_of_registers; i++) begin
            register[i] <= '0;
        end
    end
    else begin
        // Update memory only when both write address and data have been accepted
        if (write_addr_accepted && write_data_accepted) begin
            // Apply byte enables (WSTRB)
            if (write_strb_latched[0]) register[write_addr_latched[6:2]][7:0]   <= write_data_latched[7:0];
            if (write_strb_latched[1]) register[write_addr_latched[6:2]][15:8]  <= write_data_latched[15:8];
            if (write_strb_latched[2]) register[write_addr_latched[6:2]][23:16] <= write_data_latched[23:16];
            if (write_strb_latched[3]) register[write_addr_latched[6:2]][31:24] <= write_data_latched[31:24];
        end
    end
end

// Write address channel logic
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        write_addr_accepted <= 1'b0;
        write_addr_latched <= '0;
    end
    else begin
        if (S_AWVALID && S_AWREADY) begin
            write_addr_accepted <= 1'b1;
            write_addr_latched <= S_AWADDR;
        end
        else if (write_addr_accepted && write_data_accepted) begin
            // Clear when write transaction completes
            write_addr_accepted <= 1'b0;
        end
    end
end

// Write data channel logic
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        write_data_accepted <= 1'b0;
        write_data_latched <= '0;
        write_strb_latched <= '0;
    end
    else begin
        if (S_WVALID && S_WREADY) begin
            write_data_accepted <= 1'b1;
            write_data_latched <= S_WDATA;
            write_strb_latched <= S_WSTRB;
        end
        else if (write_addr_accepted && write_data_accepted) begin
            // Clear when write transaction completes
            write_data_accepted <= 1'b0;
        end
    end
end

// Write response logic
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        write_response_pending <= 1'b0;
    end
    else begin
        if (write_addr_accepted && write_data_accepted && ~write_response_pending) begin
            // Generate response when both address and data are accepted
            write_response_pending <= 1'b1;
        end
        else if (S_BVALID && S_BREADY) begin
            // Clear response when accepted by master
            write_response_pending <= 1'b0;
        end
    end
end

// Read address channel logic
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        read_addr_accepted <= 1'b0;
        read_addr_latched <= '0;
    end
    else begin
        if (S_ARVALID && S_ARREADY) begin
            read_addr_accepted <= 1'b1;
            read_addr_latched <= S_ARADDR;
        end
        else if (read_response_pending && S_RREADY) begin
            // Clear when read transaction completes
            read_addr_accepted <= 1'b0;
        end
    end
end

// Read response logic
always_ff @(posedge ACLK) begin
    if (~ARESETN) begin
        read_response_pending <= 1'b0;
    end
    else begin
        if (read_addr_accepted && ~read_response_pending) begin
            // Generate response when address is accepted
            read_response_pending <= 1'b1;
        end
        else if (S_RVALID && S_RREADY) begin
            // Clear response when accepted by master
            read_response_pending <= 1'b0;
        end
    end
end

endmodule
