# 📖 Getting Started: Software and Hardware Workflow

This guide explains how to compile bare-metal C programs for the **RV32I SoC**, run behavioral simulation, and synthesize the design onto a Xilinx 7-Series FPGA.

---

## 🛠️ 1. Software Development Workflow

The CPU boots from the instruction memory (Boot ROM) mapped at `0x0000_0000`. To run custom C programs, they must be compiled into a `.mem` format (hexadecimal text file) so Vivado or the simulator can load it.

### A. The Startup File (`start.S`)
Because there is no operating system (bare-metal), execution starts at address `0x0000_0000` inside `soc/software/start.S`:
1. It initializes the **Stack Pointer (`sp`)** to the top of the RAM memory: `0x1001_0000` (base `0x1000_0000` + 64 KB RAM size).
2. It jumps (`call`) to the C entrypoint function `main()`.
3. If `main()` ever returns, the CPU sits in an infinite loop.

### B. Linker Script (`link.ld`)
The linker script maps out where functions and variables go:
* `.text` (compiled code) starts at `0x0000_0000` (Instruction BRAM).
* `.data` and `.bss` (variables and stack) go to `0x1000_0000` (Data BRAM).

### C. Compiling the Code
To compile the C source files:
1. Ensure the `riscv64-unknown-elf-` toolchain is in your system path.
2. Open a terminal in `soc/software/` and run:
   ```bash
   make
   ```
This Makefile will run the following steps:
1. Compile and link `start.S` and `main.c` into an executable ELF:
   ```bash
   riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O0 -nostdlib -ffreestanding -T link.ld -nostartfiles -Wl,--no-relax start.S main.c -o program.elf
   ```
2. Extract the raw binary image:
   ```bash
   riscv64-unknown-elf-objcopy -O binary program.elf program.bin
   ```
3. Convert the binary to the Vivado Block RAM compatible `.mem` hex format:
   ```bash
   python make_hex.py program.bin program.mem
   ```

---

## 🖥️ 2. Browser-Based Web IDE Compiler
If you do not have the RISC-V GCC toolchain installed locally, you can use the built-in browser-based editor and compiler:

1. Navigate to the `ide/` directory.
2. Install node dependencies:
   ```bash
   npm install
   ```
3. Start the local server:
   ```bash
   node server.js
   ```
4. Open your browser to `http://localhost:3000`. You can write C code directly in the code editor, compile it, and download the output `program.mem` file!

---

## 🔬 3. Hardware Simulation Workflow

We verify the design using Vivado's built-in simulation tools.

### Step 1: Recreate the Vivado Project
Rather than checking in heavy cache folders, you can rebuild a clean Vivado project by running:
```powershell
vivado -mode batch -source scripts/create_vivado_project.tcl
```
This automatically links the source RTL from `core/`, `soc/`, and `peripherals/`, and stages `soc/software/hello.mem` as your default system program.

### Step 2: Open and Run Simulation
1. Launch Vivado and open `build/vivado/rv32i_soc.xpr`.
2. In the Vivado Tcl Console, load the simulation environment:
   ```tcl
   source setup_sim.tcl
   ```
3. Run simulation. The top-level testbench (`rv32i_soc_full_tb.v`) will automatically run a comprehensive automated check covering all 37 instruction types.

---

## 🔌 4. FPGA Synthesis and Hardware Bring-Up

### Board Target
The project targets the **Urbana Artix-7 Board** (`xc7a12tcpg238-1`). If you are using a different Artix-7 or Nexys board, change the `-part` flag in `scripts/create_vivado_project.tcl`.

### Step-by-Step Synthesis:
1. In Vivado, click **Run Synthesis** and then **Run Implementation**.
2. Click **Generate Bitstream** to compile the Verilog into a `.bit` file.
3. Open the **Hardware Manager**, connect to your board, and program it.

### Debug Indicators (Onboard LEDs):
* **`LED[15]` (Heartbeat)**: Flashes periodically (driven by a high-frequency divider clock counter), proving the 100MHz clock input is alive.
* **`LED[14]` (Clock Locked)**: Stays ON to confirm the system clock is stable.
* **`LED[13]` (Reset Synced)**: Stays ON when the CPU reset is released.
* **`LED[12:0]`**: Display the current status of the CPU GPIO outputs.
