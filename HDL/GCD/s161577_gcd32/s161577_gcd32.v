`timescale 1ns / 1ps

module s161577_gcd32(
    input wire clk,
    input wire resetn,
    input wire [31:0] x_in, y_in,
    input wire start,
    
    output wire [31:0] gcd_out,
    output reg done
    );
    localparam IDLE = 0, GO_GCD = 1, DONE = 2;
    reg [1:0] state = IDLE;
    reg [31:0] x, y, gcd;
    
    // Reset
    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            state <= IDLE;
            x <= 32'b0;
            y <= 32'b0;
            gcd <= 32'b0;
            done <= 1'b0;
        end
    end
    
    // Next state logic
    always @(posedge clk) begin
        case (state)
            IDLE : begin
                if (start) begin
                    state <= GO_GCD;
                end
            end
            GO_GCD : begin
                if (x == y) begin
                    state <= DONE;
                end
            end
            DONE : begin
                state <= IDLE;
            end
            default : begin
                state <= IDLE;
            end
        endcase
    end
    
    // Output logic
    always @(posedge clk) begin
        case (state)
            IDLE : begin
                if (start) begin
                    x <= x_in;
                    y <= y_in;
                end
            end
            GO_GCD : begin
                if (x != y) begin
                    if (x < y) begin
                        x <= x;
                        y <= y - x;
                    end
                    else begin
                        x <= x - y;
                        y <= y;
                    end
                end
            end
            DONE : begin
                gcd <= x;
                done <= 1'b1;
            end
            default : begin
                x <= 0;
                y <= 0;
                gcd <= 0;
            end
        endcase
    end
    
    // done signal pulse
    always @(posedge clk) begin
        if (done) begin
            done <= 1'b0;
        end
    end
    
    // Assign result
    assign gcd_out = gcd;
endmodule
