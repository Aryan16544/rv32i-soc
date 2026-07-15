`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// RV32I SoC — Comprehensive Verification Testbench
// Tests all 37 RV32I data-path instructions + FENCE/ECALL/EBREAK
// 60 automated checks covering:
//   - All R-type (ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND)
//   - All I-type ALU (ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI)
//   - All Load/Store (LW,LH,LB,LHU,LBU,SW,SH,SB)
//   - All Branches (BEQ,BNE,BLT,BGE,BLTU,BGEU) taken + not-taken
//   - Jumps (JAL, JALR)
//   - U-type (LUI, AUIPC)
//   - Corner cases (overflow, underflow, x0 immutability, shift 0/31)
//   - Data hazards (RAW, load-use, multi-forwarding)
//   - Backward branch (loop)
//   - FENCE, ECALL, EBREAK (NOP behavior)
//////////////////////////////////////////////////////////////////////////////

module rv32i_soc_full_tb;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    reg clk;
    reg rst_n;

    // Clock: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================================================================
    // DUT I/O
    // =========================================================================
    wire        uart_tx;
    reg         uart_rx;
    reg  [15:0] gpio_in;
    wire [15:0] gpio_out;

    // =========================================================================
    // DUT Instantiation (rv32i_soc directly — bypasses fpga_top clock divider)
    // =========================================================================
    rv32i_soc #(
        .IMEM_INIT_FILE("rv32i_test_program.mem")
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out)
    );

    // =========================================================================
    // Hierarchical References (Simulation Only)
    // =========================================================================
    // Register file: dut.core.decode.reg_file.registers[1..31]
    // PC:            dut.core.fetch.pc_reg
    // IMEM BRAM:     dut.imem.ram[0..4095]
    // DMEM BRAM:     dut.dmem.ram[0..16383]
    // Pipeline:      dut.core.fetch/decode/execute/memory/writeback

    // =========================================================================
    // Test Infrastructure
    // =========================================================================
    // Include auto-generated expected values
    `include "test_expected.vh"

    integer pass_count;
    integer fail_count;
    integer cycle_count;
    integer i;

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        cycle_count = 0;
    end

    always @(posedge clk) begin
        if (rst_n) cycle_count <= cycle_count + 1;
    end

    // =========================================================================
    // IMEM is loaded natively by the SoC's soc_bram_imem module
    // (soc_ram.v: $readmemh("rv32i_test_program.mem", ram))
    // No testbench override needed.
    // =========================================================================

    // =========================================================================
    // Opcode decoder (for display)
    // =========================================================================
    function [79:0] decode_opcode;
        input [6:0] opcode;
        begin
            case (opcode)
                7'b0110011: decode_opcode = "R-TYPE    ";
                7'b0010011: decode_opcode = "I-ALU     ";
                7'b0000011: decode_opcode = "LOAD      ";
                7'b0100011: decode_opcode = "STORE     ";
                7'b1100011: decode_opcode = "BRANCH    ";
                7'b1101111: decode_opcode = "JAL       ";
                7'b1100111: decode_opcode = "JALR      ";
                7'b0110111: decode_opcode = "LUI       ";
                7'b0010111: decode_opcode = "AUIPC     ";
                7'b0001111: decode_opcode = "FENCE     ";
                7'b1110011: decode_opcode = "SYSTEM    ";
                default:    decode_opcode = "UNKNOWN   ";
            endcase
        end
    endfunction

    // =========================================================================
    // Register value reader (handles x0 hardwired to 0)
    // =========================================================================
    function [31:0] read_reg;
        input [4:0] idx;
        begin
            if (idx == 0) read_reg = 32'b0;
            else read_reg = dut.core.decode.regfile.registers[idx];
        end
    endfunction

    // =========================================================================
    // Per-Cycle Pipeline Monitor
    // =========================================================================
    always @(posedge clk) begin
        if (rst_n && (cycle_count < 50 || (cycle_count % 100 == 0))) begin
            $display("==============================================================");
            $display(" CYCLE %0d | TIME %0t ns", cycle_count, $time);
            $display("==============================================================");

            // Fetch
            $display("[IF]  PC=0x%08h  Instr=0x%08h  Valid=%b",
                dut.core.fetch.pc,
                dut.core.if_id_instruction,
                dut.core.if_id_valid);

            // Decode - show opcode type
            $display("[ID]  Opcode=%0s  rd=x%0d  rs1=x%0d  rs2=x%0d",
                decode_opcode(dut.core.if_id_instruction[6:0]),
                dut.core.if_id_instruction[11:7],
                dut.core.if_id_instruction[19:15],
                dut.core.if_id_instruction[24:20]);

            // Execute
            $display("[EX]  rd=x%0d  ALU_out=0x%08h  BrTaken=%b",
                dut.core.id_ex_rd,
                dut.core.ex_mem_alu_result,
                dut.core.branch_taken);

            // Writeback
            if (dut.core.wb_reg_write && dut.core.wb_rd != 0)
                $display("[WB]  Writing x%0d = 0x%08h",
                    dut.core.wb_rd, dut.core.wb_data);

            // Register dump (compact: 8 per line)
            $display("--- Registers ---");
            $display(" x0 =%08h  x1 =%08h  x2 =%08h  x3 =%08h  x4 =%08h  x5 =%08h  x6 =%08h  x7 =%08h",
                read_reg(0),  read_reg(1),  read_reg(2),  read_reg(3),
                read_reg(4),  read_reg(5),  read_reg(6),  read_reg(7));
            $display(" x8 =%08h  x9 =%08h  x10=%08h  x11=%08h  x12=%08h  x13=%08h  x14=%08h  x15=%08h",
                read_reg(8),  read_reg(9),  read_reg(10), read_reg(11),
                read_reg(12), read_reg(13), read_reg(14), read_reg(15));
            $display(" x16=%08h  x17=%08h  x18=%08h  x19=%08h  x20=%08h  x21=%08h  x22=%08h  x23=%08h",
                read_reg(16), read_reg(17), read_reg(18), read_reg(19),
                read_reg(20), read_reg(21), read_reg(22), read_reg(23));
            $display(" x24=%08h  x25=%08h  x26=%08h  x27=%08h  x28=%08h  x29=%08h  x30=%08h  x31=%08h",
                read_reg(24), read_reg(25), read_reg(26), read_reg(27),
                read_reg(28), read_reg(29), read_reg(30), read_reg(31));
            $display("");
        end
    end

    // =========================================================================
    // GPIO completion monitor
    // =========================================================================
    reg test_done;
    initial test_done = 0;

    always @(posedge clk) begin
        if (rst_n && gpio_out == 16'hCAFE && !test_done) begin
            test_done <= 1;
            $display("============================================================");
            $display(" GPIO COMPLETION SIGNAL DETECTED: 0xCAFE at cycle %0d", cycle_count);
            $display("============================================================");
        end
    end

    // =========================================================================
    // Verification task
    // =========================================================================
    task verify_dmem;
        input integer test_idx;
        input [31:0] expected;
        input [255:0] name;
        reg [31:0] actual;
        begin
            // DMEM word address: test_idx (byte offset = test_idx * 4, word addr = test_idx)
            actual = dut.dmem.ram[test_idx];
            if (actual === expected) begin
                $display("[PASS] %0s = 0x%08h", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s = 0x%08h (expected 0x%08h) <<<", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task verify_reg;
        input [4:0]   reg_num;
        input [31:0]  expected;
        input [255:0] name;
        reg [31:0] actual;
        begin
            actual = read_reg(reg_num);
            if (actual === expected) begin
                $display("[PASS] %0s = 0x%08h", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s = 0x%08h (expected 0x%08h) <<<", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        // Initialize
        rst_n   = 0;
        uart_rx = 1'b1;  // UART idle high
        gpio_in = 16'hDEAD;

        $display("============================================================");
        $display(" RV32I SoC Comprehensive Verification Testbench");
        $display(" 60 automated tests covering all RV32I instructions");
        $display("============================================================");

        // Reset
        $display("[%t] Asserting reset...", $time);
        #100;
        @(posedge clk);
        rst_n = 1;
        $display("[%t] Reset released. Program execution starting.", $time);

        // Wait for program to complete (GPIO = 0xCAFE) or timeout
        // With AXI latency, each instruction takes ~3-5 cycles
        // 197 instructions * 5 cycles + margin = ~2000 cycles = 20000 ns
        begin : wait_block
            integer timeout_cnt;
            timeout_cnt = 0;
            while (!test_done && timeout_cnt < 50000) begin
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;
            end
            if (test_done)
                $display("[%t] Program completed normally at cycle %0d.", $time, cycle_count);
            else begin
                $display("[%t] WARNING: Timeout after %0d cycles. Program may not have completed.", $time, timeout_cnt);
                $display("        PC = 0x%08h, GPIO = 0x%04h", dut.core.fetch.pc, gpio_out);
            end
        end

        // Allow final writes to settle
        #500;

        // =================================================================
        // VERIFICATION PHASE
        // =================================================================
        $display("");
        $display("+=========================================================+");
        $display("|          VERIFICATION RESULTS                          |");
        $display("+=========================================================+");

        // --- Check all 60 DMEM-stored test results ---
        $display("|  DMEM-Stored Test Results (60 tests)                   |");
        $display("+=========================================================+");

        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            verify_dmem(i, expected_values[i], test_names[i]);
        end

        // --- Additional register checks ---
        $display("+=========================================================+");
        $display("|  Additional Register Checks                            |");
        $display("+=========================================================+");

        // x0 must always be 0
        verify_reg(0, 32'h00000000, "x0  hardwired zero");

        // x4 should still be DMEM base
        verify_reg(4, 32'h10000000, "x4  DMEM base preserved");

        // x5 should still be INT_MIN
        verify_reg(5, 32'h80000000, "x5  INT_MIN preserved");

        // --- Check store results in DMEM (from Phase 5 store tests) ---
        $display("+=========================================================+");
        $display("|  Store Verification (raw DMEM checks)                  |");
        $display("+=========================================================+");

        // DMEM word index 64 = byte offset 256
        verify_dmem(64, 32'h0000005A, "SW   word at DMEM[256]");
        verify_dmem(65, 32'hFFFFFFFF, "SW   word at DMEM[260]");

        // --- Summary ---
        $display("");
        $display("+=========================================================+");
        $display("|  FINAL SUMMARY                                         |");
        $display("+=========================================================+");
        $display("|  Total Checks:  %3d                                    |", pass_count + fail_count);
        $display("|  PASSED:        %3d                                    |", pass_count);
        $display("|  FAILED:        %3d                                    |", fail_count);
        $display("+=========================================================+");
        if (fail_count == 0) begin
            $display("|  >>> ALL TESTS PASSED <<<                              |");
        end else begin
            $display("|  >>> SOME TESTS FAILED <<<                             |");
        end
        $display("|  Completion cycle: %0d                                 |", cycle_count);
        $display("+=========================================================+");
        $display("");

        #100;
        $finish;
    end

    // =========================================================================
    // Waveform dump (for viewing in Vivado or GTKWave)
    // =========================================================================
    initial begin
        $dumpfile("rv32i_soc_full_tb.vcd");
        $dumpvars(0, rv32i_soc_full_tb);
    end

endmodule
