.section .text
.global _start
_start:
    lui x1, 0x30000     # UART Base address (0x30000000)

outer_loop:
    li x2, 0x41         # ASCII 'A'
    li x3, 0x5B         # ASCII 'Z' + 1 = 91 (0x5B)

char_loop:
    # Wait for UART ready (status bit 1 = TX FULL)
wait_ready:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_ready

    sw x2, 0(x1)        # Send character

    # Move to next character
    addi x2, x2, 1
    bne x2, x3, char_loop

    # Send CR ('\r')
wait_cr:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_cr
    li x4, 0x0D
    sw x4, 0(x1)

    # Send LF ('\n')
wait_lf:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_lf
    li x4, 0x0A
    sw x4, 0(x1)

    # Long delay between repeats (approx 2 million iterations)
    li x4, 2000000
delay_loop:
    addi x4, x4, -1
    bne x4, x0, delay_loop

    jal x0, outer_loop  # Repeat printing A-Z
