
import uvm_pkg::*;

class fm_radio_uvm_test extends uvm_test;

    `uvm_component_utils(fm_radio_uvm_test)

    fm_radio_uvm_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fm_radio_uvm_env::type_id::create(.name("env"), .parent(this));
    endfunction: build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction: end_of_elaboration_phase

    virtual task run_phase(uvm_phase phase);
        fm_radio_uvm_sequence seq;

        // notify that run_phase has started
        // NOTE: simulation terminates once all objections are dropped
        phase.raise_objection(.obj(this));

        seq = fm_radio_uvm_sequence::type_id::create(.name("seq"), .contxt(get_full_name()));
        seq.start(env.agent.seqr);

        // notify that run_phase has completed
        phase.drop_objection(.obj(this));
    endtask: run_phase

endclass: fm_radio_uvm_test