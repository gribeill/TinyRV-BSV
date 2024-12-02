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
    WAIT,
    CPU_RUN,
    TEST_CACHE,
    DONE
} TbState deriving (Bits, Eq);

(*synthesize*)
module mkTbCPU(Empty);

    Cache main_cache <- mkCache;
    TinyRV cpu <- mkTinyRV;

    // mkConnection(cpu.mem_client, main_cache.cpu_bram_port);
    mkConnection(cpu.mem_client, main_cache.mem_server);

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

        printColorTimed(YELLOW, $format("Testbench sending %h from addr %h", dat, ic));
        axi4_lite_write(write_test, ic, dat);
        if (dat == 32'h00000073)
        begin
            state <= WAIT;
            ic <= 0;
        end else ic <= ic+1;
    endrule

    rule do_wait (state == WAIT);
        printColorTimed(YELLOW, $format("Waiting %h", ic));
        if (ic == 10)
        begin
            state <= CPU_RUN;
            cpu.restart();
            ic <= 0;
        end else ic <= ic+1;
    endrule

    rule ctrl_write_get;
      let r <- axi4_lite_write_response(write_test);
      // printColorTimed(YELLOW, $format("Ctrl received write resp %d", r));
    endrule

    rule runCPU (state == CPU_RUN);
        if (!cpu.running) state <= TEST_CACHE;
    endrule

    rule testCachePut (state == TEST_CACHE);
        main_cache.mem_server.request.put(MemRequest{write: False, mask: W, addr: ic, data: 0});
        printColorTimed(RED, $format("Testbench requested from addr %h", ic));
        if (ic==10) state <= DONE;
        ic <= ic+1;
    endrule

    rule testCacheGet (state == TEST_CACHE);
        let resp <- main_cache.mem_server.response.get;
        printColorTimed(RED, $format("Testbench got %h cache miss %d", resp.data, resp.cache_miss));
    endrule

    rule doneCPU (state == DONE);
        $finish(0);
    endrule


endmodule
endpackage



