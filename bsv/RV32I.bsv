package RV32I;

typedef 32 XLEN;
typedef 32 NReg;
typedef 24 AddrWidth;

typedef Bit#(XLEN) Word;
typedef Int#(XLEN) SWord;

typedef TLog#(NReg) RegWidth;
typedef Bit#(RegWidth) RegIdx;

typedef Bit#(XLEN) Instr;
typedef Bit#(AddrWidth) MemAddr;

//pad to get to right width
Bit#(TSub#(XLEN, AddrWidth)) addr_pad = 0;

// INSTRUCTION DECODING...
//
function RegIdx fv_rd(Instr a);
    return a[11:7];
endfunction

function RegIdx fv_rs1(Instr a);
    return a[19:15];
endfunction

function RegIdx fv_rs2(Instr a);
    return a[24:20];
endfunction

function Word fv_Uimm(Instr a);
    return {a[31], a[30:12], 12'b00000000000 };
endfunction

function Word fv_Iimm(Instr a);
    return signExtend(a[30:20]);
endfunction

function Word fv_Simm(Instr a);
    return signExtend({a[31], a[30:25], a[11:7]});
endfunction

function Word fv_Bimm(Instr a);
    return signExtend({a[31], a[7], a[30:25], a[11:8], 1'b0});
endfunction

function Word fv_Jimm(Instr a);
    return signExtend({a[31], a[19:12], a[20], a[30:21], 1'b0});
endfunction

typedef enum {
    LOAD   = 5'b00000,
    ALUIMM = 5'b00100,
    AUIPC  = 5'b00101,
    STORE  = 5'b01000,
    ALUREG = 5'b01100,
    LUI    = 5'b01101,
    BRANCH = 5'b11000,
    JALR   = 5'b11001,
    JAL    = 5'b11011,
    SYSTEM = 5'b11100
} OpCode deriving (Bits, Eq);

function OpCode fv_opcode(Instr a);
    return unpack(a[6:2]);
endfunction

//Function 3 operands
typedef enum {
  PM  = 3'b000,
  XOR = 3'b100,
  OR  = 3'b110,
  AND = 3'b111,
  LT  = 3'b010,
  LTU = 3'b011,
  SL  = 3'b001,
  SR  = 3'b101
} ALUF3 deriving (Bits, Eq);

typedef enum {
  BEQ = 3'b000,
  BNE = 3'b001,
  BLT = 3'b100,
  BGE = 3'b101,
  BLTU = 3'b110,
  BGEU = 3'b111
} BranchF3 deriving (Bits, Eq);

typedef enum {
    B = 3'b000,
    H = 3'b001,
    W = 3'b010,
    BU = 3'b100,
    HU = 3'b101
} LSF3 deriving (Bits, Eq);

function Bit#(3) fv_funct3(Instr a);
    return a[14:12];
endfunction

function Bit#(7) fv_funct7(Instr a);
    return a[31:25];
endfunction

typedef struct {
    OpCode op;
    RegIdx rs1;
    RegIdx rs2;
    RegIdx rd;
    Bit#(3) funct3;
    Bit#(7) funct7;
    Word imm; 
} DInstr deriving (Bits, Eq);

function DInstr fv_decode(Instr a);

    let op = fv_opcode(a);
    Word imm = 32'b0; 

    case (op) matches
        ALUREG: imm = 32'b0;
        ALUIMM: imm = fv_Iimm(a);
        BRANCH: imm = fv_Bimm(a);
        JAL:    imm = fv_Jimm(a);
        JALR:   imm = fv_Iimm(a);
        LOAD:   imm = fv_Iimm(a);
        STORE:  imm = fv_Simm(a);
        LUI:    imm = fv_Uimm(a);
        AUIPC:  imm = fv_Uimm(a);
        SYSTEM: imm = fv_Iimm(a);
    endcase 

    return DInstr{ op:     op, 
                   rs1:    fv_rs1(a),
                   rs2:    fv_rs2(a),
                   rd:     fv_rd(a),
                   funct3: fv_funct3(a),
                   funct7: fv_funct7(a),
                   imm:    imm};
endfunction

endpackage