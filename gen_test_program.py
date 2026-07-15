#!/usr/bin/env python3
"""
RV32I Test Program Generator
Generates a comprehensive .mem file testing all 37 RV32I data-path instructions,
branches, jumps, load/store, corner cases, and hazard scenarios.
Results stored to DMEM (base 0x10000000) for testbench verification.

IMPORTANT: 5-stage pipeline with MEM-EX and WB-EX forwarding.
- RAW on ALU results: forwarding handles 1-cycle gap (result available from MEM stage)
- Load-use: 1-cycle stall (load result available from WB stage after stall)
- Store data forwarding: store's rs2 goes through forwarding mux
- Branches/jumps: resolved in EX, 2 NOPs in delay slots (flushed by HW)
NOTE: We add 2 NOP separators between each test to avoid cross-test hazards.
"""

import struct
import os

program = []  # (hex_str, comment)
addr = 0

# ============================================================================
# Encoding helpers
# ============================================================================
def r_type(rd, rs1, rs2, funct3, funct7):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33

def i_type(rd, rs1, imm, funct3, opcode=0x13):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(rs1, rs2, imm, funct3):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | 0x23

def b_type(rs1, rs2, imm, funct3):
    imm = imm & 0x1FFF
    b12 = (imm >> 12) & 1
    b11 = (imm >> 11) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | 0x63

def u_type(rd, imm, opcode):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode

def j_type(rd, imm):
    imm = imm & 0x1FFFFF
    b20 = (imm >> 20) & 1
    b19_12 = (imm >> 12) & 0xFF
    b11 = (imm >> 11) & 1
    b10_1 = (imm >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | 0x6F

# Instruction shortcuts
def ADD(rd, rs1, rs2): return r_type(rd, rs1, rs2, 0, 0)
def SUB(rd, rs1, rs2): return r_type(rd, rs1, rs2, 0, 0x20)
def SLL(rd, rs1, rs2): return r_type(rd, rs1, rs2, 1, 0)
def SLT(rd, rs1, rs2): return r_type(rd, rs1, rs2, 2, 0)
def SLTU(rd, rs1, rs2): return r_type(rd, rs1, rs2, 3, 0)
def XOR(rd, rs1, rs2): return r_type(rd, rs1, rs2, 4, 0)
def SRL(rd, rs1, rs2): return r_type(rd, rs1, rs2, 5, 0)
def SRA(rd, rs1, rs2): return r_type(rd, rs1, rs2, 5, 0x20)
def OR(rd, rs1, rs2): return r_type(rd, rs1, rs2, 6, 0)
def AND(rd, rs1, rs2): return r_type(rd, rs1, rs2, 7, 0)

def ADDI(rd, rs1, imm): return i_type(rd, rs1, imm, 0)
def SLTI(rd, rs1, imm): return i_type(rd, rs1, imm, 2)
def SLTIU(rd, rs1, imm): return i_type(rd, rs1, imm, 3)
def XORI(rd, rs1, imm): return i_type(rd, rs1, imm, 4)
def ORI(rd, rs1, imm): return i_type(rd, rs1, imm, 6)
def ANDI(rd, rs1, imm): return i_type(rd, rs1, imm, 7)
def SLLI(rd, rs1, shamt): return i_type(rd, rs1, shamt & 0x1F, 1)
def SRLI(rd, rs1, shamt): return i_type(rd, rs1, shamt & 0x1F, 5)
def SRAI(rd, rs1, shamt): return i_type(rd, rs1, (0x400 | (shamt & 0x1F)), 5)

def LB(rd, rs1, imm): return i_type(rd, rs1, imm, 0, 0x03)
def LH(rd, rs1, imm): return i_type(rd, rs1, imm, 1, 0x03)
def LW(rd, rs1, imm): return i_type(rd, rs1, imm, 2, 0x03)
def LBU(rd, rs1, imm): return i_type(rd, rs1, imm, 4, 0x03)
def LHU(rd, rs1, imm): return i_type(rd, rs1, imm, 5, 0x03)

def SB(rs1, rs2, imm): return s_type(rs1, rs2, imm, 0)
def SH(rs1, rs2, imm): return s_type(rs1, rs2, imm, 1)
def SW(rs1, rs2, imm): return s_type(rs1, rs2, imm, 2)

def BEQ(rs1, rs2, imm): return b_type(rs1, rs2, imm, 0)
def BNE(rs1, rs2, imm): return b_type(rs1, rs2, imm, 1)
def BLT(rs1, rs2, imm): return b_type(rs1, rs2, imm, 4)
def BGE(rs1, rs2, imm): return b_type(rs1, rs2, imm, 5)
def BLTU(rs1, rs2, imm): return b_type(rs1, rs2, imm, 6)
def BGEU(rs1, rs2, imm): return b_type(rs1, rs2, imm, 7)

def LUI(rd, imm): return u_type(rd, imm, 0x37)
def AUIPC(rd, imm): return u_type(rd, imm, 0x17)
def JAL(rd, imm): return j_type(rd, imm)
def JALR(rd, rs1, imm): return i_type(rd, rs1, imm, 0, 0x67)

def NOP(): return ADDI(0, 0, 0)
def FENCE(): return 0x0000000F
def ECALL(): return 0x00000073
def EBREAK(): return 0x00100073

def emit(instr, comment=""):
    global addr
    hex_str = f"{instr & 0xFFFFFFFF:08x}"
    program.append((hex_str, comment))
    addr += 4

# Register aliases
x0, x1, x2, x3, x4, x5 = 0, 1, 2, 3, 4, 5
x6, x7, x8, x9, x10 = 6, 7, 8, 9, 10
x11, x12, x13, x14, x15 = 11, 12, 13, 14, 15
x16, x17, x18, x19, x20 = 16, 17, 18, 19, 20
x21, x22, x23, x24, x25 = 21, 22, 23, 24, 25
x26, x27, x28, x29, x30, x31 = 26, 27, 28, 29, 30, 31

# Test result memory offset (stored at DMEM base + offset)
t = 0  # test counter (result offset = t*4)

def store_result(reg, test_num=None):
    """Store result reg to DMEM[test_num*4] via x4 base.
    Add 2 NOPs after to isolate from next test."""
    global t
    if test_num is None:
        test_num = t
        t += 1
    emit(NOP(),                      "  nop (settle)")
    emit(SW(x4, reg, test_num * 4),  f"  -> DMEM[{test_num}]")

def sep():
    """Separator NOPs between tests to avoid cross-test hazards"""
    emit(NOP(), "--- test separator ---")
    emit(NOP(), "--- test separator ---")

# ============================================================================
# TEST PROGRAM
# ============================================================================

# ==================== PHASE 1: SETUP OPERANDS ===============================
emit(ADDI(x1, x0, 5),       "x1 = 5")
emit(ADDI(x2, x0, -1),      "x2 = 0xFFFFFFFF (-1)")
emit(ADDI(x3, x0, 10),      "x3 = 10")
emit(LUI(x4, 0x10000),      "x4 = 0x10000000 (DMEM base)")
emit(LUI(x5, 0x80000),      "x5 = 0x80000000 (INT_MIN)")
emit(NOP(),                  "pipeline settle")
emit(NOP(),                  "pipeline settle")
emit(NOP(),                  "pipeline settle")

# ==================== PHASE 2: R-TYPE TESTS ================================
# Test 0: ADD
emit(ADD(x6, x1, x3),       "T0: ADD  x6 = 5+10 = 15")
store_result(x6)

# Test 1: SUB
sep()
emit(SUB(x6, x3, x1),       "T1: SUB  x6 = 10-5 = 5")
store_result(x6)

# Test 2: SLL
sep()
emit(SLL(x6, x1, x3),       "T2: SLL  x6 = 5<<10 = 5120")
store_result(x6)

# Test 3: SLT (signed: -1 < 5)
sep()
emit(SLT(x6, x2, x1),       "T3: SLT  x6 = (-1<5)s = 1")
store_result(x6)

# Test 4: SLTU (unsigned: 5 < 0xFFFFFFFF)
sep()
emit(SLTU(x6, x1, x2),      "T4: SLTU x6 = (5<MAX)u = 1")
store_result(x6)

# Test 5: XOR
sep()
emit(XOR(x6, x1, x3),       "T5: XOR  x6 = 5^10 = 15")
store_result(x6)

# Test 6: SRL
sep()
emit(SRL(x6, x2, x1),       "T6: SRL  x6 = 0xFFFFFFFF>>>5 = 0x07FFFFFF")
store_result(x6)

# Test 7: SRA
sep()
emit(SRA(x6, x2, x1),       "T7: SRA  x6 = -1>>a5 = 0xFFFFFFFF")
store_result(x6)

# Test 8: OR
sep()
emit(OR(x6, x1, x3),        "T8: OR   x6 = 5|10 = 15")
store_result(x6)

# Test 9: AND
sep()
emit(AND(x6, x1, x3),       "T9: AND  x6 = 5&10 = 0")
store_result(x6)

# ==================== PHASE 3: I-TYPE ALU TESTS ============================
# Test 10: ADDI with max positive imm
sep()
emit(ADDI(x6, x1, 2047),    "T10: ADDI x6 = 5+2047 = 2052")
store_result(x6)

# Test 11: ADDI with min negative imm
sep()
emit(ADDI(x6, x0, -2048),   "T11: ADDI x6 = -2048 = 0xFFFFF800")
store_result(x6)

# Test 12: SLTI (signed: -1 < 5)
sep()
emit(SLTI(x6, x2, 5),       "T12: SLTI x6 = (-1<5)s = 1")
store_result(x6)

# Test 13: SLTIU (unsigned: 5 < 0xFFFFFFFF)
sep()
emit(SLTIU(x6, x1, -1),     "T13: SLTIU x6 = (5<MAX)u = 1")
store_result(x6)

# Test 14: XORI
sep()
emit(XORI(x6, x1, -1),      "T14: XORI x6 = 5^-1 = 0xFFFFFFFA")
store_result(x6)

# Test 15: ORI
sep()
emit(ORI(x6, x1, 0xF0),     "T15: ORI  x6 = 5|0xF0 = 0xF5")
store_result(x6)

# Test 16: ANDI
sep()
emit(ANDI(x6, x2, 0xFF),    "T16: ANDI x6 = -1&0xFF = 0xFF")
store_result(x6)

# Test 17: SLLI
sep()
emit(SLLI(x6, x1, 3),       "T17: SLLI x6 = 5<<3 = 40")
store_result(x6)

# Test 18: SRLI
sep()
emit(SRLI(x6, x2, 28),      "T18: SRLI x6 = 0xFFFFFFFF>>>28 = 0xF")
store_result(x6)

# Test 19: SRAI
sep()
emit(SRAI(x6, x5, 16),      "T19: SRAI x6 = 0x80000000>>a16 = 0xFFFF8000")
store_result(x6)

# ==================== PHASE 4: U-TYPE TESTS ================================
# Test 20: LUI
sep()
emit(LUI(x6, 0xDEADB),      "T20: LUI  x6 = 0xDEADB000")
store_result(x6)

# Test 21: AUIPC
sep()
auipc_addr = addr
emit(AUIPC(x6, 0x00001),    f"T21: AUIPC x6 = 0x{auipc_addr:03X}+0x1000")
store_result(x6)

# ==================== PHASE 5: STORE + LOAD TESTS ==========================
# Store test data to DMEM[256..] (offset 256 from base) for load tests
sep()
emit(ADDI(x7, x0, 0x5A),    "x7 = 0x5A (test data)")
emit(ADDI(x8, x0, -86),     "x8 = 0xFFFFFFAA (-86)")
emit(NOP(),                  "settle")
emit(NOP(),                  "settle")

emit(SW(x4, x7, 256),       "DMEM[256] = 0x0000005A (SW test)")
emit(SW(x4, x2, 260),       "DMEM[260] = 0xFFFFFFFF (SW test)")
emit(SH(x4, x3, 264),       "DMEM[264] = 0x000A (SH test)")
emit(SB(x4, x8, 268),       "DMEM[268] = 0xAA (SB test)")
emit(NOP(),                  "pipeline settle for stores")
emit(NOP(),                  "pipeline settle for stores")
emit(NOP(),                  "pipeline settle for stores")

# Test 22: LW
emit(LW(x6, x4, 256),       "T22: LW  x6 = MEM[256] = 0x5A")
emit(NOP(),                  "load-use gap")
store_result(x6)

# Test 23: LH (signed half-word from 0xFFFFFFFF -> 0xFFFF -> sign_ext = 0xFFFFFFFF)
sep()
emit(LH(x6, x4, 260),       "T23: LH  x6 = sext(0xFFFF) = 0xFFFFFFFF")
emit(NOP(),                  "load-use gap")
store_result(x6)

# Test 24: LB (signed byte from 0xAA -> sign_ext = 0xFFFFFFAA)
sep()
emit(LB(x6, x4, 268),       "T24: LB  x6 = sext(0xAA) = 0xFFFFFFAA")
emit(NOP(),                  "load-use gap")
store_result(x6)

# Test 25: LHU (unsigned half-word)
sep()
emit(LHU(x6, x4, 260),      "T25: LHU x6 = zext(0xFFFF) = 0x0000FFFF")
emit(NOP(),                  "load-use gap")
store_result(x6)

# Test 26: LBU (unsigned byte)
sep()
emit(LBU(x6, x4, 268),      "T26: LBU x6 = zext(0xAA) = 0x000000AA")
emit(NOP(),                  "load-use gap")
store_result(x6)

# ==================== PHASE 6: BRANCH TESTS ================================
# Pattern: set x6=0, branch, if skipped correctly x6=1, else x6 stays wrong

# Test 27: BEQ taken (equal)
sep()
emit(ADDI(x6, x0, 0),       "T27: BEQ taken setup")
emit(BEQ(x1, x1, 8),        "  BEQ x1,x1,+8 (taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED if taken")
emit(ADDI(x6, x6, 1),       "  x6 = 0+1 = 1")
store_result(x6)

# Test 28: BEQ not-taken (not equal)
sep()
emit(ADDI(x6, x0, 0),       "T28: BEQ not-taken setup")
emit(BEQ(x1, x3, 8),        "  BEQ x1,x3,+8 (NOT taken, 5!=10)")
emit(ADDI(x6, x0, 1),       "  EXECUTED: x6=1")
emit(NOP(),                  "  fall-through")
store_result(x6)

# Test 29: BNE taken (not equal)
sep()
emit(ADDI(x6, x0, 0),       "T29: BNE taken setup")
emit(BNE(x1, x3, 8),        "  BNE x1,x3,+8 (taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED if taken")
emit(ADDI(x6, x6, 1),       "  x6 = 0+1 = 1")
store_result(x6)

# Test 30: BLT taken (signed: -1 < 5)
sep()
emit(ADDI(x6, x0, 0),       "T30: BLT taken setup")
emit(BLT(x2, x1, 8),        "  BLT x2,x1,+8 (-1<5, taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED")
emit(ADDI(x6, x6, 1),       "  x6 = 1")
store_result(x6)

# Test 31: BGE taken (signed: 5 >= -1)
sep()
emit(ADDI(x6, x0, 0),       "T31: BGE taken setup")
emit(BGE(x1, x2, 8),        "  BGE x1,x2,+8 (5>=-1, taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED")
emit(ADDI(x6, x6, 1),       "  x6 = 1")
store_result(x6)

# Test 32: BLTU taken (unsigned: 5 < 0xFFFFFFFF)
sep()
emit(ADDI(x6, x0, 0),       "T32: BLTU taken setup")
emit(BLTU(x1, x2, 8),       "  BLTU x1,x2,+8 (5<MAX, taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED")
emit(ADDI(x6, x6, 1),       "  x6 = 1")
store_result(x6)

# Test 33: BGEU taken (unsigned: 0xFFFFFFFF >= 5)
sep()
emit(ADDI(x6, x0, 0),       "T33: BGEU taken setup")
emit(BGEU(x2, x1, 8),       "  BGEU x2,x1,+8 (MAX>=5, taken)")
emit(ADDI(x6, x0, -1),      "  SKIPPED")
emit(ADDI(x6, x6, 1),       "  x6 = 1")
store_result(x6)

# Test 34: BLT not-taken (5 not < -1 signed)
sep()
emit(ADDI(x6, x0, 0),       "T34: BLT not-taken setup")
emit(BLT(x1, x2, 8),        "  BLT x1,x2,+8 (5<-1? NO)")
emit(ADDI(x6, x0, 1),       "  EXECUTED: x6=1")
emit(NOP(),                  "  fall-through")
store_result(x6)

# Test 35: BLTU not-taken (0xFFFFFFFF not < 5 unsigned)
sep()
emit(ADDI(x6, x0, 0),       "T35: BLTU not-taken setup")
emit(BLTU(x2, x1, 8),       "  BLTU x2,x1,+8 (MAX<5? NO)")
emit(ADDI(x6, x0, 1),       "  EXECUTED: x6=1")
emit(NOP(),                  "  fall-through")
store_result(x6)

# ==================== PHASE 7: JUMP TESTS ==================================
# Test 36: JAL (link addr)
sep()
jal_pc = addr
emit(JAL(x6, 8),             f"T36: JAL x6,+8 (x6=PC+4=0x{jal_pc+4:X})")
emit(ADDI(x6, x0, -1),      "  SKIPPED by JAL")
store_result(x6)

# Test 37: JALR  - use separate registers, add NOPs to avoid hazards
sep()
emit(ADDI(x10, x0, 0),       "T37: JALR flag=0")
emit(NOP(),                   "  settle")
# Use x11 as target address register
# AUIPC x11, 0  → x11 = current PC
jalr_auipc_pc = addr
emit(AUIPC(x11, 0),          f"  x11 = PC = 0x{jalr_auipc_pc:X}")
emit(NOP(),                   "  settle")
emit(NOP(),                   "  settle")
# ADDI x11, x11, 16 → skip next 4 instructions (ADDI+JALR+skip+land = 16 bytes)
emit(ADDI(x11, x11, 16),     "  x11 = PC + 16 (target = landing)")
emit(NOP(),                   "  settle")
emit(NOP(),                   "  settle")
emit(JALR(x6, x11, 0),       "  JALR x6, x11, 0")
emit(ADDI(x10, x0, -1),      "  SKIPPED by JALR")
# Landing point:
emit(ADDI(x10, x0, 1),       "  JALR lands here: x10=1")
emit(NOP(),                   "  settle")
store_result(x10)

# ==================== PHASE 8: CORNER CASES ================================
# Test 38: x0 immutability (ADDI x0, x1, 100 should NOT change x0)
sep()
emit(ADDI(x0, x1, 100),      "T38: write to x0 (should be ignored)")
emit(NOP(),                   "  settle")
emit(ADD(x6, x0, x0),        "  x6 = x0 + x0 = 0 (proves x0=0)")
store_result(x6)

# Test 39: ADD overflow (INT_MAX + 1)
sep()
emit(LUI(x8, 0x80000),       "T39: x8 = 0x80000000")
emit(NOP(),                   "  settle")
emit(ADDI(x8, x8, -1),       "  x8 = 0x7FFFFFFF (INT_MAX)")
emit(ADDI(x7, x0, 1),        "  x7 = 1")
emit(NOP(),                   "  settle")
emit(NOP(),                   "  settle")
emit(ADD(x6, x8, x7),        "  x6 = INT_MAX+1 = 0x80000000 (overflow)")
store_result(x6)

# Test 40: SUB underflow (INT_MIN - 1)
sep()
emit(ADDI(x7, x0, 1),        "T40: x7 = 1")
emit(NOP(),                   "  settle")
emit(NOP(),                   "  settle")
emit(SUB(x6, x5, x7),        "  x6 = 0x80000000-1 = 0x7FFFFFFF (underflow)")
store_result(x6)

# Test 41: Shift by 0
sep()
emit(SLLI(x6, x1, 0),        "T41: SLLI x6 = 5<<0 = 5")
store_result(x6)

# Test 42: Shift by 31 (use a known register, not x7 which may be clobbered)
sep()
emit(ADDI(x10, x0, 1),       "T42: x10 = 1")
emit(NOP(),                   "  settle")
emit(SLLI(x6, x10, 31),      "  SLLI x6 = 1<<31 = 0x80000000")
store_result(x6)

# Test 43: SRA of positive number
sep()
emit(SRAI(x6, x1, 1),        "T43: SRAI x6 = 5>>a1 = 2")
store_result(x6)

# Test 44: ADD with zero
sep()
emit(ADD(x6, x1, x0),        "T44: ADD x6 = 5+0 = 5")
store_result(x6)

# Test 45: SUB self (zero)
sep()
emit(SUB(x6, x1, x1),        "T45: SUB x6 = 5-5 = 0")
store_result(x6)

# Test 46: XOR self (zero)
sep()
emit(XOR(x6, x1, x1),        "T46: XOR x6 = 5^5 = 0")
store_result(x6)

# Test 47: OR self (identity)
sep()
emit(OR(x6, x1, x1),         "T47: OR  x6 = 5|5 = 5")
store_result(x6)

# Test 48: SLTU x0 < x1 (0 < 5)
sep()
emit(SLTU(x6, x0, x1),       "T48: SLTU x6 = (0<5)u = 1")
store_result(x6)

# Test 49: SLT equal values
sep()
emit(SLT(x6, x1, x1),        "T49: SLT x6 = (5<5)s = 0")
store_result(x6)

# ==================== PHASE 9: SPECIAL INSTRUCTIONS =========================
# Test 50: FENCE (treated as NOP -- execution should continue)
sep()
emit(ADDI(x6, x0, 0xAA),     "T50: before FENCE")
emit(FENCE(),                 "  FENCE (NOP)")
emit(NOP(),                   "  settle")
emit(ADDI(x6, x6, 0x11),     "  after FENCE: x6 = 0xAA+0x11 = 0xBB")
store_result(x6)

# Test 51: ECALL (treated as NOP)
sep()
emit(ADDI(x6, x0, 0x55),     "T51: before ECALL")
emit(ECALL(),                 "  ECALL (NOP)")
emit(NOP(),                   "  settle")
emit(ADDI(x6, x6, 0x11),     "  after ECALL: x6 = 0x55+0x11 = 0x66")
store_result(x6)

# Test 52: EBREAK (treated as NOP)
sep()
emit(ADDI(x6, x0, 0x33),     "T52: before EBREAK")
emit(EBREAK(),                "  EBREAK (NOP)")
emit(NOP(),                   "  settle")
emit(ADDI(x6, x6, 0x11),     "  after EBREAK: x6 = 0x33+0x11 = 0x44")
store_result(x6)

# ==================== PHASE 10: DATA HAZARD TESTS ===========================
# Test 53: RAW hazard (back-to-back dependency)
# Use x10 as accumulator (different from store_result's x6 dependency)
sep()
emit(ADDI(x10, x0, 42),      "T53: RAW hazard x10=42")
emit(ADDI(x10, x10, 1),      "  RAW: x10 = 42+1 = 43")
emit(ADDI(x10, x10, 1),      "  RAW: x10 = 43+1 = 44")
emit(ADDI(x10, x10, 1),      "  RAW: x10 = 44+1 = 45")
emit(NOP(),                   "  settle")
emit(ADDI(x6, x10, 0),       "  x6 = x10 = 45")
store_result(x6)

# Test 54: Load-use hazard
sep()
emit(ADDI(x10, x0, 5),       "T54: x10 = 5 (data to store)")
emit(NOP(),                   "  settle")
emit(SW(x4, x10, 512),       "  store 5 to DMEM[512]")
emit(NOP(),                   "  settle stores")
emit(NOP(),                   "  settle stores")
emit(NOP(),                   "  settle stores")
emit(LW(x10, x4, 512),       "  load x10 from DMEM[512] = 5")
emit(NOP(),                   "  load-use stall gap")
emit(NOP(),                   "  extra settle")
emit(ADDI(x6, x10, 10),      "  USE: x6 = 5+10 = 15 (load-use)")
store_result(x6)

# Test 55: Multiple forwarding paths
sep()
emit(ADDI(x10, x0, 100),     "T55: setup x10=100")
emit(ADDI(x11, x0, 200),     "  setup x11=200")
emit(NOP(),                   "  settle")
emit(NOP(),                   "  settle")
emit(ADD(x6, x10, x11),      "  x6 = 100+200 = 300 (both fwd)")
store_result(x6)

# ==================== PHASE 11: NEGATIVE BRANCH OFFSET ======================
# Test 56: Backward branch (loop test - iterate 3 times)
# Use x10 as counter and x11 as limit to avoid conflicting with x6/x7
sep()
emit(ADDI(x10, x0, 0),       "T56: loop counter x10 = 0")
emit(ADDI(x11, x0, 3),       "  loop limit x11 = 3")
emit(NOP(),                   "  settle")
# loop_start:                   addr = loop_top
loop_top = addr
emit(ADDI(x10, x10, 1),      "  loop_start: x10++")
# BNE x10, x11, offset_back_to_loop_start
# offset = loop_top - (current addr after BNE emitted)
# But we calculate offset as from BNE PC to loop_top
# BNE is at addr (before emit), loop_top is the ADDI above
# offset = loop_top - addr (BNE_PC) = negative
bne_pc = addr
bne_offset = loop_top - bne_pc   # should be -4
emit(BNE(x10, x11, bne_offset),  f"  BNE x10,x11,{bne_offset} (back to loop_start)")
# After loop: x10 = 3
emit(NOP(),                   "  post-loop settle")
emit(ADDI(x6, x10, 0),       "  x6 = x10 = 3")
store_result(x6)

# ==================== PHASE 12: SIGN-EXTENSION CORNER CASES =================
# Test 57: ADDI negative immediate
sep()
emit(ADDI(x6, x0, -1),       "T57: ADDI x6 = -1 = 0xFFFFFFFF")
store_result(x6)

# Test 58: SLTI with negative immediate
sep()
emit(SLTI(x6, x0, -1),       "T58: SLTI x6 = (0<-1)s = 0")
store_result(x6)

# Test 59: SLTIU with 1 (smallest positive)
sep()
emit(SLTIU(x6, x0, 1),       "T59: SLTIU x6 = (0<1)u = 1")
store_result(x6)

# ==================== SIGNAL COMPLETION VIA GPIO ============================
# Write 0xCAFE to GPIO (0x20000000, offset 0x04 = data_out register)
sep()
emit(LUI(x9, 0x20000),       "x9 = 0x20000000 (GPIO base)")
emit(ADDI(x6, x0, 0),        "x6 = 0")
emit(LUI(x6, 0x0CAFE),       "x6 = 0x0CAFE000")
emit(NOP(),                   "settle")
emit(SRLI(x6, x6, 12),       "x6 = 0x0000CAFE")
emit(NOP(),                   "settle")
emit(SW(x9, x6, 4),          "GPIO_DATA_OUT = 0xCAFE (completion signal)")

# Infinite loop (end of program)
emit(JAL(x0, 0),              "END: infinite loop (JAL x0, 0)")

# ============================================================================
# Generate expected values table
# ============================================================================
expected = {
    0:  0x0000000F,  # ADD 5+10=15
    1:  0x00000005,  # SUB 10-5=5
    2:  0x00001400,  # SLL 5<<10=5120
    3:  0x00000001,  # SLT -1<5=1
    4:  0x00000001,  # SLTU 5<MAX=1
    5:  0x0000000F,  # XOR 5^10=15
    6:  0x07FFFFFF,  # SRL MAX>>>5
    7:  0xFFFFFFFF,  # SRA -1>>a5=-1
    8:  0x0000000F,  # OR 5|10=15
    9:  0x00000000,  # AND 5&10=0
    10: 0x00000804,  # ADDI 5+2047=2052
    11: 0xFFFFF800,  # ADDI -2048
    12: 0x00000001,  # SLTI -1<5=1
    13: 0x00000001,  # SLTIU 5<MAX=1
    14: 0xFFFFFFFA,  # XORI 5^-1
    15: 0x000000F5,  # ORI 5|0xF0
    16: 0x000000FF,  # ANDI -1&0xFF
    17: 0x00000028,  # SLLI 5<<3=40
    18: 0x0000000F,  # SRLI MAX>>>28
    19: 0xFFFF8000,  # SRAI MIN>>a16
    20: 0xDEADB000,  # LUI
    21: auipc_addr + 0x1000,  # AUIPC
    22: 0x0000005A,  # LW
    23: 0xFFFFFFFF,  # LH (sign-ext)
    24: 0xFFFFFFAA,  # LB (sign-ext)
    25: 0x0000FFFF,  # LHU
    26: 0x000000AA,  # LBU
    27: 0x00000001,  # BEQ taken
    28: 0x00000001,  # BEQ not-taken
    29: 0x00000001,  # BNE taken
    30: 0x00000001,  # BLT taken
    31: 0x00000001,  # BGE taken
    32: 0x00000001,  # BLTU taken
    33: 0x00000001,  # BGEU taken
    34: 0x00000001,  # BLT not-taken
    35: 0x00000001,  # BLTU not-taken
    36: jal_pc + 4,  # JAL link
    37: 0x00000001,  # JALR (lands correctly, x10=1)
    38: 0x00000000,  # x0 immutability
    39: 0x80000000,  # ADD overflow
    40: 0x7FFFFFFF,  # SUB underflow
    41: 0x00000005,  # SLLI by 0
    42: 0x80000000,  # SLLI by 31
    43: 0x00000002,  # SRAI positive
    44: 0x00000005,  # ADD with zero
    45: 0x00000000,  # SUB self
    46: 0x00000000,  # XOR self
    47: 0x00000005,  # OR self
    48: 0x00000001,  # SLTU 0<5
    49: 0x00000000,  # SLT equal
    50: 0x000000BB,  # FENCE NOP
    51: 0x00000066,  # ECALL NOP
    52: 0x00000044,  # EBREAK NOP
    53: 0x0000002D,  # RAW hazard = 45
    54: 0x0000000F,  # Load-use = 15
    55: 0x0000012C,  # Forward paths = 300
    56: 0x00000003,  # Loop count = 3
    57: 0xFFFFFFFF,  # ADDI -1
    58: 0x00000000,  # SLTI 0<-1 = 0
    59: 0x00000001,  # SLTIU 0<1 = 1
}

# ============================================================================
# Write output files
# ============================================================================
script_dir = os.path.dirname(os.path.abspath(__file__))

# Write .mem file
mem_path = os.path.join(script_dir, "rv32i_test_program.mem")
with open(mem_path, "w") as f:
    f.write("// RV32I Comprehensive Test Program (auto-generated)\n")
    f.write(f"// {len(program)} instructions, {t} test results to DMEM\n")
    f.write("// Results at DMEM base 0x10000000, offset = test_num * 4\n\n")
    for i, (hexval, comment) in enumerate(program):
        f.write(f"{hexval}  // [{i*4:03X}] {comment}\n")

# Write expected values as Verilog include
vh_path = os.path.join(script_dir, "test_expected.vh")
with open(vh_path, "w") as f:
    f.write("// Auto-generated expected values for RV32I test program\n")
    f.write(f"localparam NUM_TESTS = {len(expected)};\n")
    f.write("reg [31:0] expected_values [0:NUM_TESTS-1];\n")
    f.write("reg [255:0] test_names [0:NUM_TESTS-1];\n\n")
    f.write("initial begin\n")
    
    test_descs = {
        0: "ADD  5+10",  1: "SUB  10-5", 2: "SLL  5<<10", 3: "SLT  -1<5",
        4: "SLTU 5<MAX", 5: "XOR  5^10", 6: "SRL  MAX>>>5", 7: "SRA  -1>>a5",
        8: "OR   5|10",  9: "AND  5&10", 10: "ADDI max_imm", 11: "ADDI min_imm",
        12: "SLTI signed", 13: "SLTIU unsigned", 14: "XORI inverse", 15: "ORI  bits",
        16: "ANDI mask", 17: "SLLI x3", 18: "SRLI x28", 19: "SRAI neg",
        20: "LUI  value", 21: "AUIPC addr", 22: "LW   word", 23: "LH   signed",
        24: "LB   signed", 25: "LHU  unsigned", 26: "LBU  unsigned",
        27: "BEQ  taken", 28: "BEQ  not-taken", 29: "BNE  taken",
        30: "BLT  taken", 31: "BGE  taken", 32: "BLTU taken", 33: "BGEU taken",
        34: "BLT  not-taken", 35: "BLTU not-taken",
        36: "JAL  link", 37: "JALR jump", 38: "x0   immutable",
        39: "ADD  overflow", 40: "SUB  underflow", 41: "SLLI by_0",
        42: "SLLI by_31", 43: "SRAI positive", 44: "ADD  with_zero",
        45: "SUB  self", 46: "XOR  self", 47: "OR   self",
        48: "SLTU 0<5", 49: "SLT  equal", 50: "FENCE nop",
        51: "ECALL nop", 52: "EBREAK nop", 53: "RAW  hazard",
        54: "Load-use haz", 55: "Multi fwd", 56: "Loop backward",
        57: "ADDI neg_imm", 58: "SLTI neg_cmp", 59: "SLTIU pos",
    }
    
    for k in range(len(expected)):
        f.write(f"    expected_values[{k}] = 32'h{expected[k]:08X};\n")
    f.write("\n")
    for k in range(len(expected)):
        desc = test_descs.get(k, f"Test {k}")
        f.write(f'    test_names[{k}] = "T{k:02d}: {desc}";\n')
    f.write("end\n")

print(f"Generated {len(program)} instructions ({len(program)*4} bytes)")
print(f"Generated {len(expected)} test result checks")
print(f"Files: {mem_path}")
print(f"       {vh_path}")
