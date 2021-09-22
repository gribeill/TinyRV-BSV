package TinyRV;

// Library imports
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import Memories::*;

//Project imports
import RV32I::*;
import Registers::*;
import ALU::*;

//Reset address of CPU
MemAddr reset_addr = 0;

//CPU pipeline stages. 
typedef enum {
    FETCH    = 8'b00000001,
    DECODE   = 8'b00000010,
    EXEC     = 8'b00000100,
    WAIT     = 8'b00001000,
    MEM      = 8'b00010000,
    WAIT_MEM = 8'b00100000,
    WB       = 8'b01000000,
    HALT     = 8'b10000000
} State deriving (Bits, Eq);


interface CPU_Ifc;
    interface MemClient mem_client; 
    method Bool running;
    method Action restart();
endinterface

(*synthesize*)
module mkCPU(CPU_Ifc);

    Reg#(State)   state <- mkReg(FETCH);
    Reg#(MemAddr) pc    <- mkReg(reset_addr);

    //PC and memory address updates
    Reg#(MemAddr) pc_4 <- mkReg(reset_addr);
    Reg#(Word)    pc_imm <- mkReg(0);
    Reg#(MemAddr) maddr <- mkReg(reset_addr);

    //latched decoded instructions
    Reg#(DInstr) dinstr <- mkRegU; 

    GPR_Ifc gpr <- mkGPR;
    ALU_Ifc alu <- mkALU;

    //Input and output register values. 
    Reg#(Word) rv1 <- mkReg(0);
    Reg#(Word) rv2 <- mkReg(0);
    Reg#(Word) rvd <- mkReg(0);

    //Control signals
    Reg#(Bool) reg_wb <- mkReg(False); //Register will be written back.
    Reg#(Bool) pc_wb  <- mkReg(False); //PC will be updated with something other than PC <= PC+4
    Reg#(Bool) is_branch <- mkReg(False);
    Reg#(Bool) is_alu    <- mkReg(False);
    Reg#(Bool) is_jalr   <- mkReg(False);
    Reg#(Bool) is_load   <- mkReg(False);
    Reg#(Bool) is_store  <- mkReg(False);

    //Memory request/response FIFOs
    FIFO#(MemRequest)  to_mem <- mkFIFO;
    FIFO#(MemResponse) from_mem <- mkFIFO;

    rule fetch (state == FETCH);
        //ask for the next instruction
        let mem_req = MemRequest{ write: False, 
                          mask: W,
                          addr: pc,
                          data: 0};
        to_mem.enq(mem_req); 
        pc_4 <= pc + 4; 
        reg_wb <= False;
        pc_wb  <= False;
        is_branch <= False;
        is_alu <= False;
        is_jalr <= False;
        is_load <= False;
        is_store <= False; 
        state <= DECODE;
    endrule 

    rule decode (state == DECODE);
        //get the next instruction from memory, decode
        let instr = from_mem.first.data; 
        from_mem.deq;
        let di = fv_decode(instr);
        dinstr <= di; 

        //read from the register file 
        // (does this need an extra cycle, or ar these available immediately?? )
        rv1 <= gpr.read_rs1(di.rs1);
        rv2 <= gpr.read_rs2(di.rs2);

        pc_imm <= extend(pc) + di.imm; 

        state <= EXEC;
    endrule 

    rule exec (state == EXEC);

        maddr <= truncate(rv1 + dinstr.imm);

        case (dinstr.op)  
            BRANCH: begin 
                    ALUinput in = tagged BRexec unpack(dinstr.funct3);
                    alu.write(in, rv1, rv2);
                    is_branch <= True;
                    state <= WAIT;
                end
            ALUREG: begin
                    ALUinput in = tagged ALUexec{f3: unpack(dinstr.funct3), 
                                                 bit30: dinstr.funct7[5]};
                    alu.write(in, rv1, rv2);
                    reg_wb <= True;
                    is_alu <= True;
                    state <= WAIT;
                end
            ALUIMM: begin
                    ALUinput in = tagged ALUexec{f3: unpack(dinstr.funct3), 
                                                 bit30: dinstr.funct7[5]};
                    alu.write(in, rv1, dinstr.imm);
                    reg_wb <= True;
                    is_alu <= True; 
                    state <= WAIT; 
                end
            LOAD: begin
                is_load <= True;
                state <= MEM;
            end
            STORE: begin
                is_store <= True;
                state <= MEM;
                reg_wb <= True; 
            end
            LUI: begin
                    reg_wb <= True;
                    rvd <= dinstr.imm;
                    state <= WB;
                end
            AUIPC: begin
                    reg_wb <= True;
                    rvd <= pc_imm;
                    state <= WB;
            end
            JAL: begin
                reg_wb <= True; pc_wb <= True;
                rvd <= extend(pc_4);
                state <= WB; 
            end
            JALR: begin
                reg_wb <= True; pc_wb <= True; is_jalr <= True; 
                rvd <= extend(pc_4);
            end
            SYSTEM: begin
                state <= HALT;
            end
        endcase
    endrule 

    rule wait_alu (state == WAIT);
        let alu_result <- alu.read();
        if (is_alu) rvd <= alu_result;
        if (is_branch) begin
            if (alu_result == 1) pc_wb <= True;
            else pc_wb <= False;
        end
        state <= WB;
    endrule 

    rule mem (state == MEM);
        if (is_load) begin
            let mem_req = MemRequest{write: False,
                                    mask: unpack(dinstr.funct3),
                                    addr: maddr,
                                    data: 0};
            to_mem.enq(mem_req);
            state <= WAIT_MEM; 
        end else
        if (is_store) begin 
            let mem_req = MemRequest{write: True, 
                                     mask: unpack(dinstr.funct3),
                                     addr: maddr,
                                     data: rv2};
            to_mem.enq(mem_req);
            state <= WB;
        end
    endrule

    rule wait_mem (state == WAIT_MEM);
        rvd <= from_mem.first.data;
        from_mem.deq;
        state <= WB; 
    endrule

    rule writeback (state == WB);
        if (reg_wb) gpr.write_rd(dinstr.rd, rvd);

        if (pc_wb) begin
            if (is_jalr) pc <= maddr;
            else pc <= truncate(pc_imm);
        end else pc <= pc_4; 

        state <= FETCH;
    endrule 

    method Bool running();
        return !(state == HALT);
    endmethod 

    method Action restart() if (state == HALT);
        pc <= reset_addr;
        state <= FETCH;
    endmethod

    interface MemClient mem_client;
        interface Get request = toGet(to_mem);
        interface Put response = toPut(from_mem);
    endinterface

endmodule
endpackage





















