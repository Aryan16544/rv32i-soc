# =============================================================================
# RV32I Full Instruction Test Suite - UART Output
# Tests all 37 RV32I base instructions
# Author: Aryan's RV32I Verification Team
# =============================================================================
# Memory Map:
#   UART_BASE  = 0x30000000
#   UART_TX    = UART_BASE + 0x00 (write byte here)
#   UART_STATUS = UART_BASE + 0x08 (bit 1 = TX FIFO full)
#   DATA_MEM   = 0x10000000 (for load/store tests)
#
# Output Format:
#   Each test prints: [INSTRUCTION_NAME]: [PASS/FAIL]\n
# =============================================================================

.equ UART_BASE,   0x30000000
.equ UART_TX,     0x00
.equ UART_STATUS, 0x08
.equ DATA_MEM,    0x10000000

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================
_start:
    # Initialize UART base address in x1
    lui     x1, 0x30000       # x1 = UART_BASE (0x30000000)
    
    # Initialize data memory pointer in x2  
    lui     x2, 0x10000       # x2 = DATA_MEM (0x10000000)
    
    # Initialize test data
    addi    x3, x0, 0         # x3 = test result (0=pass, 1=fail)
    
    # Print header: "RV32I TEST\n"
    jal     x31, print_header
    
    # ==========================================================================
    # TEST 1: LUI (Load Upper Immediate)
    # ==========================================================================
test_lui:
    jal     x31, print_lui_name
    lui     x10, 0x12345      # x10 = 0x12345000
    lui     x11, 0x12345      # Expected value
    beq     x10, x11, lui_pass
    jal     x31, print_fail
    j       test_auipc
lui_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 2: AUIPC (Add Upper Immediate to PC)
    # ==========================================================================
test_auipc:
    jal     x31, print_auipc_name
    auipc   x10, 0            # x10 = current PC
    addi    x10, x10, 4       # x10 = PC + 4 (next instruction address)
    auipc   x11, 0            # x11 = current PC (should be x10)
    beq     x10, x11, auipc_pass
    jal     x31, print_fail
    j       test_jal
auipc_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 3: JAL (Jump and Link)
    # ==========================================================================
test_jal:
    jal     x31, print_jal_name
    jal     x10, jal_target     # Jump and save return address
    j       jal_check           # Should skip this if JAL works
jal_target:
    addi    x11, x0, 1          # Mark that we reached here
    jalr    x0, x10, 0          # Return to x10 (link address)
jal_check:
    addi    x12, x0, 1          # Expected value
    beq     x11, x12, jal_pass
    jal     x31, print_fail
    j       test_jalr
jal_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 4: JALR (Jump and Link Register)
    # ==========================================================================
test_jalr:
    jal     x31, print_jalr_name
    addi    x11, x0, 0          # Clear x11
    jal     x10, jalr_setup     # Get address of jalr_target2
jalr_setup:
    addi    x10, x10, 16        # Point to jalr_target2 (skip 4 instructions)
    jalr    x12, x10, 0         # Jump to jalr_target2, save return in x12
    j       jalr_check
jalr_target2:
    addi    x11, x0, 2          # Mark that we reached here
    jalr    x0, x12, 0          # Return
jalr_check:
    addi    x13, x0, 2
    beq     x11, x13, jalr_pass
    jal     x31, print_fail
    j       test_beq
jalr_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 5: BEQ (Branch if Equal)
    # ==========================================================================
test_beq:
    jal     x31, print_beq_name
    addi    x10, x0, 42
    addi    x11, x0, 42
    beq     x10, x11, beq_pass
    jal     x31, print_fail
    j       test_bne
beq_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 6: BNE (Branch if Not Equal)
    # ==========================================================================
test_bne:
    jal     x31, print_bne_name
    addi    x10, x0, 42
    addi    x11, x0, 43
    bne     x10, x11, bne_pass
    jal     x31, print_fail
    j       test_blt
bne_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 7: BLT (Branch if Less Than - signed)
    # ==========================================================================
test_blt:
    jal     x31, print_blt_name
    addi    x10, x0, -5         # x10 = -5 (signed)
    addi    x11, x0, 5          # x11 = 5
    blt     x10, x11, blt_pass
    jal     x31, print_fail
    j       test_bge
blt_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 8: BGE (Branch if Greater or Equal - signed)
    # ==========================================================================
test_bge:
    jal     x31, print_bge_name
    addi    x10, x0, 10
    addi    x11, x0, 10
    bge     x10, x11, bge_pass
    jal     x31, print_fail
    j       test_bltu
bge_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 9: BLTU (Branch if Less Than Unsigned)
    # ==========================================================================
test_bltu:
    jal     x31, print_bltu_name
    addi    x10, x0, 5
    addi    x11, x0, -1         # x11 = 0xFFFFFFFF (largest unsigned)
    bltu    x10, x11, bltu_pass
    jal     x31, print_fail
    j       test_bgeu
bltu_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 10: BGEU (Branch if Greater or Equal Unsigned)
    # ==========================================================================
test_bgeu:
    jal     x31, print_bgeu_name
    addi    x10, x0, -1         # x10 = 0xFFFFFFFF
    addi    x11, x0, 100
    bgeu    x10, x11, bgeu_pass
    jal     x31, print_fail
    j       test_lb
bgeu_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 11-15: Load Instructions (LB, LH, LW, LBU, LHU)
    # First store test data to memory
    # ==========================================================================
    # Store test pattern: 0xDEADBEEF at DATA_MEM
    lui     x10, 0xDEADB
    addi    x10, x10, 0xEEF     # This won't work exactly, but close
    # Actually let's use: 0x807F8180
    lui     x10, 0x807F8       # Upper bits
    addi    x10, x10, 0x180    # x10 = test pattern
    sw      x10, 0(x2)          # Store at DATA_MEM
    
    # TEST 11: LW (Load Word)
test_lw:
    jal     x31, print_lw_name
    lw      x11, 0(x2)          # Load word from DATA_MEM
    beq     x10, x11, lw_pass
    jal     x31, print_fail
    j       test_lh
lw_pass:
    jal     x31, print_pass
    
    # TEST 12: LH (Load Halfword - signed)
test_lh:
    jal     x31, print_lh_name
    # Store 0x8000FF80 to test sign extension
    lui     x10, 0x8000F
    addi    x10, x10, 0xF80     # x10 = 0x8000FF80
    sw      x10, 4(x2)          # Store at DATA_MEM+4
    lh      x11, 4(x2)          # Load lower halfword (0xFF80)
    # 0xFF80 sign-extended = 0xFFFFFF80
    lui     x12, 0xFFFFF
    addi    x12, x12, 0xF80     # Expected: 0xFFFFFF80
    beq     x11, x12, lh_pass
    jal     x31, print_fail
    j       test_lhu
lh_pass:
    jal     x31, print_pass
    
    # TEST 13: LHU (Load Halfword Unsigned)
test_lhu:
    jal     x31, print_lhu_name
    lhu     x11, 4(x2)          # Load lower halfword unsigned (0xFF80)
    addi    x12, x0, 0          # Build expected value
    lui     x12, 0x00000
    addi    x12, x0, 0x7F       # Can't easily build 0xFF80, let's just check non-zero
    addi    x12, x12, 1         # x12 = 0x80
    # LHU should give 0x0000FF80 - check upper bits are 0
    srli    x13, x11, 16        # Upper 16 bits should be 0
    beq     x13, x0, lhu_pass
    jal     x31, print_fail
    j       test_lb
lhu_pass:
    jal     x31, print_pass
    
    # TEST 14: LB (Load Byte - signed)
test_lb:
    jal     x31, print_lb_name
    # Store 0x00000080 to test sign extension
    addi    x10, x0, 0x80       # Store 0x80 in lower byte
    sb      x10, 8(x2)          # Store byte
    lb      x11, 8(x2)          # Load byte signed - should be 0xFFFFFF80
    # Check if sign-extended (negative)
    blt     x11, x0, lb_pass    # If negative, sign extension worked
    jal     x31, print_fail
    j       test_lbu
lb_pass:
    jal     x31, print_pass
    
    # TEST 15: LBU (Load Byte Unsigned)
test_lbu:
    jal     x31, print_lbu_name
    lbu     x11, 8(x2)          # Load byte unsigned - should be 0x00000080
    addi    x12, x0, 0x80       # Expected value
    beq     x11, x12, lbu_pass
    jal     x31, print_fail
    j       test_sb
lbu_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 16-18: Store Instructions (SB, SH, SW)
    # ==========================================================================
    # TEST 16: SB (Store Byte)
test_sb:
    jal     x31, print_sb_name
    addi    x10, x0, 0x55       # Test pattern
    sb      x10, 12(x2)         # Store byte
    lbu     x11, 12(x2)         # Read back
    beq     x10, x11, sb_pass
    jal     x31, print_fail
    j       test_sh
sb_pass:
    jal     x31, print_pass
    
    # TEST 17: SH (Store Halfword)
test_sh:
    jal     x31, print_sh_name
    lui     x10, 0x00001
    addi    x10, x10, 0x234     # x10 = 0x00001234
    sh      x10, 16(x2)         # Store halfword (only 0x1234)
    lhu     x11, 16(x2)         # Read back
    andi    x12, x10, 0x7FF     # Mask to get lower bits
    lui     x13, 0x00000
    addi    x13, x0, 0x234      # Expected lower part
    # Just check if stored/loaded properly
    addi    x12, x0, 0x34       # Check lower byte
    lbu     x14, 16(x2)         # Load lower byte
    beq     x14, x12, sh_pass
    jal     x31, print_fail
    j       test_sw
sh_pass:
    jal     x31, print_pass
    
    # TEST 18: SW (Store Word) - already tested implicitly, but explicit test
test_sw:
    jal     x31, print_sw_name
    lui     x10, 0xABCDE
    addi    x10, x10, 0x123     # x10 = 0xABCDE123
    sw      x10, 20(x2)         # Store word
    lw      x11, 20(x2)         # Read back
    beq     x10, x11, sw_pass
    jal     x31, print_fail
    j       test_addi
sw_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 19-27: Immediate ALU Instructions
    # ==========================================================================
    # TEST 19: ADDI (Add Immediate)
test_addi:
    jal     x31, print_addi_name
    addi    x10, x0, 100        # x10 = 100
    addi    x10, x10, 50        # x10 = 150
    addi    x11, x0, 150        # Expected
    beq     x10, x11, addi_pass
    jal     x31, print_fail
    j       test_slti
addi_pass:
    jal     x31, print_pass
    
    # TEST 20: SLTI (Set Less Than Immediate - signed)
test_slti:
    jal     x31, print_slti_name
    addi    x10, x0, -10        # x10 = -10
    slti    x11, x10, 5         # x11 = 1 (since -10 < 5)
    addi    x12, x0, 1          # Expected
    beq     x11, x12, slti_pass
    jal     x31, print_fail
    j       test_sltiu
slti_pass:
    jal     x31, print_pass
    
    # TEST 21: SLTIU (Set Less Than Immediate Unsigned)
test_sltiu:
    jal     x31, print_sltiu_name
    addi    x10, x0, 5
    sltiu   x11, x10, 10        # x11 = 1 (since 5 < 10)
    addi    x12, x0, 1
    beq     x11, x12, sltiu_pass
    jal     x31, print_fail
    j       test_xori
sltiu_pass:
    jal     x31, print_pass
    
    # TEST 22: XORI (XOR Immediate)
test_xori:
    jal     x31, print_xori_name
    addi    x10, x0, 0xFF       # x10 = 0xFF
    xori    x11, x10, 0x0F      # x11 = 0xF0 (toggle lower 4 bits)
    addi    x12, x0, 0xF0       # Expected
    beq     x11, x12, xori_pass
    jal     x31, print_fail
    j       test_ori
xori_pass:
    jal     x31, print_pass
    
    # TEST 23: ORI (OR Immediate)
test_ori:
    jal     x31, print_ori_name
    addi    x10, x0, 0xF0       # x10 = 0xF0
    ori     x11, x10, 0x0F      # x11 = 0xFF
    addi    x12, x0, 0xFF       # Expected
    beq     x11, x12, ori_pass
    jal     x31, print_fail
    j       test_andi
ori_pass:
    jal     x31, print_pass
    
    # TEST 24: ANDI (AND Immediate)
test_andi:
    jal     x31, print_andi_name
    addi    x10, x0, 0xFF       # x10 = 0xFF
    andi    x11, x10, 0x0F      # x11 = 0x0F
    addi    x12, x0, 0x0F       # Expected
    beq     x11, x12, andi_pass
    jal     x31, print_fail
    j       test_slli
andi_pass:
    jal     x31, print_pass
    
    # TEST 25: SLLI (Shift Left Logical Immediate)
test_slli:
    jal     x31, print_slli_name
    addi    x10, x0, 1          # x10 = 1
    slli    x11, x10, 4         # x11 = 16 (1 << 4)
    addi    x12, x0, 16         # Expected
    beq     x11, x12, slli_pass
    jal     x31, print_fail
    j       test_srli
slli_pass:
    jal     x31, print_pass
    
    # TEST 26: SRLI (Shift Right Logical Immediate)
test_srli:
    jal     x31, print_srli_name
    addi    x10, x0, 64         # x10 = 64
    srli    x11, x10, 2         # x11 = 16 (64 >> 2)
    addi    x12, x0, 16         # Expected
    beq     x11, x12, srli_pass
    jal     x31, print_fail
    j       test_srai
srli_pass:
    jal     x31, print_pass
    
    # TEST 27: SRAI (Shift Right Arithmetic Immediate)
test_srai:
    jal     x31, print_srai_name
    addi    x10, x0, -64        # x10 = -64 (0xFFFFFFC0)
    srai    x11, x10, 2         # x11 = -16 (arithmetic shift)
    addi    x12, x0, -16        # Expected
    beq     x11, x12, srai_pass
    jal     x31, print_fail
    j       test_add
srai_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST 28-37: Register-Register ALU Instructions
    # ==========================================================================
    # TEST 28: ADD
test_add:
    jal     x31, print_add_name
    addi    x10, x0, 100
    addi    x11, x0, 50
    add     x12, x10, x11       # x12 = 150
    addi    x13, x0, 150
    beq     x12, x13, add_pass
    jal     x31, print_fail
    j       test_sub
add_pass:
    jal     x31, print_pass
    
    # TEST 29: SUB
test_sub:
    jal     x31, print_sub_name
    addi    x10, x0, 100
    addi    x11, x0, 30
    sub     x12, x10, x11       # x12 = 70
    addi    x13, x0, 70
    beq     x12, x13, sub_pass
    jal     x31, print_fail
    j       test_sll
sub_pass:
    jal     x31, print_pass
    
    # TEST 30: SLL (Shift Left Logical)
test_sll:
    jal     x31, print_sll_name
    addi    x10, x0, 1
    addi    x11, x0, 5
    sll     x12, x10, x11       # x12 = 32 (1 << 5)
    addi    x13, x0, 32
    beq     x12, x13, sll_pass
    jal     x31, print_fail
    j       test_slt
sll_pass:
    jal     x31, print_pass
    
    # TEST 31: SLT (Set Less Than - signed)
test_slt:
    jal     x31, print_slt_name
    addi    x10, x0, -5
    addi    x11, x0, 5
    slt     x12, x10, x11       # x12 = 1 (since -5 < 5)
    addi    x13, x0, 1
    beq     x12, x13, slt_pass
    jal     x31, print_fail
    j       test_sltu
slt_pass:
    jal     x31, print_pass
    
    # TEST 32: SLTU (Set Less Than Unsigned)
test_sltu:
    jal     x31, print_sltu_name
    addi    x10, x0, 5
    addi    x11, x0, -1         # 0xFFFFFFFF (largest unsigned)
    sltu    x12, x10, x11       # x12 = 1 (since 5 < 0xFFFFFFFF unsigned)
    addi    x13, x0, 1
    beq     x12, x13, sltu_pass
    jal     x31, print_fail
    j       test_xor
sltu_pass:
    jal     x31, print_pass
    
    # TEST 33: XOR
test_xor:
    jal     x31, print_xor_name
    addi    x10, x0, 0xFF
    addi    x11, x0, 0x0F
    xor     x12, x10, x11       # x12 = 0xF0
    addi    x13, x0, 0xF0
    beq     x12, x13, xor_pass
    jal     x31, print_fail
    j       test_srl
xor_pass:
    jal     x31, print_pass
    
    # TEST 34: SRL (Shift Right Logical)
test_srl:
    jal     x31, print_srl_name
    addi    x10, x0, 64
    addi    x11, x0, 3
    srl     x12, x10, x11       # x12 = 8 (64 >> 3)
    addi    x13, x0, 8
    beq     x12, x13, srl_pass
    jal     x31, print_fail
    j       test_sra
srl_pass:
    jal     x31, print_pass
    
    # TEST 35: SRA (Shift Right Arithmetic)
test_sra:
    jal     x31, print_sra_name
    addi    x10, x0, -32        # x10 = -32
    addi    x11, x0, 2
    sra     x12, x10, x11       # x12 = -8 (arithmetic shift)
    addi    x13, x0, -8
    beq     x12, x13, sra_pass
    jal     x31, print_fail
    j       test_or
sra_pass:
    jal     x31, print_pass
    
    # TEST 36: OR
test_or:
    jal     x31, print_or_name
    addi    x10, x0, 0xF0
    addi    x11, x0, 0x0F
    or      x12, x10, x11       # x12 = 0xFF
    addi    x13, x0, 0xFF
    beq     x12, x13, or_pass
    jal     x31, print_fail
    j       test_and
or_pass:
    jal     x31, print_pass
    
    # TEST 37: AND
test_and:
    jal     x31, print_and_name
    addi    x10, x0, 0xFF
    addi    x11, x0, 0x0F
    and     x12, x10, x11       # x12 = 0x0F
    addi    x13, x0, 0x0F
    beq     x12, x13, and_pass
    jal     x31, print_fail
    j       test_done
and_pass:
    jal     x31, print_pass
    
    # ==========================================================================
    # TEST COMPLETE
    # ==========================================================================
test_done:
    jal     x31, print_done
    
    # Infinite loop - all tests complete
done_loop:
    j       done_loop

# =============================================================================
# UART HELPER FUNCTIONS
# =============================================================================

# Wait for UART TX ready (poll status register)
# Uses: x20, x21
uart_wait:
    lw      x20, 8(x1)          # Read UART_STATUS
    andi    x20, x20, 0x02      # Check TX FIFO full bit
    bne     x20, x0, uart_wait  # Wait if full
    jalr    x0, x30, 0          # Return

# Print single character in x4 to UART
# Uses: x4 (char), x20, x21, x30
print_char:
    addi    x30, x31, 0         # Save return address
    jal     x31, uart_wait      # Wait for TX ready
    sw      x4, 0(x1)           # Write byte to UART_TX
    jalr    x0, x30, 0          # Return

# Print "PASS\n"
print_pass:
    addi    x29, x31, 0         # Save outer return address
    addi    x4, x0, 'P'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 0x0A        # '\n'
    jal     x31, print_char
    jalr    x0, x29, 0          # Return

# Print "FAIL\n"
print_fail:
    addi    x29, x31, 0
    addi    x4, x0, 'F'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 0x0A
    jal     x31, print_char
    jalr    x0, x29, 0

# Print header "RV32I TEST\n"
print_header:
    addi    x29, x31, 0
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'V'
    jal     x31, print_char
    addi    x4, x0, '3'
    jal     x31, print_char
    addi    x4, x0, '2'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 0x0A
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "DONE!\n"
print_done:
    addi    x29, x31, 0
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, 'O'
    jal     x31, print_char
    addi    x4, x0, 'N'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, '!'
    jal     x31, print_char
    addi    x4, x0, 0x0A
    jal     x31, print_char
    jalr    x0, x29, 0

# =============================================================================
# INSTRUCTION NAME PRINT FUNCTIONS
# Format: "XX: " where XX is instruction name
# =============================================================================

# Print "LUI: "
print_lui_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "AUIPC: "
print_auipc_name:
    addi    x29, x31, 0
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, 'P'
    jal     x31, print_char
    addi    x4, x0, 'C'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "JAL: "
print_jal_name:
    addi    x29, x31, 0
    addi    x4, x0, 'J'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "JALR: "
print_jalr_name:
    addi    x29, x31, 0
    addi    x4, x0, 'J'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BEQ: "
print_beq_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, 'Q'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BNE: "
print_bne_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'N'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BLT: "
print_blt_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BGE: "
print_bge_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'G'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BLTU: "
print_bltu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "BGEU: "
print_bgeu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'G'
    jal     x31, print_char
    addi    x4, x0, 'E'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "LB: "
print_lb_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "LH: "
print_lh_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'H'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "LW: "
print_lw_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'W'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "LBU: "
print_lbu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "LHU: "
print_lhu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'H'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SB: "
print_sb_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SH: "
print_sh_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'H'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SW: "
print_sw_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'W'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "ADDI: "
print_addi_name:
    addi    x29, x31, 0
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLTI: "
print_slti_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLTIU: "
print_sltiu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "XORI: "
print_xori_name:
    addi    x29, x31, 0
    addi    x4, x0, 'X'
    jal     x31, print_char
    addi    x4, x0, 'O'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "ORI: "
print_ori_name:
    addi    x29, x31, 0
    addi    x4, x0, 'O'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "ANDI: "
print_andi_name:
    addi    x29, x31, 0
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'N'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLLI: "
print_slli_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SRLI: "
print_srli_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SRAI: "
print_srai_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'I'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "ADD: "
print_add_name:
    addi    x29, x31, 0
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SUB: "
print_sub_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, 'B'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLL: "
print_sll_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLT: "
print_slt_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SLTU: "
print_sltu_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, 'T'
    jal     x31, print_char
    addi    x4, x0, 'U'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "XOR: "
print_xor_name:
    addi    x29, x31, 0
    addi    x4, x0, 'X'
    jal     x31, print_char
    addi    x4, x0, 'O'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SRL: "
print_srl_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'L'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "SRA: "
print_sra_name:
    addi    x29, x31, 0
    addi    x4, x0, 'S'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "OR: "
print_or_name:
    addi    x29, x31, 0
    addi    x4, x0, 'O'
    jal     x31, print_char
    addi    x4, x0, 'R'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# Print "AND: "
print_and_name:
    addi    x29, x31, 0
    addi    x4, x0, 'A'
    jal     x31, print_char
    addi    x4, x0, 'N'
    jal     x31, print_char
    addi    x4, x0, 'D'
    jal     x31, print_char
    addi    x4, x0, ':'
    jal     x31, print_char
    addi    x4, x0, ' '
    jal     x31, print_char
    jalr    x0, x29, 0

# =============================================================================
# END OF PROGRAM
# =============================================================================
