package TbCPU;

import RegFile::*;
import RV32I::*;
import Memories::*;
import TinyRV::*;

String input_file = "test_rv32i.hex";
typedef 32 TestAddrWidth; 

(*synthesize*)
module mkTbCPU(Empty);

    RegFile#(Bit#(TestAddrWidth), Word) mem <- mkRegFileFullLoad(input_file);
    CPU_Ifc cpu <- mkCPU;

    mkConnection(cpu.mem_client, mem);

endmodule
endpackage



