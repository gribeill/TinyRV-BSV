package Registers; 

import RegFile::*;
import RV32I::*;

//Register file 
interface GPR_Ifc;
    (*always_ready*)
    method Word read_rs1(RegIdx rs1);
    (*always_ready*)
    method Word read_rs2(RegIdx rs2);
    (*always_ready*)
    method Action write_rd(RegIdx rd, Word data);
endinterface

//(*synthesize*)
module mkGPR(GPR_Ifc);

    RegFile#(RegIdx, Word) rf <- mkRegFileFull;

    method Word read_rs1(RegIdx rs1);
        return ((rs1 == 0) ? 0 : rf.sub(rs1));
    endmethod

    method Word read_rs2(RegIdx rs2);
        return ((rs2 == 0) ? 0 : rf.sub(rs2));
    endmethod 

    method Action write_rd(RegIdx rd, Word data);
        if (rd != 0)
            rf.upd(rd, data);
    endmethod
endmodule 

endpackage