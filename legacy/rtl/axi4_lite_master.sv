module axi4_lite_master #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32
)
(
    //global signals
    input ACLK,
    input ARESETN,

    input START_READ, 
    input START_WRITE,

    input [ADDRESS-1:0] address,
    input [DATA_WIDTH-1:0] W_data,

    //Read Address Channel inputs
    input M_ARREADY,
    //Read data channel inputs
    input [DATA_WIDTH-1:0] M_RDATA,
    input [1:0] M_RRESP,
    input M_RVALID,
    //Write address channel inputs
    input M_AWREADY,
    //Write data channel inputs
    input M_WREADY,
    //Write response channel inputs
    input [1:0] M_BRESP,
    input M_BVALID,
    //Read address channel outputs
    output logic [ADDRESS-1:0] M_ARADDR,
    output logic M_ARVALID,
    //read data channel outputs
    output logic M_RREADY,
    //Write Address channel outputs
    output logic [ADDRESS-1:0] M_AWADDR,
    output logic M_AWVALID,
    //Write data channel outputs
    output logic [DATA_WIDTH-1:0] M_WDATA,
    output logic [3:0] M_WSTRB,
    output logic M_WVALID,
    //write response channel outputs
    output logic M_BREADY
);

logic read_start;
logic write_addr;
logic write_data;
logic write_start;

typedef enum logic [2:0] {IDLE, WRITE_CHANNEL, WRESP_CHANNEL, RADDR_CHANNEL, RDATA_CHANNEL} state_type;
state_type state, next_state;

//read address
assign M_ARADDR = (state == RADDR_CHANNEL) ? address : 32'h0;
assign M_ARVALID = (state == RADDR_CHANNEL) ? 1:0;

// read data
assign M_RREADY = (state == RDATA_CHANNEL ||state == RADDR_CHANNEL) ? 1:0;

// write address 
assign M_AWADDR = (state == WRITE_CHANNEL) ? address : 32'h0;
assign M_AWVALID = (state == WRITE_CHANNEL) ? 1:0;
assign write_addr = M_AWVALID && M_AWREADY;

//write data
assign M_WVALID = (state == WRITE_CHANNEL) ? 1:0;
assign M_WDATA = (state == WRITE_CHANNEL) ? W_data : 32'h0;
assign M_WSTRB = (state == WRITE_CHANNEL) ? 4'b1111:0;
assign write_data = M_WVALID && M_WREADY;

// write response
assign M_BREADY = ((state == WRITE_CHANNEL)||(state == WRESP_CHANNEL)) ? 1:0;

always_ff @ (posedge ACLK) begin
    if (~ARESETN) begin
        state <= IDLE;
        read_start <= 1'b0;
        write_start <= 1'b0;
    end else begin
        state<=next_state;
        read_start <= START_READ;
        write_start <= START_WRITE;
    end
end

always_comb begin
    case (state)
        IDLE: begin
            if (write_start) begin
                next_state=WRITE_CHANNEL;
            end
            else if (read_start) begin
                next_state = RADDR_CHANNEL;
            end
            else begin
                next_state=IDLE;
            end
        end
        RADDR_CHANNEL:if (M_ARVALID && M_ARREADY) next_state = RDATA_CHANNEL;
        RDATA_CHANNEL: if (M_RVALID && M_RREADY) next_state = IDLE;
        WRITE_CHANNEL: if (write_addr && write_data) next_state= WRESP_CHANNEL;
        WRESP_CHANNEL: if (M_BVALID && M_BREADY) next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

endmodule
