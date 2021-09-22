package TbCPU;

//Library imports
import RegFile::*;
import Connectable::*;

//Project imports
import RV32I::*;
import Memories::*;
import TinyRV::*;


String input_file = "test_rv32i.txt";
String output_file = "test_r32i.out";
typedef 10 TestAddrWidth; //Width of addresses in test memory.

(*synthesize*)
module mkTbCPU(Empty);

    RegFile#(Bit#(TestAddrWidth), Word) mem <- mkRegFileFullLoad(input_file);
    CPU_Ifc cpu <- mkCPU;

    mkConnection(cpu.mem_client, mem);

    Reg#(int) out_state <- mkReg(0);
    Reg#(int) out_idx <- mkReg(0);

    let fh <- mkReg(InvalidFile);
    
    rule done (!cpu.running());
        $display("Done!");
        $finish(1);
        //File fout <- $fopen(output_file, "w");
        //$display("Start writing out memory...");
        //fh <= fout; 
        //out_state <= 1;
    endrule 

    //rule writeout (out_idx < fromInteger(2**valueOf(TestAddrWidth)));
    //    Bit#(TestAddrWidth) addr = truncate(pack(out_idx));
    //    $fwrite(fh, "%x %x", out_idx, mem.sub(addr));
    //    out_idx <= out_idx + 1;
    //endrule 

    //rule exit (out_idx == fromInteger(2**valueOf(TestAddrWidth)));
    //    $fclose(fh);
    //    $display("Finished writing out memory.");
    //    $finish(1);
    //endrule 

endmodule
endpackage



