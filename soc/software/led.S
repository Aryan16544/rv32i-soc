.section .text
.global _start
_start:
    lui x1, 0x20000     # GPIO Base address (0x20000000)
loop:
    # Pattern 1: 0x5555 (alternate LEDs ON)
    # 0x5555 is 21845, which does not fit in 12-bit signed immediate.
    # We load it using LUI + ADDI or we can write it simply.
    # Let's let the assembler handle "li x2, 0x5555" (it expands to LUI + ADDI)
    li x2, 0x5555
    sw x2, 0(x1)        # Write to GPIO

    # Delay loop (approx 1 million iterations)
    li x3, 1000000
delay1:
    addi x3, x3, -1
    bne x3, x0, delay1

    # Pattern 2: 0xAAAA (other alternate LEDs ON)
    li x2, 0xAAAA
    sw x2, 0(x1)        # Write to GPIO

    # Delay loop (approx 1 million iterations)
    li x3, 1000000
delay2:
    addi x3, x3, -1
    bne x3, x0, delay2

    jal x0, loop        # Infinite loop
