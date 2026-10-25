// ============================================================================
// File: rtl/de10_lite_top.sv
// Description: Terasic DE10-Lite FPGA Board Top-Level Wrapper
// Target Device: Intel MAX 10 (10M50DAF484C7G)
//
// Interfaces:
//   - Clock: 50 MHz Oscillator (MAX10_CLK1_50 @ PIN_P11)
//   - Reset: Pushbutton KEY[0] (@ PIN_B8, active-low)
//   - LEDs:  LEDR[9:0] (@ PIN_B11..PIN_A8)
//            LEDR[0]: Accel Done (lights up when MatMul finishes)
//            LEDR[1]: Accel Busy (active computation)
//            LEDR[2]: Accel Error
//            LEDR[3]: Data Bus Request activity
//            LEDR[4]: Success Signature 0xCAFEBABE Verified
//            LEDR[8]: Reset indicator (~KEY[0])
//            LEDR[9]: 1.5 Hz Heartbeat LED (confirms system clock is running)
//   - 7-Seg: HEX5..HEX0 (@ PIN_N20..PIN_C14, active-low segments)
//            HEX3..HEX0: Displays current CPU PC or Test Result
//            HEX5..HEX4: Status codes
// ============================================================================

`timescale 1ns/1ps

module de10_lite_top #(
    parameter INIT_FILE = "firmware.mif"
)(
    // 50 MHz Onboard Clock
    input  logic        MAX10_CLK1_50,

    // Push Buttons (Active-Low)
    input  logic [1:0]  KEY,

    // Slide Switches (Active-High)
    input  logic [9:0]  SW,

    // 10 User LEDs (Active-High)
    output logic [9:0]  LEDR,

    // 6 7-Segment Displays (Active-Low Segments: [6]=G, [5]=F, [4]=E, [3]=D, [2]=C, [1]=B, [0]=A)
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5
);

    // ------------------------------------------------------------------------
    // Clock & Reset Conditioning
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    assign clk   = MAX10_CLK1_50;
    assign rst_n = KEY[0]; // Pushbutton KEY[0] is active-low (0 when pressed)

    // ------------------------------------------------------------------------
    // Heartbeat Counter (1.5 Hz blink from 50 MHz clock)
    // ------------------------------------------------------------------------
    logic [25:0] hb_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hb_counter <= 26'd0;
        end else begin
            hb_counter <= hb_counter + 1'b1;
        end
    end

    // ------------------------------------------------------------------------
    // SoC Signals & Observability
    // ------------------------------------------------------------------------
    logic        accel_done;
    logic        accel_busy;
    logic        accel_error;
    logic        accel_irq;

    logic [31:0] dbg_pc;
    logic        dbg_data_req;
    logic [31:0] dbg_data_addr;
    logic [31:0] dbg_data_wdata;

    // Latch successful completion signature
    logic [31:0] signature_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signature_reg <= 32'd0;
        end else if (dbg_data_req && (dbg_data_addr == 32'h0000_10FC)) begin
            signature_reg <= dbg_data_wdata;
        end
    end

    // ------------------------------------------------------------------------
    // RISC-V + AI Accelerator SoC Instance
    // ------------------------------------------------------------------------
    soc_top #(
        .RESET_ADDR     (32'h0000_0000),
        .MEM_SIZE_BYTES (16384),
        .INIT_FILE      (INIT_FILE)
    ) u_soc_top (
        .clk            (clk),
        .rst_n          (rst_n),
        .accel_done     (accel_done),
        .accel_busy     (accel_busy),
        .accel_error    (accel_error),
        .accel_irq      (accel_irq),
        .dbg_pc         (dbg_pc),
        .dbg_data_req   (dbg_data_req),
        .dbg_data_addr  (dbg_data_addr),
        .dbg_data_wdata (dbg_data_wdata)
    );

    // ------------------------------------------------------------------------
    // LED Mapping
    // ------------------------------------------------------------------------
    assign LEDR[0] = accel_done;                  // Bit 0: Accel Done
    assign LEDR[1] = accel_busy;                  // Bit 1: Accel Busy
    assign LEDR[2] = accel_error;                 // Bit 2: Accel Error
    assign LEDR[3] = dbg_data_req;                // Bit 3: Memory bus transaction
    assign LEDR[4] = (signature_reg == 32'hCAFEBABE); // Bit 4: Signature CAFEBABE verified!
    assign LEDR[5] = accel_irq;                   // Bit 5: Interrupt
    assign LEDR[6] = 1'b0;
    assign LEDR[7] = 1'b0;
    assign LEDR[8] = ~rst_n;                      // Bit 8: In Reset (KEY0 pressed)
    assign LEDR[9] = hb_counter[24];              // Bit 9: 1.5 Hz Heartbeat

    // ------------------------------------------------------------------------
    // 7-Segment Display Drivers (Active-Low Segments)
    // Mode switch:
    //   SW[0] = 0 -> Display lower 16 bits of CPU PC (dbg_pc[15:0])
    //   SW[0] = 1 -> Display signature register (signature_reg[15:0] -> "bAbE")
    // ------------------------------------------------------------------------
    logic [15:0] display_word;
    assign display_word = SW[0] ? signature_reg[15:0] : dbg_pc[15:0];

    hex_digit_decoder u_hex0 (.digit(display_word[3:0]),   .segments(HEX0));
    hex_digit_decoder u_hex1 (.digit(display_word[7:4]),   .segments(HEX1));
    hex_digit_decoder u_hex2 (.digit(display_word[11:8]),  .segments(HEX2));
    hex_digit_decoder u_hex3 (.digit(display_word[15:12]), .segments(HEX3));

    // HEX4 and HEX5 display upper nibbles of signature or PC
    logic [7:0] upper_word;
    assign upper_word = SW[0] ? signature_reg[23:16] : dbg_pc[23:16];
    hex_digit_decoder u_hex4 (.digit(upper_word[3:0]), .segments(HEX4));
    hex_digit_decoder u_hex5 (.digit(upper_word[7:4]), .segments(HEX5));

endmodule

// ============================================================================
// Helper Module: 4-bit Hex to 7-Segment Decoder (Active-Low Output)
// Segments: {G, F, E, D, C, B, A}
// ============================================================================
module hex_digit_decoder (
    input  logic [3:0] digit,
    output logic [6:0] segments
);
    always_comb begin
        case (digit)
            4'h0: segments = 7'b1000000; // 0
            4'h1: segments = 7'b1111001; // 1
            4'h2: segments = 7'b0100100; // 2
            4'h3: segments = 7'b0110000; // 3
            4'h4: segments = 7'b0011001; // 4
            4'h5: segments = 7'b0010010; // 5
            4'h6: segments = 7'b0000010; // 6
            4'h7: segments = 7'b1111000; // 7
            4'h8: segments = 7'b0000000; // 8
            4'h9: segments = 7'b0010000; // 9
            4'hA: segments = 7'b0001000; // A
            4'hB: segments = 7'b0000011; // b
            4'hC: segments = 7'b1000110; // C
            4'hD: segments = 7'b0100001; // d
            4'hE: segments = 7'b0000110; // E
            4'hF: segments = 7'b0001110; // F
            default: segments = 7'b1111111;
        endcase
    end
endmodule
