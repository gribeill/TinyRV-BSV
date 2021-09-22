package TbCPU;

//Library imports
import RegFile::*;
import Connectable::*;

//Project imports
import RV32I::*;
import Memories::*;
import TinyRV::*;


String input_file = "test_rv32i.hex";
typedef 10 TestAddrWidth; //Width of addresses in test memory.

(*synthesize*)
module mkTbCPU(Empty);

    RegFile#(Bit#(TestAddrWidth), Word) mem <- mkRegFileFullLoad(input_file);
    CPU_Ifc cpu <- mkCPU;

    mkConnection(cpu.mem_client, mem);

endmodule
endpackage



