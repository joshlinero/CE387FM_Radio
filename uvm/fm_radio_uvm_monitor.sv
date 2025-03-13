import uvm_pkg::*;


// Reads data from output fifo to scoreboard
class fm_radio_uvm_monitor_output extends uvm_monitor;
    `uvm_component_utils(fm_radio_uvm_monitor_output)

    uvm_analysis_port#(fm_radio_uvm_transaction) mon_ap_output;

    virtual fm_radio_uvm_if vif;
    int left_out_file, right_out_file;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual fm_radio_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_output = new(.name("mon_ap_output"), .parent(this));

        left_out_file = $fopen(FILE_LEFT_OUT_NAME, "wb");
        if ( !left_out_file ) begin
            `uvm_fatal("MON_OUT_BUILD", $sformatf("Failed to open output file %s...", FILE_LEFT_OUT_NAME));
        end
        right_out_file = $fopen(FILE_RIGHT_OUT_NAME, "wb");
        if ( !right_out_file ) begin
            `uvm_fatal("MON_OUT_BUILD", $sformatf("Failed to open output file %s...", FILE_RIGHT_OUT_NAME));
        end
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        fm_radio_uvm_transaction tx_out;
        int left_out, right_out;
        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_out = fm_radio_uvm_transaction::type_id::create(.name("tx_out"), .contxt(get_full_name()));

        vif.left_audio_out_rd_en = 1'b0;
        vif.right_audio_out_rd_en = 1'b0;

        forever begin
            @(negedge vif.clock)
            begin
                if (vif.left_audio_out_empty == 1'b0 && vif.right_audio_out_empty == 1'b0) begin
                    left_out = vif.left_audio_out_data;  
                    right_out = vif.right_audio_out_data;
                    $fwrite(left_out_file, "%x\n",left_out);
                    $fwrite(right_out_file, "%x\n",right_out);
                    tx_out.audio_left_output = vif.left_audio_out_data;
                    tx_out.audio_right_output = vif.right_audio_out_data;
                    mon_ap_output.write(tx_out);
                    vif.left_audio_out_rd_en = 1'b1;
                    vif.right_audio_out_rd_en = 1'b1;
                end else begin
                    vif.left_audio_out_rd_en = 1'b0;
                    vif.right_audio_out_rd_en = 1'b0;
                end
            end
        end
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("MON_OUT_FINAL", $sformatf("Closing file %s...", FILE_LEFT_OUT_NAME), UVM_LOW);
        $fclose(left_out_file);
        `uvm_info("MON_OUT_FINAL", $sformatf("Closing file %s...", FILE_RIGHT_OUT_NAME), UVM_LOW);
        $fclose(right_out_file);
    endfunction: final_phase

endclass: fm_radio_uvm_monitor_output


// Reads data from compare file to scoreboard
class fm_radio_uvm_monitor_compare extends uvm_monitor;
    `uvm_component_utils(fm_radio_uvm_monitor_compare)

    uvm_analysis_port#(fm_radio_uvm_transaction) mon_ap_compare;
    virtual fm_radio_uvm_if vif;
    int left_cmp_file, right_cmp_file, n_bytes;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual fm_radio_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_compare = new(.name("mon_ap_compare"), .parent(this));

        left_cmp_file = $fopen(FILE_LEFT_CMP_NAME, "rb");
        if ( !left_cmp_file ) begin
            `uvm_fatal("MON_CMP_BUILD", $sformatf("Failed to open file %s...", FILE_LEFT_CMP_NAME));
        end

        right_cmp_file = $fopen(FILE_RIGHT_CMP_NAME, "rb");
        if ( !right_cmp_file ) begin
            `uvm_fatal("MON_CMP_BUILD", $sformatf("Failed to open file %s...", FILE_RIGHT_CMP_NAME));
        end

    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        int i=0, m_bytes, n_bytes;
        fm_radio_uvm_transaction tx_cmp;
        logic [31:0] left_cmp_out, right_cmp_out;

        // extend the run_phase 20 clock cycles
        phase.phase_done.set_drain_time(this, (CLOCK_PERIOD*20));

        // notify that run_phase has started
        phase.raise_objection(.obj(this));

        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_cmp = fm_radio_uvm_transaction::type_id::create(.name("tx_cmp"), .contxt(get_full_name()));

        // syncronize file read with fifo data
        while (i < 1000/8) begin
            @(negedge vif.clock)
            begin
            if (vif.left_audio_out_empty == 1'b0 && vif.right_audio_out_empty == 1'b0) begin
                m_bytes = $fscanf(left_cmp_file, "%h", left_cmp_out);
                tx_cmp.audio_left_output = left_cmp_out;
                n_bytes = $fscanf(right_cmp_file, "%h", right_cmp_out);
                tx_cmp.audio_right_output = right_cmp_out;
                mon_ap_compare.write(tx_cmp);
                i++;
            end
        end
        end

        // notify that run_phase has completed
        phase.drop_objection(.obj(this));
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("MON_CMP_FINAL", $sformatf("Closing file %s...", FILE_LEFT_CMP_NAME), UVM_LOW);
        $fclose(left_cmp_file);
        `uvm_info("MON_CMP_FINAL", $sformatf("Closing file %s...", FILE_RIGHT_CMP_NAME), UVM_LOW);
        $fclose(right_cmp_file);
    endfunction: final_phase

endclass: fm_radio_uvm_monitor_compare