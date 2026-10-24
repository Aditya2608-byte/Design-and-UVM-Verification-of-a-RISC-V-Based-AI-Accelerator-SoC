// ============================================================================
// File: tb/tb_de10_lite_top.sv
// Description: Testbench for DE10-Lite FPGA Board Top-Level Wrapper
// ============================================================================

`timescale 1ns/1ps

module tb_de10_lite_top;

    logic        MAX10_CLK1_50;
    logic [1:0]  KEY;
    logic [9:0]  SW;
    logic [9:0]  LEDR;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // Instantiate DE10-Lite Board Top
    de10_lite_top #(
        .INIT_FILE("sim/firmware.hex")
    ) dut (
        .MAX10_CLK1_50 (MAX10_CLK1_50),
        .KEY           (KEY),
        .SW            (SW),
        .LEDR          (LEDR),
        .HEX0          (HEX0),
        .HEX1          (HEX1),
        .HEX2          (HEX2),
        .HEX3          (HEX3),
        .HEX4          (HEX4),
        .HEX5          (HEX5)
    );

    // 50 MHz clock generator (20ns period)
    always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

    initial begin
        $dumpfile("waves/tb_de10_lite_top.vcd");
        $dumpvars(0, tb_de10_lite_top);

        MAX10_CLK1_50 = 0;
        KEY           = 2'b00; // KEY[0] active (held in reset)
        SW            = 10'd0; // SW[0]=0: PC mode

        #100;
        KEY[0] = 1'b1; // Release reset (active-low)
        $display("[INFO] DE10-Lite reset released at %0t ps", $time);

        // Wait for signature match on LEDR[4] or timeout
        fork
            begin
                wait (dut.LEDR[4] == 1'b1);
                $display("\n=======================================================");
                $display("  🏆 SUCCESS: DE10-Lite Top Verified Signature 0xCAFEBABE!");
                $display("  LEDR[0] (Accel Done) = %b", dut.LEDR[0]);
                $display("  LEDR[4] (Signature OK) = %b", dut.LEDR[4]);
                $display("  Heartbeat LEDR[9]    = %b", dut.LEDR[9]);
                
                // Switch to Signature Display mode
                SW[0] = 1'b1;
                #40;
                $display("  HEX3..HEX0 in Signature Mode: %b %b %b %b", dut.HEX3, dut.HEX2, dut.HEX1, dut.HEX0);
                $display("=======================================================\n");
            end
            begin
                #50000; // 50 microseconds
                if (dut.LEDR[4] != 1'b1) begin
                    $display("❌ TIMEOUT: DE10-Lite failed to assert LEDR[4]");
                    $finish;
                end
            end
        join_any

        #200;
        $finish;
    end

endmodule
