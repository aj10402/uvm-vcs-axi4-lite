class axi4_lite_master_agent extends uvm_agent;
    
    `uvm_component_utils(axi4_lite_master_agent)

    axi4_lite_sequencer sequencer;
    axi4_lite_master_driver driver;
    axi4_lite_monitor monitor;

    uvm_analysis_port #(axi4_lite_transaction) ap;

    function new(string name = "axi4_lite_master_agent", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sequencer = axi4_lite_sequencer::type_id::create("sequencer", this);
        driver = axi4_lite_master_driver::type_id::create("driver", this);
        monitor = axi4_lite_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction

endclass
