package Memories;

import GetPut::*;
import ClientServer::*;
import RegFile::*;
import FIFO::*;
import Connectable::*;

import RV32I::*;

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
            client.response.put(MemResponse {data : response});
        endrule 
    endmodule
endinstance 

endpackage