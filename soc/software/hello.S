.section .text
.global _start
_start:
    lui x1, 0x30000     # UART Base address

    # 'H'
    li x2, 0x48
wait_H:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_H
    sw x2, 0(x1)

    # 'e'
    li x2, 0x65
wait_e:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_e
    sw x2, 0(x1)

    # 'l'
    li x2, 0x6C
wait_l1:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_l1
    sw x2, 0(x1)

    # 'l'
    li x2, 0x6C
wait_l2:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_l2
    sw x2, 0(x1)

    # 'o'
    li x2, 0x6F
wait_o:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_o
    sw x2, 0(x1)

    # ','
    li x2, 0x2C
wait_comma:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_comma
    sw x2, 0(x1)

    # ' '
    li x2, 0x20
wait_space:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_space
    sw x2, 0(x1)

    # 'W'
    li x2, 0x57
wait_W:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_W
    sw x2, 0(x1)

    # 'o'
    li x2, 0x6F
wait_o2:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_o2
    sw x2, 0(x1)

    # 'r'
    li x2, 0x72
wait_r:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_r
    sw x2, 0(x1)

    # 'l'
    li x2, 0x6C
wait_l3:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_l3
    sw x2, 0(x1)

    # 'd'
    li x2, 0x64
wait_d:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_d
    sw x2, 0(x1)

    # '!'
    li x2, 0x21
wait_excl:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_excl
    sw x2, 0(x1)

    # '\r'
    li x2, 0x0D
wait_cr:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_cr
    sw x2, 0(x1)

    # '\n'
    li x2, 0x0A
wait_lf:
    lw x5, 8(x1)
    andi x5, x5, 2
    bne x5, x0, wait_lf
    sw x2, 0(x1)

    # Infinite Loop
done:
    jal x0, done
