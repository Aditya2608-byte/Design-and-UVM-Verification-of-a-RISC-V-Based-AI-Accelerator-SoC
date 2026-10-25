// ============================================================================
// File: rtl/soc_sram.sv
// Description: Synthesizable 16KB Byte-Addressable Dual-Port M9K SRAM Subsystem
//              - In Synthesis: Infers Intel MAX 10 M9K Block RAM via altsyncram
//              - In Simulation: Synthesizable behavioral array for probe access
// ============================================================================

`timescale 1ns/1ps

module soc_sram #(
    parameter int MEM_SIZE_BYTES = 16384,            // 16 KB
    parameter int NUM_WORDS      = MEM_SIZE_BYTES / 4, // 4096 32-bit words
    parameter     INIT_FILE      = "firmware.mif"
)(
    input  logic        clk,
    input  logic        rst_n,

    // ------------------------------------------------------------------------
    // Port A: Instruction Fetch (Word-Aligned Synchronous Read)
    // ------------------------------------------------------------------------
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_rdata,

    // ------------------------------------------------------------------------
    // Port B: Data Access (Byte-Addressable Synchronous Read/Write)
    // ------------------------------------------------------------------------
    input  logic        data_req,
    input  logic        data_we,
    input  logic [3:0]  data_wstrb,
    input  logic [31:0] data_addr,
    input  logic [31:0] data_wdata,
    output logic [31:0] data_rdata
);

    // 12-bit word indices for 4096 words
    logic [11:0] instr_word_idx;
    logic [11:0] data_word_idx;

    assign instr_word_idx = instr_addr[13:2];
    assign data_word_idx  = data_addr[13:2];

`ifdef SYNTHESIS
    // ------------------------------------------------------------------------
    // Intel MAX 10 Embedded M9K Block RAM (Hardware Implementation)
    // ------------------------------------------------------------------------
    altsyncram #(
        .operation_mode                 ("BIDIR_DUAL_PORT"),
        .width_a                        (32),
        .widthad_a                      (12),
        .numwords_a                     (4096),
        .outdata_reg_a                  ("UNREGISTERED"),
        .address_reg_b                  ("CLOCK0"),
        .indata_reg_b                   ("CLOCK0"),
        .wrcontrol_wraddress_reg_b      ("CLOCK0"),
        .byteena_reg_b                  ("CLOCK0"),
        .width_b                        (32),
        .widthad_b                      (12),
        .numwords_b                     (4096),
        .outdata_reg_b                  ("UNREGISTERED"),
        .width_byteena_b                (4),
        .byte_size                      (8),
        .ram_block_type                 ("M9K"),
        .init_file                      (INIT_FILE),
        .read_during_write_mode_port_b  ("DONT_CARE")
    ) u_m9k_ram (
        .clock0         (clk),
        .wren_a         (1'b0),
        .data_a         (32'd0),
        .address_a      (instr_word_idx),
        .q_a            (instr_rdata),
        .wren_b         (data_req && data_we),
        .data_b         (data_wdata),
        .address_b      (data_word_idx),
        .byteena_b      (data_wstrb),
        .q_b            (data_rdata)
    );

`else
    // ------------------------------------------------------------------------
    // Behavioral Dual-Port Memory for Simulation & Testbench Probing
    // ------------------------------------------------------------------------
    logic [31:0] mem [0:NUM_WORDS-1];

    always_ff @(posedge clk) begin
        instr_rdata <= mem[instr_word_idx];
    end

    always_ff @(posedge clk) begin
        if (data_req && data_we) begin
            if (data_wstrb[0]) mem[data_word_idx][7:0]   <= data_wdata[7:0];
            if (data_wstrb[1]) mem[data_word_idx][15:8]  <= data_wdata[15:8];
            if (data_wstrb[2]) mem[data_word_idx][23:16] <= data_wdata[23:16];
            if (data_wstrb[3]) mem[data_word_idx][31:24] <= data_wdata[31:24];
        end
        data_rdata <= mem[data_word_idx];
    end

    initial begin
        $readmemh("sim/firmware.hex", mem);
    end
`endif

endmodule
