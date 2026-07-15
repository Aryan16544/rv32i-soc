# Contributing to RV32I RISC-V SoC

Thank you for your interest in contributing! This project welcomes improvements to the RTL design, bare-metal software, documentation, and CI tooling.

---

## Ways to Contribute

| Type | Examples |
|:---|:---|
| 🐛 **Bug fix** | Fix a pipeline hazard edge case, incorrect register behavior |
| ✨ **New feature** | Add SPI, I2C peripheral, interrupt controller, CSR registers |
| 📖 **Documentation** | Improve README, add timing diagrams, annotate RTL |
| 🧪 **Tests** | Extend testbench coverage, add new assembly test cases |
| 💾 **Software** | Add new bare-metal example programs |

---

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/rv32i-soc.git
   cd rv32i-soc
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b feature/add-spi-peripheral
   ```

---

## Making Changes

### RTL Changes
- Keep RTL files in the correct folder (`core/`, `soc/`, `peripherals/`)
- Follow the existing naming convention: `module_name.v` for modules, `module_name.vh` for headers
- Add a comment block at the top of any new file with: module name, description, and port list

### Software Changes
- New example programs go in `soc/software/`
- Use the same linker script (`link.ld`) and build system (`Makefile`)
- Keep programs self-contained and well-commented

---

## Before Submitting

1. **Verify RTL compiles** (no syntax errors):
   ```bash
   iverilog -g2012 -o /dev/null core/*.v soc/*.v peripherals/*.v
   ```
2. **Run the testbench** in Vivado simulation to check your change does not break existing tests
3. **Update the README** if you add a new peripheral or change the memory map

---

## Submitting a Pull Request

1. Push your branch: `git push origin feature/your-feature`
2. Open a Pull Request on GitHub
3. Fill in the PR description: what changed, why, and how to test it
4. The CI will automatically run the Verilog syntax check — make sure it passes (green)

---

## Code Style

- **Verilog**: 4-space indentation, `always_ff` blocks over `always` where intent is clear, meaningful signal names
- **C**: 4-space indentation, `volatile` on all hardware register accesses
- **Commits**: Use clear, concise commit messages (`fix: resolve load-use stall for LW followed by ADD`)

---

## Questions?

Open a [GitHub Issue](https://github.com/Aryan16544/rv32i-soc/issues) with your question. Label it `question`.
