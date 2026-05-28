import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_lite_pkg::*;

class axi4_lite_base_test extends uvm_test;
    
    `uvm_component_utils(axi4_lite_base_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4_lite_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass

// Main test: Write known data, then read it back for verification
class axi4_lite_write_read_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_write_read_test)

    function new(string name = "axi4_lite_write_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_write_read_pairing_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Write-Read Pairing Test", UVM_MEDIUM)
        seq = axi4_lite_write_read_pairing_sequence::type_id::create("seq");
        seq.num_pairs = 5;
        seq.start(env.master_agent.sequencer);
        
        #200;
        phase.drop_objection(this);
    endtask

endclass

// Test partial writes with byte enable
class axi4_lite_partial_write_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_partial_write_test)

    function new(string name = "axi4_lite_partial_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_partial_write_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Partial Write Test (with WSTRB)", UVM_MEDIUM)
        seq = axi4_lite_partial_write_sequence::type_id::create("seq");
        seq.start(env.master_agent.sequencer);
        
        #200;
        phase.drop_objection(this);
    endtask

endclass

// Stress test with random transactions
class axi4_lite_stress_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_stress_test)

    function new(string name = "axi4_lite_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_stress_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Stress Test", UVM_MEDIUM)
        seq = axi4_lite_stress_sequence::type_id::create("seq");
        seq.num_transactions = 50;
        seq.start(env.master_agent.sequencer);
        
        #300;
        phase.drop_objection(this);
    endtask

endclass

// Legacy test: Write only
class axi4_lite_write_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_write_test)

    function new(string name = "axi4_lite_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_write_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Write-Only Test", UVM_MEDIUM)
        seq = axi4_lite_write_sequence::type_id::create("seq");
        seq.num_writes = 5;
        seq.start(env.master_agent.sequencer);
        
        #100;
        phase.drop_objection(this);
    endtask

endclass

// Legacy test: Read only
class axi4_lite_read_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_read_test)

    function new(string name = "axi4_lite_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_read_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Read-Only Test", UVM_MEDIUM)
        seq = axi4_lite_read_sequence::type_id::create("seq");
        seq.num_reads = 5;
        seq.start(env.master_agent.sequencer);
        
        #100;
        phase.drop_objection(this);
    endtask

endclass

// Back-to-back test - no delays between transactions
class axi4_lite_back_to_back_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_back_to_back_test)

    function new(string name = "axi4_lite_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_back_to_back_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Back-to-Back Test", UVM_MEDIUM)
        seq = axi4_lite_back_to_back_sequence::type_id::create("seq");
        seq.num_transactions = 20;
        seq.start(env.master_agent.sequencer);
        
        #200;
        phase.drop_objection(this);
    endtask

endclass

// Reset test - verify reset behavior
class axi4_lite_reset_test extends axi4_lite_base_test;
    
    `uvm_component_utils(axi4_lite_reset_test)

    function new(string name = "axi4_lite_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_reset_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Reset Test", UVM_MEDIUM)
        seq = axi4_lite_reset_sequence::type_id::create("seq");
        seq.start(env.master_agent.sequencer);
        
        #300;
        phase.drop_objection(this);
    endtask

endclass
