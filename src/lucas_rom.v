`default_nettype none
// lucas_rom.v — Lucas number ROM L₂..L₇
// Apache-2.0
//
// PhD anchor: Lucas closure chain
//   L₂=3, L₃=4, L₄=7, L₅=11, L₆=18, L₇=29
//
// Single-cycle ROM addressable by 3-bit index 0..5 (maps to n=2..7).
// Use case: external host can prove silicon identity by reading the chain
// through the Wishbone status register.

module lucas_rom (
    input  wire [2:0] idx,    // 0=L₂, 1=L₃, ... 5=L₇
    output reg  [7:0] value
);

    always @(*) begin
        case (idx)
            3'd0: value = 8'd3;   // L₂
            3'd1: value = 8'd4;   // L₃
            3'd2: value = 8'd7;   // L₄
            3'd3: value = 8'd11;  // L₅
            3'd4: value = 8'd18;  // L₆
            3'd5: value = 8'd29;  // L₇
            default: value = 8'd0;
        endcase
    end

endmodule
