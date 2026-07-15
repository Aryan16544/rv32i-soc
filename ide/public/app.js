/* ═══════════════════════════════════════════════════════════════
   RV32I SoC IDE — Frontend Application Logic
   ═══════════════════════════════════════════════════════════════ */

// ── State ─────────────────────────────────────────────────────────────────────
const state = {
  hexData: null,
  disasm:  null,
  symbols: null,
  lastBuildOk: false,
};

// ── Peripheral macro snippets ──────────────────────────────────────────────────
const PERIPH_SNIPPETS = {
  BOOT_ROM: `// Boot ROM – 0x0000_0000 (4 KB, Read/Execute)
#define BOOT_ROM_BASE  0x00000000
`,
  MAIN_RAM: `// Main RAM – 0x1000_0000 (64 KB, Read/Write/Execute)
#define MAIN_RAM_BASE  0x10000000
`,
  GPIO: `// GPIO – 0x2000_0000
#define GPIO_BASE   0x20000000
#define GPIO_OUT  (*(volatile uint32_t *)(GPIO_BASE + 0x04))  // Write → LEDs
#define GPIO_IN   (*(volatile uint32_t *)(GPIO_BASE + 0x00))  // Read  → Switches
`,
  UART: `// UART – 0x3000_0000 (115200 baud)
#define UART_BASE     0x30000000
#define UART_TX     (*(volatile uint32_t *)(UART_BASE + 0x00))  // Write → Transmit
#define UART_RX     (*(volatile uint32_t *)(UART_BASE + 0x04))  // Read  → Receive
#define UART_STAT   (*(volatile uint32_t *)(UART_BASE + 0x08))  // Bit0=RX_VALID Bit1=TX_FULL
#define UART_TX_FULL  0x02
#define UART_RX_VALID 0x01
`,
  TIMER: `// Timer – 0x4000_0000
#define TIMER_BASE    0x40000000
#define TIMER_MTIME_LO    (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define TIMER_MTIME_HI    (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define TIMER_MTIMECMP_LO (*(volatile uint32_t *)(TIMER_BASE + 0x08))
#define TIMER_MTIMECMP_HI (*(volatile uint32_t *)(TIMER_BASE + 0x0C))
`,
};

// ── INIT ──────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  updateLineNumbers();
  await checkToolchain();
  await loadExamples();
  loadDefaultCode();
});

// ── Toolchain check ───────────────────────────────────────────────────────────
async function checkToolchain() {
  const badge = document.getElementById('toolchain-badge');
  const text  = document.getElementById('toolchain-text');
  try {
    const r = await fetch('/api/toolchain');
    const d = await r.json();
    if (d.available) {
      badge.className = 'badge badge-ok';
      text.textContent = d.version.substring(0, 40);
    } else {
      badge.className = 'badge badge-error';
      text.textContent = 'Toolchain not found!';
    }
  } catch(e) {
    badge.className = 'badge badge-error';
    text.textContent = 'Server offline';
  }
}

// ── Load examples ─────────────────────────────────────────────────────────────
async function loadExamples() {
  try {
    const r = await fetch('/api/examples');
    const d = await r.json();
    const list = document.getElementById('examples-list');
    list.innerHTML = '';
    d.examples.forEach(ex => {
      const el = document.createElement('div');
      el.className = 'example-item';
      el.innerHTML = `
        <div class="example-item-name">${ex.name}</div>
        <div class="example-item-desc">${ex.description}</div>
      `;
      el.onclick = () => loadExample(ex);
      list.appendChild(el);
    });
  } catch(e) {}
}

function loadExample(ex) {
  document.getElementById('code-editor').value = ex.code;
  updateLineNumbers();
  showToast(`Loaded: ${ex.name}`, 'success');
}

// ── Default code ──────────────────────────────────────────────────────────────
function loadDefaultCode() {
  const saved = localStorage.getItem('rv32i_code');
  if (saved) {
    document.getElementById('code-editor').value = saved;
    updateLineNumbers();
    return;
  }
  document.getElementById('code-editor').value = `#include <stdint.h>

// ═══════════════════════════════════════════════════════════
//  RV32I SoC — C to HEX Demo Program
//  Target: riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32
// ═══════════════════════════════════════════════════════════

// ── Peripheral Base Addresses (from soc_map.vh) ──────────────
#define UART_BASE    0x30000000
#define UART_TX    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STAT  (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_TX_FULL  0x02

#define GPIO_BASE    0x20000000
#define GPIO_IN    (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_OUT   (*(volatile uint32_t *)(GPIO_BASE + 0x04))

// ── Helper functions ─────────────────────────────────────────
void uart_putc(char c) {
    while (UART_STAT & UART_TX_FULL);
    UART_TX = c;
}

void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

void delay(volatile int n) {
    while (n--);
}

// ── Main ─────────────────────────────────────────────────────
int main() {
    uart_puts("Hello from RV32I SoC!\\r\\n");

    uint32_t count = 0;
    while (1) {
        GPIO_OUT = count++;
        delay(500000);
    }
    return 0;
}
`;
  updateLineNumbers();
}

// ── View switching ────────────────────────────────────────────────────────────
function switchView(name) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
  document.getElementById(`view-${name}`).classList.add('active');
  document.getElementById(`btn-${name}`).classList.add('active');
}

// ── Editor ────────────────────────────────────────────────────────────────────
function onEditorInput() {
  updateLineNumbers();
  const code = document.getElementById('code-editor').value;
  localStorage.setItem('rv32i_code', code);
}

function updateLineNumbers() {
  const ta   = document.getElementById('code-editor');
  const ln   = document.getElementById('line-numbers');
  const lines = ta.value.split('\n').length;
  let nums = '';
  for (let i = 1; i <= lines; i++) nums += i + '\n';
  ln.textContent = nums;
}

function syncScroll() {
  const ta = document.getElementById('code-editor');
  const ln = document.getElementById('line-numbers');
  ln.scrollTop = ta.scrollTop;
}

function handleEditorKey(e) {
  if (e.key === 'Tab') {
    e.preventDefault();
    const ta = document.getElementById('code-editor');
    const s  = ta.selectionStart;
    const v  = ta.value;
    ta.value = v.substring(0, s) + '    ' + v.substring(ta.selectionEnd);
    ta.selectionStart = ta.selectionEnd = s + 4;
    updateLineNumbers();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    e.preventDefault();
    compile();
  }
}

function clearEditor() {
  if (confirm('Clear the editor?')) {
    document.getElementById('code-editor').value = '';
    updateLineNumbers();
  }
}

function formatCode() {
  showToast('Auto-format requires clang-format (not included). Code unchanged.', 'info');
}

function toggleStartS() {
  const p = document.getElementById('start-panel');
  p.classList.toggle('hidden');
  const tabs = document.querySelectorAll('.editor-tab');
  tabs[1].classList.toggle('active');
  tabs[0].classList.toggle('active', p.classList.contains('hidden'));
}

// ── Insert peripheral snippet ─────────────────────────────────────────────────
function insertPeripheral(name) {
  const snippet = PERIPH_SNIPPETS[name];
  if (!snippet) return;
  const ta = document.getElementById('code-editor');
  const s  = ta.selectionStart;
  const v  = ta.value;
  ta.value = v.substring(0, s) + snippet + v.substring(s);
  ta.selectionStart = ta.selectionEnd = s + snippet.length;
  ta.focus();
  updateLineNumbers();
  showToast(`Inserted ${name} address macros`, 'success');
}

// ── COMPILE ───────────────────────────────────────────────────────────────────
async function compile() {
  const code = document.getElementById('code-editor').value.trim();
  if (!code) { showToast('Editor is empty!', 'error'); return; }

  const arch    = document.getElementById('sel-arch').value;
  const opt     = document.getElementById('sel-opt').value;
  const startS  = document.getElementById('start-editor').value;

  // Show loading
  showLoading(true);
  document.getElementById('btn-compile').disabled = true;

  // Animate steps
  animateSteps();

  let result;
  try {
    const resp = await fetch('/api/compile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code, startS, arch, abi: 'ilp32', optimize: opt })
    });
    result = await resp.json();
  } catch(e) {
    showLoading(false);
    document.getElementById('btn-compile').disabled = false;
    showToast('Cannot reach server!', 'error');
    return;
  }

  showLoading(false);
  document.getElementById('btn-compile').disabled = false;

  // Update log
  showLog(result);

  if (result.success) {
    state.hexData = result;
    state.disasm  = result.disassembly;
    state.lastBuildOk = true;

    // Update stats
    document.getElementById('stat-status').textContent = '✓ OK';
    document.getElementById('stat-status').style.color = 'var(--green)';
    document.getElementById('stat-words').textContent  = result.word_count;
    document.getElementById('stat-bytes').textContent  = result.byte_count + ' B';
    document.getElementById('stat-arch').textContent   = arch;

    // Populate hex view
    populateHexView(result);
    populateAsmView(result.disassembly);

    showToast(`✓ Compiled! ${result.word_count} words (${result.byte_count} bytes)`, 'success');
    switchView('hex');
  } else {
    state.lastBuildOk = false;
    document.getElementById('stat-status').textContent = '✗ Error';
    document.getElementById('stat-status').style.color = 'var(--red)';
    showToast('Build failed — see log below', 'error');
  }
}

// ── Loading animation ─────────────────────────────────────────────────────────
let stepTimer = null;
function animateSteps() {
  const steps = ['step1','step2','step3','step4'];
  const icons = ['⚙️','📦','🔄','🔍'];
  steps.forEach(id => {
    const el = document.getElementById(id);
    el.className = 'step';
    el.querySelector('.step-icon').textContent = '⟳';
  });
  let i = 0;
  stepTimer = setInterval(() => {
    if (i > 0) {
      const prev = document.getElementById(steps[i-1]);
      prev.className = 'step done';
      prev.querySelector('.step-icon').textContent = '✓';
    }
    if (i < steps.length) {
      const cur = document.getElementById(steps[i]);
      cur.className = 'step active';
      cur.querySelector('.step-icon').textContent = icons[i];
    }
    i++;
    if (i >= steps.length + 1) {
      clearInterval(stepTimer);
    }
  }, 400);
}

function showLoading(visible) {
  const el = document.getElementById('loading-overlay');
  el.classList.toggle('hidden', !visible);
  if (!visible && stepTimer) clearInterval(stepTimer);
}

// ── Compile log ───────────────────────────────────────────────────────────────
function showLog(result) {
  const log   = document.getElementById('compile-log');
  const title = document.getElementById('log-title');
  const pre   = document.getElementById('log-content');
  log.classList.remove('hidden');

  if (result.success) {
    title.textContent = '✓ Build Successful';
    title.style.color = 'var(--green)';
    let txt = result.compile_log || 'Compiled OK.';
    if (result.size_info) txt += '\n' + result.size_info;
    pre.textContent = txt;
    pre.className = 'log-success';
  } else {
    title.textContent = '✗ Build Failed';
    title.style.color = 'var(--red)';
    pre.textContent = result.error + '\n' + (result.compile_log || '');
    pre.className = 'log-error';
  }
}

function closeLog() {
  document.getElementById('compile-log').classList.add('hidden');
}

// ── HEX VIEW ─────────────────────────────────────────────────────────────────
function populateHexView(result) {
  document.getElementById('hex-no-data').classList.add('hidden');
  document.getElementById('hex-output-wrap').classList.remove('hidden');
  document.getElementById('hex-raw').value = result.hex_content;
  renderHexTable();
}

function renderHexTable() {
  if (!state.hexData) return;
  const showBin  = document.getElementById('chk-show-bin').checked;
  const showAddr = document.getElementById('chk-show-addr').checked;
  const thead = document.getElementById('hex-thead');
  const tbody = document.getElementById('hex-tbody');

  // Header
  thead.innerHTML = '<th>Word #</th>';
  if (showAddr) thead.innerHTML += '<th>Address</th>';
  thead.innerHTML += '<th>HEX (32-bit)</th>';
  if (showBin)  thead.innerHTML += '<th>Binary</th>';

  // Rows
  tbody.innerHTML = '';
  state.hexData.hex_table.forEach((row, i) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td class="hex-num">${i}</td>`;
    if (showAddr) tr.innerHTML += `<td class="hex-addr">${row.addr}</td>`;
    tr.innerHTML += `<td class="hex-word">${row.hex}</td>`;
    if (showBin) {
      // Show binary with colour groups of 4 bits
      const bins = row.bin.match(/.{1,4}/g).join(' ');
      tr.innerHTML += `<td class="hex-bin">${bins}</td>`;
    }
    tbody.appendChild(tr);
  });
}

function filterHexTable() {
  const q = document.getElementById('hex-search').value.toLowerCase();
  document.querySelectorAll('#hex-tbody tr').forEach(tr => {
    tr.classList.remove('hex-highlighted');
    const text = tr.textContent.toLowerCase();
    if (q && text.includes(q)) {
      tr.classList.add('hex-highlighted');
      tr.style.display = '';
    } else if (q) {
      tr.style.display = '';  // keep all visible but highlight matches
    } else {
      tr.style.display = '';
    }
  });
}

// ── DISASSEMBLY VIEW ──────────────────────────────────────────────────────────
function populateAsmView(asm) {
  const el = document.getElementById('asm-output');
  const nd = document.getElementById('asm-no-data');
  if (!asm) { nd.classList.remove('hidden'); el.classList.add('hidden'); return; }
  nd.classList.add('hidden');
  el.classList.remove('hidden');
  el.innerHTML = colorizeAsm(asm);
}

function colorizeAsm(text) {
  // Simple RISC-V disasm colorizer
  return text
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .split('\n').map(line => {
      // Section headers
      if (/^Disassembly/.test(line))
        return `<span style="color:#a5b4fc;font-weight:700">${line}</span>`;
      // Symbol labels like <main>:
      if (/^\w+ &lt;[\w.@]+&gt;:/.test(line))
        return `<span style="color:#22d3a0;font-weight:600">${line}</span>`;
      // Instruction lines (addr: hex   mnem)
      if (/^\s+[0-9a-f]+:/.test(line)) {
        return line.replace(
          /^(\s+)([0-9a-f]+:)(\s+)([0-9a-f ]{8,}?)(\s+)(\w+)(.*)/,
          (_, sp, addr, ws1, hex, ws2, mnem, rest) =>
            `${sp}<span style="color:#6b7280">${addr}</span>${ws1}` +
            `<span style="color:#374151">${hex}</span>${ws2}` +
            `<span style="color:#fbbf24;font-weight:500">${mnem}</span>` +
            `<span style="color:#d1d5db">${rest}</span>`
        );
      }
      return `<span style="color:#4b5563">${line}</span>`;
    }).join('\n');
}

function filterAsm() {
  const q = document.getElementById('asm-search').value.toLowerCase();
  if (!state.disasm) return;
  if (!q) { populateAsmView(state.disasm); return; }
  const filtered = state.disasm.split('\n')
    .filter(l => l.toLowerCase().includes(q))
    .join('\n');
  document.getElementById('asm-output').innerHTML = colorizeAsm(filtered);
}

// ── Save / Download ───────────────────────────────────────────────────────────
async function saveFile() {
  const code = document.getElementById('code-editor').value;
  let fname = prompt('Save as:', 'main.c');
  if (!fname) return;
  try {
    const r = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ filename: fname, code })
    });
    const d = await r.json();
    if (d.success) showToast(`Saved to: ${d.path}`, 'success');
    else showToast('Save failed!', 'error');
  } catch(e) {
    showToast('Cannot reach server!', 'error');
  }
}

function downloadHex() {
  if (!state.hexData) { showToast('Compile first!', 'error'); return; }
  download('program.mem', state.hexData.hex_content);
}

function downloadDisasm() {
  if (!state.disasm) { showToast('Compile first!', 'error'); return; }
  download('program.asm', state.disasm);
}

function download(fname, content) {
  const a = document.createElement('a');
  a.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent(content);
  a.download = fname;
  a.click();
}

// ── Toast ─────────────────────────────────────────────────────────────────────
let toastTimer;
function showToast(msg, type = 'info') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className   = `toast toast-${type}`;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.className = 'toast hidden'; }, 3500);
}
