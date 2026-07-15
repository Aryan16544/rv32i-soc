.section .text
.global _start
_start:
    lui x1, 0x20000     # GPIO Base Address (0x20000000)
loop:
    lw x2, 0(x1)        # Read Switches from offset 0
    sw x2, 4(x1)        # Write to LEDs at offset 4
    jal x0, loop        # Repeat forever
