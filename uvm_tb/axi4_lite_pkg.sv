package axi4_lite_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Parameters
    parameter int ADDRESS_WIDTH = 32;
    parameter int DATA_WIDTH = 32;

    // Transaction class
    `include "axi4_lite_transaction.sv"

    // Sequences
    `include "axi4_lite_sequence.sv"

    // Drivers
    `include "axi4_lite_master_driver.sv"

    // Monitors
    `include "axi4_lite_monitor.sv"

    // Sequencers
    `include "axi4_lite_sequencer.sv"

    // Agents
    `include "axi4_lite_master_agent.sv"

    // Scoreboard
    `include "axi4_lite_scoreboard.sv"

    // Coverage
    `include "axi4_lite_coverage.sv"

    // Environment
    `include "axi4_lite_env.sv"

endpackage
