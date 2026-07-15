OUTPUT_ARCH( "riscv" )

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
  .text :
  {
    *(.text.init)   /* Start code must be first */
    *(.text)        /* Remaining code */
    *(.text.*)
  } > ROM

  .rodata :
  {
    *(.rodata)
    *(.rodata.*)
  } > ROM

  /* Initialized data */
  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
    . = ALIGN(4);
    _edata = .;
  } > RAM AT > ROM
  /* Note: Real startup code copies .data from ROM to RAM. 
     For simple programs we skip this if no initialized globals used. */

  /* Uninitialized data */
  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
    . = ALIGN(4);
    _ebss = .;
  } > RAM
}
