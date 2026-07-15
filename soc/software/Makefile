# Makefile for RV32I C Programs
# Assumes riscv-none-elf-gcc is in PATH

CROSS_COMPILE ?= riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32i -mabi=ilp32 -O0 -nostdlib -ffreestanding
LDFLAGS = -T link.ld -nostartfiles -Wl,--no-relax

all: program.mem

program.elf: start.S main.c link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) start.S main.c -o program.elf

program.bin: program.elf
	$(OBJCOPY) -O binary program.elf program.bin

# Convert binary to hex format using python script
program.mem: program.bin
	python make_hex.py program.bin program.mem

dump: program.elf
	$(OBJDUMP) -D program.elf > program.asm

clean:
	rm -f *.elf *.bin *.mem *.asm

.PHONY: all clean dump
