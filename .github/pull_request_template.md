## Pull Request Description

### What does this PR do?
<!-- Briefly describe the change -->

### Type of Change
- [ ] 🐛 Bug fix (RTL or software)
- [ ] ✨ New feature (peripheral, instruction support)
- [ ] 📖 Documentation improvement
- [ ] 🧪 Test / testbench update
- [ ] 🔧 CI / tooling change

### Related Issue
Closes #<!-- issue number -->

### Testing Done
- [ ] RTL compiles without errors (`iverilog -g2012 core/*.v soc/*.v peripherals/*.v`)
- [ ] Vivado simulation passes (no `[FAIL]` in testbench output)
- [ ] Hardware tested on FPGA board (optional but appreciated)

### Checklist
- [ ] Code follows the project style (4-space indent, meaningful signal names)
- [ ] README updated if memory map or peripherals changed
- [ ] New files added to `scripts/create_vivado_project.tcl` if needed
