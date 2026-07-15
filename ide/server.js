const express = require('express');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const TOOLCHAIN_PREFIX = 'riscv64-unknown-elf-';
const GCC     = `${TOOLCHAIN_PREFIX}gcc`;
const OBJCOPY = `${TOOLCHAIN_PREFIX}objcopy`;
const OBJDUMP = `${TOOLCHAIN_PREFIX}objdump`;
const SIZE    = `${TOOLCHAIN_PREFIX}size`;

const LINKER_SCRIPT = path.join(__dirname, '..', 'soc', 'software', 'link.ld');

// ─── Pure Node.js: binary → .mem hex (replaces make_hex.py, no Python needed) ─
function binToMem(binFile, memFile) {
  let data = fs.readFileSync(binFile);
  // Pad to 4-byte boundary
  while (data.length % 4 !== 0) {
    data = Buffer.concat([data, Buffer.from([0x00])]);
  }
  const lines = [];
  for (let i = 0; i < data.length; i += 4) {
    const val = data.readUInt32LE(i);
    lines.push(val.toString(16).padStart(8, '0'));
  }
  fs.writeFileSync(memFile, lines.join('\n') + '\n');
  return lines.length;
}

// ─── POST /api/compile ────────────────────────────────────────────────────────
app.post('/api/compile', (req, res) => {
  const { code, startS, arch = 'rv32i', abi = 'ilp32', optimize = 'O0' } = req.body;
  if (!code) return res.status(400).json({ success: false, error: 'No C code provided.' });

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'rv32i_'));
  const cFile  = path.join(tmpDir, 'main.c');
  const sFile  = path.join(tmpDir, 'start.S');
  const elfFile = path.join(tmpDir, 'program.elf');
  const binFile = path.join(tmpDir, 'program.bin');
  const memFile = path.join(tmpDir, 'program.mem');
  const asmFile = path.join(tmpDir, 'program.asm');

  try {
    fs.writeFileSync(cFile, code);

    // Write start.S (use custom or default)
    const startContent = startS || `.section .text.init
.global _start
_start:
    lui sp, 0x10010
    call main
loop:
    j loop
`;
    fs.writeFileSync(sFile, startContent);

    const cflags  = `-march=${arch} -mabi=${abi} -${optimize} -nostdlib -ffreestanding`;
    const ldflags = `-T "${LINKER_SCRIPT}" -nostartfiles -Wl,--no-relax`;

    // Step 1: Compile
    const compileCmd = `"${GCC}" ${cflags} ${ldflags} "${sFile}" "${cFile}" -o "${elfFile}" 2>&1`;
    let compileLog = '';
    try {
      compileLog = execSync(compileCmd, { env: { ...process.env }, timeout: 30000 }).toString();
    } catch (e) {
      const errText = e.stdout ? e.stdout.toString() : e.message;
      return res.json({
        success: false,
        error: 'Compilation failed',
        compile_log: errText,
        stage: 'compile'
      });
    }

    // Step 2: objcopy → binary
    const objcopyCmd = `"${OBJCOPY}" -O binary "${elfFile}" "${binFile}"`;
    execSync(objcopyCmd, { timeout: 10000 });

    // Step 3: binary → .mem hex (pure Node.js, no Python needed)
    binToMem(binFile, memFile);

    // Step 4: Disassembly
    const dumpCmd = `"${OBJDUMP}" -d -S "${elfFile}" 2>&1`;
    let disasm = '';
    try { disasm = execSync(dumpCmd, { timeout: 10000 }).toString(); } catch(e) { disasm = ''; }

    // Step 5: Symbol table
    const nmCmd = `"${TOOLCHAIN_PREFIX}nm" -n "${elfFile}" 2>&1`;
    let symbols = '';
    try { symbols = execSync(nmCmd, { timeout: 5000 }).toString(); } catch(e) { symbols = ''; }

    // Step 6: Size
    const sizeCmd = `"${SIZE}" "${elfFile}" 2>&1`;
    let sizeInfo = '';
    try { sizeInfo = execSync(sizeCmd, { timeout: 5000 }).toString(); } catch(e) { sizeInfo = ''; }

    // Read outputs
    const hexContent = fs.readFileSync(memFile, 'utf-8');
    const binBytes   = fs.readFileSync(binFile);

    // Build hex table
    const hexLines = hexContent.trim().split('\n');
    const hexTable = hexLines.map((line, i) => ({
      addr: `0x${(i * 4).toString(16).padStart(8, '0')}`,
      hex:  line.trim(),
      bin:  parseInt(line.trim(), 16).toString(2).padStart(32, '0')
    }));

    // Clean up
    fs.rmSync(tmpDir, { recursive: true });

    res.json({
      success: true,
      compile_log: compileLog || 'Compiled successfully.',
      hex_content: hexContent,
      hex_table: hexTable,
      disassembly: disasm,
      symbols: symbols,
      size_info: sizeInfo,
      byte_count: binBytes.length,
      word_count: hexLines.length
    });

  } catch (err) {
    try { fs.rmSync(tmpDir, { recursive: true }); } catch(_) {}
    res.json({ success: false, error: err.message, stage: 'unknown' });
  }
});

// ─── GET /api/toolchain ───────────────────────────────────────────────────────
app.get('/api/toolchain', (req, res) => {
  try {
    const ver = execSync(`"${GCC}" --version 2>&1`, { timeout: 5000 }).toString().split('\n')[0];
    res.json({ available: true, version: ver, prefix: TOOLCHAIN_PREFIX });
  } catch(e) {
    res.json({ available: false, error: e.message });
  }
});

// ─── GET /api/examples ───────────────────────────────────────────────────────
app.get('/api/examples', (req, res) => {
  res.json({ examples: EXAMPLES });
});

// ─── POST /api/save ──────────────────────────────────────────────────────────
app.post('/api/save', (req, res) => {
  const { filename, code } = req.body;
  if (!filename || !code) return res.status(400).json({ success: false });
  const safeName = path.basename(filename).replace(/[^a-zA-Z0-9_.-]/g, '_');
  const savePath = path.join(__dirname, '..', 'soc', 'software', safeName.endsWith('.c') ? safeName : safeName + '.c');
  fs.writeFileSync(savePath, code);
  res.json({ success: true, path: savePath });
});

// ─── Example programs ────────────────────────────────────────────────────────
const EXAMPLES = [
  {
    name: 'LED Blink (GPIO)',
    description: 'Blink all LEDs using GPIO peripheral',
    code: `#include <stdint.h>

// ── SoC Peripheral Addresses ──────────────────────────────────────────────
#define GPIO_BASE   0x20000000
#define GPIO_IN   (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OUT  (*(volatile uint32_t *)(GPIO_BASE + 0x04))

void delay(volatile int n) {
    while(n--);
}

int main() {
    uint32_t pattern = 0xAAAA;
    while(1) {
        GPIO_OUT = pattern;
        delay(500000);
        GPIO_OUT = ~pattern;
        delay(500000);
    }
    return 0;
}`
  },
  {
    name: 'UART Hello World',
    description: 'Print Hello World over UART',
    code: `#include <stdint.h>

// ── SoC Peripheral Addresses ──────────────────────────────────────────────
#define UART_BASE    0x30000000
#define UART_TX    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STAT  (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_TX_FULL  0x02

void uart_putc(char c) {
    while (UART_STAT & UART_TX_FULL);
    UART_TX = c;
}

void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

int main() {
    uart_puts("Hello from RV32I SoC!\\r\\n");
    uart_puts("UART is working.\\r\\n");
    while(1);
    return 0;
}`
  },
  {
    name: 'Timer Counter',
    description: 'Read the free-running timer and mirror it to LEDs',
    code: `#include <stdint.h>

// ── SoC Peripheral Addresses ──────────────────────────────────────────────
#define TIMER_BASE     0x40000000
#define TIMER_MTIME_LO     (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define TIMER_MTIME_HI     (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define TIMER_MTIMECMP_LO  (*(volatile uint32_t *)(TIMER_BASE + 0x08))
#define TIMER_MTIMECMP_HI  (*(volatile uint32_t *)(TIMER_BASE + 0x0C))

#define GPIO_BASE    0x20000000
#define GPIO_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x04))

int main() {
    while(1) {
        GPIO_OUT = TIMER_MTIME_LO;
    }
    return 0;
}`
  },
  {
    name: 'GPIO + UART Monitor',
    description: 'Read switches and print status over UART',
    code: `#include <stdint.h>

// ── SoC Peripheral Addresses ──────────────────────────────────────────────
#define UART_BASE    0x30000000
#define UART_TX    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STAT  (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_TX_FULL  0x02

#define GPIO_BASE    0x20000000
#define GPIO_IN    (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x04))

void uart_putc(char c) {
    while (UART_STAT & UART_TX_FULL);
    UART_TX = c;
}

void uart_puts(const char *s) { while(*s) uart_putc(*s++); }

void uart_puthex(uint32_t v) {
    uart_puts("0x");
    for(int i=28; i>=0; i-=4) {
        uint8_t nib = (v >> i) & 0xF;
        uart_putc(nib < 10 ? '0'+nib : 'A'+(nib-10));
    }
}

void delay(volatile int n) { while(n--); }

int main() {
    uart_puts("RV32I GPIO Monitor\\r\\n");
    uint32_t prev = 0xDEAD;
    while(1) {
        uint32_t sw = GPIO_IN;
        if (sw != prev) {
            uart_puts("GPIO_IN = ");
            uart_puthex(sw);
            uart_puts("\\r\\n");
            GPIO_OUT = sw;
            prev = sw;
        }
        delay(10000);
    }
    return 0;
}`
  }
];

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n  ╔══════════════════════════════════════╗`);
  console.log(`  ║   RV32I SoC IDE  –  Server Running   ║`);
  console.log(`  ╠══════════════════════════════════════╣`);
  console.log(`  ║  http://localhost:${PORT}                 ║`);
  console.log(`  ╚══════════════════════════════════════╝\n`);
});
