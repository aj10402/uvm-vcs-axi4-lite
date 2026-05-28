`ifndef AXI4_LITE_COVERAGE_SV
`define AXI4_LITE_COVERAGE_SV

class axi4_lite_coverage extends uvm_subscriber #(axi4_lite_transaction);

    `uvm_component_utils(axi4_lite_coverage)

    // Current observed transaction used by covergroup sampling.
    axi4_lite_transaction tr;

    // Coverage groups
    covergroup axi4_lite_cg;

        // Address coverage - separate for write and read
        awaddr_cp: coverpoint tr.awaddr iff (tr.trans_type == axi4_lite_transaction::WRITE) {
            bins addr_bins[] = {[32'h00:32'h7C]} with (item % 4 == 0);
            bins addr_edge_low = {32'h00};
            bins addr_edge_high = {32'h7C};
        }

        araddr_cp: coverpoint tr.araddr iff (tr.trans_type == axi4_lite_transaction::READ) {
            bins addr_bins[] = {[32'h00:32'h7C]} with (item % 4 == 0);
            bins addr_edge_low = {32'h00};
            bins addr_edge_high = {32'h7C};
        }

        // Transaction type coverage
        trans_type_cp: coverpoint tr.trans_type {
            bins read_trans = {axi4_lite_transaction::READ};
            bins write_trans = {axi4_lite_transaction::WRITE};
        }

        // Write strobe (WSTRB) coverage for write transactions
        wstrb_cp: coverpoint tr.wstrb iff (tr.trans_type == axi4_lite_transaction::WRITE) {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins half_word_low = {4'b0011};
            bins half_word_high = {4'b1100};
            bins full_word = {4'b1111};
            bins other_patterns = default;
        }

        // Data value coverage for writes
        wdata_cp: coverpoint tr.wdata iff (tr.trans_type == axi4_lite_transaction::WRITE) {
            bins zero = {32'h00000000};
            bins all_ones = {32'hFFFFFFFF};
            bins alternating = {32'hAAAAAAAA, 32'h55555555};
            bins low_values = {[32'h00000000:32'h0000FFFF]};
            bins high_values = {[32'hFFFF0000:32'hFFFFFFFF]};
            bins mid_values = default;
        }

        // Response coverage - separate for write and read
        bresp_cp: coverpoint tr.bresp iff (tr.trans_type == axi4_lite_transaction::WRITE) {
            bins okay_resp = {2'b00};
            bins slv_err = {2'b10};
            bins dec_err = {2'b11};
        }

        rresp_cp: coverpoint tr.rresp iff (tr.trans_type == axi4_lite_transaction::READ) {
            bins okay_resp = {2'b00};
            bins slv_err = {2'b10};
            bins dec_err = {2'b11};
        }

        // Cross coverage: transaction type vs response
        trans_x_bresp: cross trans_type_cp, bresp_cp;
        trans_x_rresp: cross trans_type_cp, rresp_cp;

    endgroup

    // Constructor
    function new(string name = "axi4_lite_coverage", uvm_component parent = null);
        super.new(name, parent);
        axi4_lite_cg = new();
    endfunction

    // Write method - called by monitor when transaction observed
    virtual function void write(axi4_lite_transaction t);
        tr = t;
        axi4_lite_cg.sample();
    endfunction

    // Report phase - print coverage results
    virtual function void report_phase(uvm_phase phase);
        real overall_cov;
        real inst_cov;
        overall_cov = axi4_lite_cg.get_coverage();
        inst_cov = axi4_lite_cg.get_inst_coverage();

        `uvm_info(get_type_name(),
            $sformatf("Functional Coverage: overall=%0.2f%% instance=%0.2f%%", overall_cov, inst_cov),
            UVM_LOW)
    endfunction

endclass : axi4_lite_coverage

`endif