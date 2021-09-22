package ALU;

import FIFO::*;
import FIFOF::*;
import RV32I::*;

typedef struct {
    Word sum;
    Word minus;
    bit  lt;
    bit  ltu;
    bit  eq;
} ALUops deriving (Bits);

typedef union tagged {
    struct {
        ALUF3 f3;
        bit   bit30;
    } ALUexec;
    BranchF3 BRexec;
} ALUinput deriving (Bits, Eq);

function ALUops do_alu_operations(Word input1, Word input2);
    Bit#(33) minus = {1'b1, ~input2} + {1'b0, input1} + 33'b1;
    return ALUops{ sum: input1 + input2, 
                    minus: minus[31:0],
                    lt: ((input1[31] ^ input2[31]) == 1) ? input1[31] : minus[32],
                    ltu: minus[32],
                    eq: (minus[31:0] == 0) ? 1 : 0}; 
endfunction

typedef enum {
    SLL,
    SRA,
    SRL
} ShiftType deriving (Bits, Eq);

interface ALU_Ifc;
    method Action write(ALUinput in, Word v1, Word v2);
    method ActionValue#(Word) read();
endinterface

//(*synthesize*)
module mkALU(ALU_Ifc);

    FIFO#(Word) fifo_out    <- mkLFIFO;

    Reg#(Word)     shift_r    <- mkReg(0);
    Reg#(Bit#(5))  shift_by_r <- mkReg(0);
    Reg#(ShiftType) shift_type <- mkRegU;
    
    rule do_shift (shift_by_r > 0);

        Word nextval = 0;
        case (shift_type) matches
                SLL : nextval = shift_r << 1;
                SRA : nextval = {shift_r[31], shift_r[31:1]};
                SRL : nextval = {1'b0, shift_r[31:1]};
        endcase

        if ((shift_by_r - 1) == 0) begin
            fifo_out.enq(nextval);
            shift_by_r <= 0;
        end
        else begin
            shift_by_r <= shift_by_r - 1;
            if ((shift_by_r-1) == 0) fifo_out.enq(nextval);
            else shift_r <= nextval;
        end
            
    endrule

    method Action write(ALUinput in, Word v1, Word v2) if (shift_by_r == 0);
        Word input1 = v1;
        Word input2 = v2; 
        Word out = 0;

        let ops = do_alu_operations(input1, input2); 

        Bool is_shift = False;

        if (in matches tagged ALUexec {f3: .f3, bit30: .bit30}) begin

            case (f3) matches
                PM  : begin 
                            if (bit30 == 0) 
                                out = ops.sum; 
                            else 
                                out = ops.minus;
                         end
                XOR : out = input1 ^ input2;
                OR  : out = input1 | input2;
                AND : out = input1 & input2; 
                LT  : out = {31'b0, ops.lt};
                LTU : out = {31'b0, ops.ltu};
                SL  : begin 
                            is_shift = True;
                            shift_type <= SLL;
                         end
                SR  : begin 
                            is_shift = True;
                            shift_type <= (bit30 == 1) ? SRA : SRL;
                         end
            endcase
        end else if (in matches tagged BRexec .f3) begin 

            case (f3) matches

                BEQ: out = extend(ops.eq);
                BNE: out = extend(~ops.eq);
                BLT: out = extend(ops.lt);
                BGE: out = extend(~ops.lt);
                BLTU: out = extend(ops.ltu);
                BGEU: out = extend(~ops.ltu);
            endcase
        end

        if (is_shift) begin 
            if (input2[4:0] == 0) begin
                shift_by_r <= 0;
                fifo_out.enq(input1);
            end else begin
                shift_r <= input1;
                shift_by_r <= input2[4:0];
            end
        end else 
            fifo_out.enq(out);
    endmethod

    method ActionValue#(Word) read();
        let out = fifo_out.first;
        fifo_out.deq;
        return out;
    endmethod

endmodule

endpackage