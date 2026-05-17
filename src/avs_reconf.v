// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/avs_reconf.v
// AVS Reconfiguration Controller (Sacred opcode 0xE4)
// Dynamic voltage scaling reconfiguration

`default_nettype none
module avs_reconf (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]   opcode,         // Must be 0xE4 for AVS_RECONF
    input  wire [7:0]   region_id,      // Voltage region ID
    input  wire [1:0]   voltage_mode,   // 00=ultra-low, 01=low, 10=normal, 11=high
    input  wire        reconf_req,     // Reconfiguration request
    output reg  [7:0]   active_regions, // Bitmask of active regions
    output reg  [1:0]   region_mode[7:0], // Mode per region
    output reg         reconf_done,    // Reconfiguration complete
    output reg  [7:0]   reconf_status   // Status code
);

    // Voltage levels
    localparam V_ULTRA_LOW = 2'b00;
    localparam V_LOW       = 2'b01;
    localparam V_NORMAL    = 2'b10;
    localparam V_HIGH      = 2'b11;

    // Status codes
    localparam STS_IDLE    = 8'd0;
    localparam STS_BUSY    = 8'd1;
    localparam STS_DONE    = 8'd2;
    localparam STS_ERROR   = 8'd255;

    reg [2:0] state;
    reg [7:0] target_region;
    reg [1:0] target_mode;
    reg [7:0] timeout_counter;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'd0;
            active_regions <= 8'hFF;
            for (i = 0; i < 8; i = i + 1)
                region_mode[i] <= V_NORMAL;
            reconf_done <= 1'b0;
            reconf_status <= STS_IDLE;
            target_region <= 8'd0;
            target_mode <= V_NORMAL;
            timeout_counter <= 8'd0;
        end else begin
            case (state)
                3'd0: begin
                    // Idle state
                    reconf_done <= 1'b0;
                    reconf_status <= STS_IDLE;

                    if (opcode == 4'd4 && reconf_req) begin
                        target_region <= region_id;
                        target_mode <= voltage_mode;
                        state <= 3'd1;
                        reconf_status <= STS_BUSY;
                    end
                end

                3'd1: begin
                    // Apply reconfiguration
                    region_mode[target_region[2:0]] <= target_mode;
                    timeout_counter <= 8'd10;
                    state <= 3'd2;
                end

                3'd2: begin
                    // Wait for stability
                    if (timeout_counter > 0) begin
                        timeout_counter <= timeout_counter - 1;
                    end else begin
                        state <= 3'd3;
                    end
                end

                3'd3: begin
                    // Complete
                    reconf_done <= 1'b1;
                    reconf_status <= STS_DONE;
                    state <= 3'd0;
                end

                default: state <= 3'd0;
            endcase
        end
    end

endmodule