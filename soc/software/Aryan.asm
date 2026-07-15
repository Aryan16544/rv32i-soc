
Aryan.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_start>:
   0:	10010137          	lui	sp,0x10010
   4:	00000097          	auipc	ra,0x0
   8:	054080e7          	jalr	84(ra) # 58 <main>

0000000c <loop>:
   c:	0000006f          	j	c <loop>

00000010 <uart_send>:
  10:	fe010113          	addi	sp,sp,-32 # 1000ffe0 <_edata+0xffe0>
  14:	00812e23          	sw	s0,28(sp)
  18:	02010413          	addi	s0,sp,32
  1c:	00050793          	mv	a5,a0
  20:	fef407a3          	sb	a5,-17(s0)
  24:	00000013          	nop
  28:	300007b7          	lui	a5,0x30000
  2c:	00878793          	addi	a5,a5,8 # 30000008 <_edata+0x20000008>
  30:	0007a783          	lw	a5,0(a5)
  34:	0027f793          	andi	a5,a5,2
  38:	fe0788e3          	beqz	a5,28 <uart_send+0x18>
  3c:	300007b7          	lui	a5,0x30000
  40:	fef44703          	lbu	a4,-17(s0)
  44:	00e7a023          	sw	a4,0(a5) # 30000000 <_edata+0x20000000>
  48:	00000013          	nop
  4c:	01c12403          	lw	s0,28(sp)
  50:	02010113          	addi	sp,sp,32
  54:	00008067          	ret

00000058 <main>:
  58:	ff010113          	addi	sp,sp,-16
  5c:	00112623          	sw	ra,12(sp)
  60:	00812423          	sw	s0,8(sp)
  64:	01010413          	addi	s0,sp,16
  68:	04100513          	li	a0,65
  6c:	00000097          	auipc	ra,0x0
  70:	fa4080e7          	jalr	-92(ra) # 10 <uart_send>
  74:	07200513          	li	a0,114
  78:	00000097          	auipc	ra,0x0
  7c:	f98080e7          	jalr	-104(ra) # 10 <uart_send>
  80:	07900513          	li	a0,121
  84:	00000097          	auipc	ra,0x0
  88:	f8c080e7          	jalr	-116(ra) # 10 <uart_send>
  8c:	06100513          	li	a0,97
  90:	00000097          	auipc	ra,0x0
  94:	f80080e7          	jalr	-128(ra) # 10 <uart_send>
  98:	06e00513          	li	a0,110
  9c:	00000097          	auipc	ra,0x0
  a0:	f74080e7          	jalr	-140(ra) # 10 <uart_send>
  a4:	00d00513          	li	a0,13
  a8:	00000097          	auipc	ra,0x0
  ac:	f68080e7          	jalr	-152(ra) # 10 <uart_send>
  b0:	00a00513          	li	a0,10
  b4:	00000097          	auipc	ra,0x0
  b8:	f5c080e7          	jalr	-164(ra) # 10 <uart_send>
  bc:	00000793          	li	a5,0
  c0:	00078513          	mv	a0,a5
  c4:	00c12083          	lw	ra,12(sp)
  c8:	00812403          	lw	s0,8(sp)
  cc:	01010113          	addi	sp,sp,16
  d0:	00008067          	ret
	...
