import uvm_pkg::*;


class fm_radio_uvm_agent extends uvm_agent;

    `uvm_component_utils(fm_radio_uvm_agent)

    uvm_analysis_port#(fm_radio_uvm_transaction) agent_ap_output;
    uvm_analysis_port#(fm_radio_uvm_transaction) agent_ap_compare;

    fm_radio_uvm_sequencer        seqr;
    fm_radio_uvm_driver            drvr;
    fm_radio_uvm_monitor_output    mon_out;
    fm_radio_uvm_monitor_compare    mon_cmp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_ap_output  = new(.name("agent_ap_output"), .parent(this));
        agent_ap_compare = new(.name("agent_ap_compare"),  .parent(this));

        seqr    = fm_radio_uvm_sequencer::type_id::create(.name("seqr"), .parent(this));
        drvr    = fm_radio_uvm_driver::type_id::create(.name("drvr"), .parent(this));
        mon_out    = fm_radio_uvm_monitor_output::type_id::create(.name("mon_out"), .parent(this));
        mon_cmp    = fm_radio_uvm_monitor_compare::type_id::create(.name("mon_cmp"), .parent(this));
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);        
        drvr.seq_item_port.connect(seqr.seq_item_export);
        mon_out.mon_ap_output.connect(agent_ap_output);
        mon_cmp.mon_ap_compare.connect(agent_ap_compare);
    endfunction: connect_phase

endclass: fm_radio_uvm_agent