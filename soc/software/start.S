.section .text.init
.global _start

_start:
    /* Initialize Stack Pointer to top of RAM (64KB at 0x10000000) */
    /* RAM Base: 0x10000000, Size: 0x10000 => End: 0x10010000 */
    lui sp, 0x10010
    
    /* Jump to main C function */
    call main

    /* Infinite loop if main returns */
loop:
    j loop
