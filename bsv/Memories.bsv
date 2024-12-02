package Memories;

import GetPut::*;
import ClientServer::*;
import RegFile::*;
import FIFO::*;
import Connectable::*;
import BRAM::*;
import RV32I::*;
import SpecialFIFOs::*;

import BlueLib :: *;
import BlueAXI :: *;

Bool debug = True; 

//A memory request.
typedef struct {
    Bool write; //true = write to memory, false = read from memory
    LSF3 mask;
    MemAddr addr;
    Word data;
} MemRequest deriving (Bits, Eq);

//A memory response.
typedef struct {
    Word data;
    Bool cache_miss;
} MemResponse deriving (Bits, Eq);

typedef Server#(MemRequest, MemResponse) MemServer;
typedef Client#(MemRequest, MemResponse) MemClient;

//word / halfword / byte masking for RV32
function Word mask_data(Word data, LSF3 mask);
    case (mask)
        W: return data;
        H: return signExtend(data[15:0]);
        B: return signExtend(data[7:0]);
        HU: return zeroExtend(data[15:0]);
        BU: return zeroExtend(data[7:0]);
    endcase
endfunction

//A connectable between a memory client and a register file for simulation.
//Address width of register file can be less than full address width of bus.
instance Connectable#(MemClient, RegFile#(Bit#(mem_w), Word))
    provisos (Add#(a__, mem_w, AddrWidth)); //what does a__ mean???
    module mkConnection#(MemClient client, RegFile#(Bit#(mem_w), Word) rf)(Empty);

        FIFO#(Word) read_results <- mkLFIFO;

        rule connect_requests;
            let request <- client.request.get();
            Bit#(mem_w) addr = truncate(request.addr >> 2);
            Word old_data = rf.sub(addr);
            if (request.write) begin
                let newdata = mask_data(request.data, request.mask);
                rf.upd(addr, newdata);
                if (debug) $display("[%t] MEM WRITE %x @ %x", $time, newdata, addr);
            end
            else begin 
                let newdata = mask_data(old_data, request.mask);
                read_results.enq(newdata);
                if (debug) $display("[%t] MEM READ %x @ %x", $time, newdata, addr);
            end
        endrule 

        rule connect_responses;
            let response = read_results.first; read_results.deq;
            client.response.put(MemResponse {cache_miss: False, data : response});
        endrule 
    endmodule
endinstance 

interface Cache;
    interface BRAMServer#(Bit#(24), Word) cpu_bram_port; // Direct connection to BRAM
    interface AXI4_Lite_Slave_Wr_Fab#(24, 32) axi4l_cache_write_s;
    interface MemServer mem_server;
endinterface

(* synthesize *)
module mkCache(Cache);
    
    // Store the mask in a register
    Reg#(LSF3) cached_mask <- mkRegU;

    // Create the BRAM
    BRAM_Configure cfg = defaultValue;
    cfg.loadFormat = tagged None; 
    cfg.allowWriteResponseBypass = False;
    BRAM2Port#(Bit#(24), Word) bram <- mkBRAM2Server(cfg);

    // Create the AXI interface
    AXI4_Lite_Slave_Wr#(24,32) axi4l_cache_write_s_inst <- mkAXI4_Lite_Slave_Wr_24_32;

    rule axi4l_cache_write_s_drain; 
      let payload <- axi4l_cache_write_s_inst.request.get;
      if(debug) printColorTimed(GREEN, $format("Cache portA writing %h to addr %h", payload.data, payload.addr));
      AXI4_Lite_Write_Rs_Pkg resp = AXI4_Lite_Write_Rs_Pkg {resp: OKAY};
      axi4l_cache_write_s_inst.response.put(resp);

      bram.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: payload.addr, datain: payload.data});
    endrule


    interface MemServer mem_server;
        interface Put request;
            method Action put (MemRequest request);
                let addr = request.addr >> 2;
                let masked_data = mask_data(request.data, request.mask);
                cached_mask <= request.mask;
                if (debug) printColorTimed(BLUE, $format("BRAM Get/Put READ %x @ %x", request.data, addr));
                bram.portB.request.put(BRAMRequest{write: request.write, responseOnWrite: False, address: addr, datain: masked_data});
            endmethod
        endinterface

        interface Get response;
            method ActionValue#(MemResponse) get ();
                let resp <- bram.portB.response.get;
                let mask = cached_mask;
                if (debug) printColorTimed(BLUE, $format("BRAM Get/Put READ yielded %x", mask_data(resp, mask)));
                return MemResponse {cache_miss: False, data : mask_data(resp, mask)};
            endmethod
        endinterface
    endinterface

    interface cpu_bram_port = bram.portB;
    interface axi4l_cache_write_s = axi4l_cache_write_s_inst.fab;
    
endmodule

(* synthesize *)
module mkAXI4_Lite_Slave_Wr_24_32 (AXI4_Lite_Slave_Wr#(24,32));
   let ifc <- mkAXI4_Lite_Slave_Wr(1);
   return ifc;
endmodule

(* synthesize *)
module mkAXI4_Lite_Master_Wr_24_32 (AXI4_Lite_Master_Wr#(24,32));
   let ifc <- mkAXI4_Lite_Master_Wr(1);
   return ifc;
endmodule

endpackage