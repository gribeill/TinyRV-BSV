package TbCPU;

//Library imports
import RegFile::*;
import Connectable::*;
import BRAM::*;
import StmtFSM::*;

// Third Party Libraries
import BlueAXI::*;
import BlueLib::*;

//Project imports
import RV32I::*;
import Memories::*;
import TinyRV::*;


String input_file = "test_rv32i.txt";
String output_file = "test_r32i.out";
typedef 10 TestAddrWidth; //Width of addresses in test memory.

typedef enum {
    BRAM_INIT,
    CPU_RUN,
    DONE
} TbState deriving (Bits, Eq);

(*synthesize*)
module mkTbCPU(Empty);

    Cache main_cache <- mkCache;
    TinyRV cpu <- mkTinyRV;

    mkConnection(cpu.mem_client, main_cache.cpu_bram_port);

    // AXI4L Interface to write the Cache
    AXI4_Lite_Master_Wr#(24,32) write_test <- mkAXI4_Lite_Master_Wr_24_32;
    mkConnection (write_test.fab, main_cache.axi4l_cache_write_s);

    Reg#(int) out_state <- mkReg(0);
    Reg#(int) out_idx <- mkReg(0);

    RegFile#(Bit#(24), Word) mem <- mkRegFileFullLoad(input_file);

    Reg#(Word) data <- mkReg(0);
    Reg#(TbState) state <- mkReg(BRAM_INIT);
    Reg#(Bit#(24)) ic <- mkReg(0);

    rule initBRAM (state == BRAM_INIT);
        Word dat = mem.sub(ic);

        printColorTimed(YELLOW, $format("Sending %h from addr %h testbench", dat, ic));
        if (dat == 32'h00000073)
        begin
            // $display("Got ecall");
            cpu.restart();
            state <= CPU_RUN;
        end
        axi4_lite_write(write_test, ic, dat);
        ic <= ic+1;
    endrule

    rule ctrl_write_get;
      let r <- axi4_lite_write_response(write_test);
      // printColorTimed(YELLOW, $format("Ctrl received write resp %d", r));
    endrule

    rule runCPU (state == CPU_RUN);
        if (!cpu.running) $finish(0);
    endrule


endmodule
endpackage



