import uvm_pkg::*;

class fm_radio_uvm_configuration extends uvm_object;
    `uvm_object_utils(fm_radio_uvm_configuration)

    function new(string name = "");
        super.new(name);
    endfunction: new
endclass: fm_radio_uvm_configuration