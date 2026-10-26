// ============================================================================
// File: rtl/de10_standard_top.sv
// Description: Terasic DE10-Standard FPGA Board Top-Level Wrapper
// Target Device: Intel Cyclone V SX SoC FPGA (5CSXFC6D6F31C6N)
//
// Interfaces:
//   - Clock: 50 MHz Oscillator (CLOCK_50 @ PIN_AF14)
//   - Reset: Pushbutton KEY[0] (@ PIN_AJ4, active-low)
//   - LEDs:  LEDR[9:0] (@ PIN_AC22..PIN_AA24)
//            LEDR[0]: Accel Done (Latched on completion)
//            LEDR[1]: Accel Busy (active computation)
//            LEDR[2]: Accel Error
//            LEDR[3]: Data Bus Request activity
//            LEDR[4]: Success Signature 0xCAFEBABE Verified
//            LEDR[5]: Accel IRQ asserted
//            LEDR[8]: Reset indicator (~KEY[0])
//            LEDR[9]: 1.5 Hz Heartbeat LED (confirms system clock is running)
//   - 7-Seg: HEX5..HEX0 (@ PIN_AB21..PIN_W17, active-low segments)
//            Interactive Multi-Mode Inspection via SW[3:0]:
//              4'h0: Signature "FE bA bE" (0xCAFEBABE)
//              4'h1: Predicted Class "CLASSE 0"
//              4'h2: Output Logit 0 "L0  324"
//              4'h3: Output Logit 1 "L1   87"
//              4'h4: Output Logit 2 "L2 -127"
//              4'h5: Output Logit 3 "L3  149"
//              4'h6: Hardware Latency Cycles "CC  xxx"
//              4'h7: CPU Program Counter "PC xxxx"
//              4'h8..4'hF: Hidden Layer Activations "H0" .. "H7"
// ============================================================================

`timescale 1ns/1ps

module de10_standard_top #(
    parameter INIT_FILE = "firmware.mif"
)(
    // 50 MHz Onboard Clock
    input  logic        CLOCK_50,

    // Push Buttons (Active-Low)
    input  logic [3:0]  KEY,

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

    assign rst_n = KEY[0]; // Pushbutton KEY[0] is active-low (0 when pressed)

    // ------------------------------------------------------------------------
    // Safe 5 MHz SoC Core Clock Generation (50 MHz / 10 = 5 MHz, period = 200 ns)
    // Guarantees timing closure across the 32-bit LPM_DIVIDE combinational unit
    // ------------------------------------------------------------------------
    logic [2:0] clk_div_cnt;
    logic       soc_clk;

    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_cnt <= 3'd0;
            soc_clk     <= 1'b0;
        end else begin
            if (clk_div_cnt == 3'd4) begin
                clk_div_cnt <= 3'd0;
                soc_clk     <= ~soc_clk;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end
    end

    assign clk = soc_clk;

    // ------------------------------------------------------------------------
    // Heartbeat Counter (1.5 Hz blink from 50 MHz clock)
    // ------------------------------------------------------------------------
    logic [25:0] hb_counter;
    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
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

    // Latch accelerator done to keep LEDR[0] solidly lit once finished
    logic accel_done_latched;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accel_done_latched <= 1'b0;
        end else if (accel_done) begin
            accel_done_latched <= 1'b1;
        end
    end

    // Latch neural network results and completion signature from SRAM writes
    logic [31:0] hidden_reg [8];
    logic [31:0] logit_reg  [4];
    logic [31:0] pred_class_reg;
    logic [31:0] signature_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < 8; k++) hidden_reg[k] <= 32'd0;
            for (int k = 0; k < 4; k++) logit_reg[k]  <= 32'd0;
            pred_class_reg <= 32'd0;
            signature_reg  <= 32'd0;
        end else if (dbg_data_req) begin
            case (dbg_data_addr)
                32'h0000_1000: hidden_reg[0]  <= dbg_data_wdata;
                32'h0000_1004: hidden_reg[1]  <= dbg_data_wdata;
                32'h0000_1008: hidden_reg[2]  <= dbg_data_wdata;
                32'h0000_100C: hidden_reg[3]  <= dbg_data_wdata;
                32'h0000_1010: hidden_reg[4]  <= dbg_data_wdata;
                32'h0000_1014: hidden_reg[5]  <= dbg_data_wdata;
                32'h0000_1018: hidden_reg[6]  <= dbg_data_wdata;
                32'h0000_101C: hidden_reg[7]  <= dbg_data_wdata;
                32'h0000_1020: logit_reg[0]   <= dbg_data_wdata;
                32'h0000_1024: logit_reg[1]   <= dbg_data_wdata;
                32'h0000_1028: logit_reg[2]   <= dbg_data_wdata;
                32'h0000_102C: logit_reg[3]   <= dbg_data_wdata;
                32'h0000_1030: pred_class_reg <= dbg_data_wdata;
                32'h0000_10FC: signature_reg  <= dbg_data_wdata;
                default: ;
            endcase
        end
    end

    // Track execution cycles spent in accelerator computation
    logic [15:0] cycle_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt <= 16'd0;
        end else if (accel_busy) begin
            cycle_cnt <= cycle_cnt + 16'd1;
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
    assign LEDR[0] = accel_done_latched;              // Bit 0: Accel Done (Latched)
    assign LEDR[1] = accel_busy;                      // Bit 1: Accel Busy
    assign LEDR[2] = accel_error;                     // Bit 2: Accel Error
    assign LEDR[3] = dbg_data_req;                    // Bit 3: Memory bus transaction
    assign LEDR[4] = (signature_reg == 32'hCAFEBABE); // Bit 4: Signature CAFEBABE verified!
    assign LEDR[5] = accel_irq;                       // Bit 5: Interrupt
    assign LEDR[6] = 1'b0;
    assign LEDR[7] = 1'b0;
    assign LEDR[8] = ~rst_n;                          // Bit 8: In Reset (KEY0 pressed)
    assign LEDR[9] = hb_counter[24];                  // Bit 9: 1.5 Hz Heartbeat

    // ------------------------------------------------------------------------
    // Interactive 7-Segment Display Controller (HEX5..HEX0)
    // ------------------------------------------------------------------------
    logic signed [15:0] selected_val;
    logic [6:0] tag_h5, tag_h4;
    logic is_decimal_mode;
    logic is_signature_mode;
    logic is_pc_mode;
    logic is_class_mode;

    always_comb begin
        is_decimal_mode   = 1'b1;
        is_signature_mode = 1'b0;
        is_pc_mode        = 1'b0;
        is_class_mode     = 1'b0;
        selected_val      = 16'd0;
        tag_h5            = 7'b1111111;
        tag_h4            = 7'b1111111;

        case (SW[3:0])
            4'h0: begin // Signature FEbAbE
                is_signature_mode = 1'b1;
                is_decimal_mode   = 1'b0;
            end
            4'h1: begin // Predicted Class: CLASSE 0
                is_class_mode   = 1'b1;
                is_decimal_mode = 1'b0;
            end
            4'h2: begin // Logit 0: L0 324
                tag_h5       = 7'b1000111; // 'L'
                tag_h4       = 7'b1000000; // '0'
                selected_val = logit_reg[0][15:0];
            end
            4'h3: begin // Logit 1: L1 87
                tag_h5       = 7'b1000111; // 'L'
                tag_h4       = 7'b1111001; // '1'
                selected_val = logit_reg[1][15:0];
            end
            4'h4: begin // Logit 2: L2 -127
                tag_h5       = 7'b1000111; // 'L'
                tag_h4       = 7'b0100100; // '2'
                selected_val = logit_reg[2][15:0];
            end
            4'h5: begin // Logit 3: L3 149
                tag_h5       = 7'b1000111; // 'L'
                tag_h4       = 7'b0110000; // '3'
                selected_val = logit_reg[3][15:0];
            end
            4'h6: begin // Latency cycles: CC xxx
                tag_h5       = 7'b1000110; // 'C'
                tag_h4       = 7'b1000110; // 'C'
                selected_val = cycle_cnt;
            end
            4'h7: begin // Program Counter: PC xxxx
                is_pc_mode      = 1'b1;
                is_decimal_mode = 1'b0;
                tag_h5          = 7'b0001100; // 'P'
                tag_h4          = 7'b1000110; // 'C'
            end
            4'h8: begin // Hidden 0
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b1000000; // '0'
                selected_val = hidden_reg[0][15:0];
            end
            4'h9: begin // Hidden 1
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b1111001; // '1'
                selected_val = hidden_reg[1][15:0];
            end
            4'hA: begin // Hidden 2
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b0100100; // '2'
                selected_val = hidden_reg[2][15:0];
            end
            4'hB: begin // Hidden 3
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b0110000; // '3'
                selected_val = hidden_reg[3][15:0];
            end
            4'hC: begin // Hidden 4
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b0011001; // '4'
                selected_val = hidden_reg[4][15:0];
            end
            4'hD: begin // Hidden 5
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b0010010; // '5'
                selected_val = hidden_reg[5][15:0];
            end
            4'hE: begin // Hidden 6
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b0000010; // '6'
                selected_val = hidden_reg[6][15:0];
            end
            4'hF: begin // Hidden 7
                tag_h5       = 7'b0001001; // 'H'
                tag_h4       = 7'b1111000; // '7'
                selected_val = hidden_reg[7][15:0];
            end
        endcase
    end

    // Signed decimal decoder instance
    logic [6:0] dec_h3, dec_h2, dec_h1, dec_h0;
    signed_decimal_display u_dec (
        .value (selected_val),
        .seg3  (dec_h3),
        .seg2  (dec_h2),
        .seg1  (dec_h1),
        .seg0  (dec_h0)
    );

    // Hex decoders for PC and Signature
    logic [6:0] hex_pc3, hex_pc2, hex_pc1, hex_pc0;
    hex_digit_decoder u_pc0 (.digit(dbg_pc[3:0]),   .segments(hex_pc0));
    hex_digit_decoder u_pc1 (.digit(dbg_pc[7:4]),   .segments(hex_pc1));
    hex_digit_decoder u_pc2 (.digit(dbg_pc[11:8]),  .segments(hex_pc2));
    hex_digit_decoder u_pc3 (.digit(dbg_pc[15:12]), .segments(hex_pc3));

    logic [6:0] hex_sig5, hex_sig4, hex_sig3, hex_sig2, hex_sig1, hex_sig0;
    hex_digit_decoder u_s0 (.digit(signature_reg[3:0]),   .segments(hex_sig0));
    hex_digit_decoder u_s1 (.digit(signature_reg[7:4]),   .segments(hex_sig1));
    hex_digit_decoder u_s2 (.digit(signature_reg[11:8]),  .segments(hex_sig2));
    hex_digit_decoder u_s3 (.digit(signature_reg[15:12]), .segments(hex_sig3));
    hex_digit_decoder u_s4 (.digit(signature_reg[19:16]), .segments(hex_sig4));
    hex_digit_decoder u_s5 (.digit(signature_reg[23:20]), .segments(hex_sig5));

    logic [6:0] hex_cls0;
    hex_digit_decoder u_cls0 (.digit(pred_class_reg[3:0]), .segments(hex_cls0));

    // Multiplex final segments to HEX5..HEX0
    always_comb begin
        if (is_signature_mode) begin
            HEX5 = hex_sig5;
            HEX4 = hex_sig4;
            HEX3 = hex_sig3;
            HEX2 = hex_sig2;
            HEX1 = hex_sig1;
            HEX0 = hex_sig0;
        end else if (is_class_mode) begin
            HEX5 = 7'b1000110; // 'C'
            HEX4 = 7'b1000111; // 'L'
            HEX3 = 7'b0001000; // 'A'
            HEX2 = 7'b0010010; // 'S'
            HEX1 = 7'b1111111; // blank
            HEX0 = hex_cls0;   // class digit (e.g. 0)
        end else if (is_pc_mode) begin
            HEX5 = tag_h5;     // 'P'
            HEX4 = tag_h4;     // 'C'
            HEX3 = hex_pc3;
            HEX2 = hex_pc2;
            HEX1 = hex_pc1;
            HEX0 = hex_pc0;
        end else begin // Decimal values: Logits, Latency, Hidden
            HEX5 = tag_h5;
            HEX4 = tag_h4;
            HEX3 = dec_h3;
            HEX2 = dec_h2;
            HEX1 = dec_h1;
            HEX0 = dec_h0;
        end
    end

endmodule


// ============================================================================
// Helper Module: Signed 16-Bit Decimal to 7-Segment Formatter
// Automatically performs Double-Dabble BCD, minus-sign handling, and blanking
// ============================================================================
module signed_decimal_display (
    input  logic signed [15:0] value,
    output logic [6:0]         seg3,
    output logic [6:0]         seg2,
    output logic [6:0]         seg1,
    output logic [6:0]         seg0
);
    localparam logic [6:0] SEG_MINUS = 7'b0111111;
    localparam logic [6:0] SEG_BLANK = 7'b1111111;

    logic is_neg;
    logic [13:0] abs_val;
    logic [15:0] bcd;
    logic [3:0] d3, d2, d1, d0;

    assign is_neg = value[15];
    assign abs_val = is_neg ? (-value[13:0]) : value[13:0];

    // Double-dabble for 14-bit unsigned (0..9999)
    function automatic [15:0] bcd14(input logic [13:0] bin);
        integer i;
        logic [29:0] sr;
        begin
            sr = {16'd0, bin};
            for (i = 0; i < 14; i = i + 1) begin
                if (sr[17:14] >= 5) sr[17:14] = sr[17:14] + 4'd3;
                if (sr[21:18] >= 5) sr[21:18] = sr[21:18] + 4'd3;
                if (sr[25:22] >= 5) sr[25:22] = sr[25:22] + 4'd3;
                if (sr[29:26] >= 5) sr[29:26] = sr[29:26] + 4'd3;
                sr = sr << 1;
            end
            bcd14 = sr[29:14];
        end
    endfunction

    function automatic [6:0] dec_seg(input logic [3:0] d);
        case (d)
            4'h0: dec_seg = 7'b1000000;
            4'h1: dec_seg = 7'b1111001;
            4'h2: dec_seg = 7'b0100100;
            4'h3: dec_seg = 7'b0110000;
            4'h4: dec_seg = 7'b0011001;
            4'h5: dec_seg = 7'b0010010;
            4'h6: dec_seg = 7'b0000010;
            4'h7: dec_seg = 7'b1111000;
            4'h8: dec_seg = 7'b0000000;
            4'h9: dec_seg = 7'b0010000;
            default: dec_seg = 7'b1111111;
        endcase
    endfunction

    assign bcd = bcd14(abs_val);
    assign d3 = bcd[15:12];
    assign d2 = bcd[11:8];
    assign d1 = bcd[7:4];
    assign d0 = bcd[3:0];

    always_comb begin
        if (d3 != 4'd0) begin
            seg3 = is_neg ? SEG_MINUS : dec_seg(d3);
            seg2 = dec_seg(d2);
            seg1 = dec_seg(d1);
            seg0 = dec_seg(d0);
        end else if (d2 != 4'd0) begin
            seg3 = is_neg ? SEG_MINUS : SEG_BLANK;
            seg2 = dec_seg(d2);
            seg1 = dec_seg(d1);
            seg0 = dec_seg(d0);
        end else if (d1 != 4'd0) begin
            seg3 = SEG_BLANK;
            seg2 = is_neg ? SEG_MINUS : SEG_BLANK;
            seg1 = dec_seg(d1);
            seg0 = dec_seg(d0);
        end else begin
            seg3 = SEG_BLANK;
            seg2 = SEG_BLANK;
            seg1 = is_neg ? SEG_MINUS : SEG_BLANK;
            seg0 = dec_seg(d0);
        end
    end
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
