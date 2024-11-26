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

    // RegFile#(Bit#(TestAddrWidth), Word) mem <- mkRegFileFullLoad(input_file);
    // BRAM_Configure cfg = defaultValue;
    // cfg.loadFormat = tagged None; 
    // cfg.allowWriteResponseBypass = False;
    // BRAM2Port#(Bit#(24), Word) bram <- mkBRAM2Server(cfg);

    Cache main_cache <- mkCache;
    TinyRV cpu <- mkTinyRV;

    // mkConnection(cpu.mem_client, mem);
    // mkConnection(cpu.mem_client, bram.portB);
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
            $display("Got ecall");
            cpu.restart();
            state <= CPU_RUN;
        end
        axi4_lite_write(write_test, ic, dat);
        ic <= ic+1;
    endrule

    rule ctrl_write_get;
      let r <- axi4_lite_write_response(write_test);
      printColorTimed(BLUE, $format("Ctrl received write resp %d", r));
    endrule

    rule runCPU (state == CPU_RUN);
        if (!cpu.running) $finish(0);
    endrule

    // rule 

    // Stmt bring_up_cpu = seq
    //     $display("CPU is running: %d", cpu.running());
    //     $display("Loading Memory From File: test_rv32i.bin");
    //     action
        
    //         for (i <= 0; i < 300; i <= i+1)
    //         begin
    //             Word read_word = mem.sub(i);
    //             $display( "Got value %h", read_word) ;
    //         end

    //     endaction
    //     // action
    //         // $display( "In action!");
    //         // String readFile = "test_rv32i.bin";
    //         // File lfh <- $fopen(readFile, "rb" ) ;
    //         // Bool done = False;
    //         // while ( !done )
    //         //  begin
    //         //     int i <- $fgetc( lfh );
    //         //     if (i == -1) done = True;
    //         //     Bit#(32) c = truncate( pack(i) ) ;
    //         //     $display( "Got value %h", c) ;
    //         //  end
    //         // // else // an error occurred.
    //         // //  begin
    //         // //     $display( "Could not get byte from %s", readFile ) ;
    //         // //  end
    //         // $fclose ( lfh ) ;
    //     // endaction
        
    //     cpu.restart();
    //     $display("CPU is running: %d", cpu.running());
    //     // cpu.stop();
    //     // for (i <= 0; i < 300; i <= i+1)
    //     //         action
    //     //         endaction
    //     // cpu.stop();
    //     // $display("CPU is running: %d", cpu.running());
    //     $finish(0);
    // endseq;

    //  // Define fsm behavior
    // Stmt s = seq
    //              for (i <= 0; i < 50; i <= i + 1)
    //                      sram.write (i, j, i+j);

    // mkAutoFSM( bring_up_cpu );

    // rule done (!cpu.running());
    //     $display("Done!");
    //     $finish(1);
    //     //File fout <- $fopen(output_file, "w");
    //     //$display("Start writing out memory...");
    //     //fh <= fout; 
    //     //out_state <= 1;
    // endrule 

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



