class axi4_lite_env extends uvm_env;
    
    `uvm_component_utils(axi4_lite_env)

    axi4_lite_master_agent master_agent;
    axi4_lite_scoreboard scoreboard;
    axi4_lite_coverage coverage;

    function new(string name = "axi4_lite_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        master_agent = axi4_lite_master_agent::type_id::create("master_agent", this);
        scoreboard = axi4_lite_scoreboard::type_id::create("scoreboard", this);
        coverage = axi4_lite_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Single source of truth: passive monitor from master_agent observes all transactions
        // Monitor sends both write and read transactions to scoreboard
        master_agent.ap.connect(scoreboard.monitor_imp);
        // Coverage also receives transactions from master_agent's monitor
        master_agent.ap.connect(coverage.analysis_export);
    endfunction

endclass
