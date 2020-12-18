`timescale 1ns / 1ps

module led_btn_ctrl # (
    parameter integer LED_WIDTH = 4,
    parameter integer BTN_WIDTH = 4,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    parameter integer OPT_MEM_ADDR_BITS = 2
)
(
    output wire [LED_WIDTH - 1:0] led,
    input wire [BTN_WIDTH - 1:0] btn,
    output wire irq,
    input wire clk, resetN, // reset if resetN = 0(low active)
    input wire [C_S_AXI_ADDR_WIDTH - 1:0] axi_araddr, // 5 bit addr
    input wire [C_S_AXI_DATA_WIDTH - 1:0] r0, r1, r2, r3, r4, r5, r6, r7,
    output reg [C_S_AXI_DATA_WIDTH - 1:0] reg_out
);
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
integer i = 0; // Counter in for loop
reg [BTN_WIDTH - 1:0] btnr, btnr_d, btn_pulse, btn_reg;
wire btn_pushed;
wire int_clr, int_en;
reg int_req;

assign int_en = r3[0]; // 1/0 (enable/disable)
assign int_clr = r3[1]; // 1 (interrupt clear)
assign irq = int_req & int_en;
assign led = r0[LED_WIDTH - 1:0]; // r0 will have led value

// Latch btn and delayed btn
always @(posedge clk) begin
    if (resetN == 1'b0) begin
        btnr <= 0;
        btnr_d <= 0;
    end
    else begin
        btnr <= btn;
        btnr_d <= btnr;
    end
end

// btn pulse generation
always @(*) begin
    for (i = 0; i < 4; i = i + 1)
        btn_pulse[i] = btnr[i] & (~btnr_d[i]);
end

// btn push detection (use reduction or)
assign btn_pushed =| (btn_pulse);

// Set btn_reg
always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        if (resetN == 1'b0 || int_clr == 1'b1)
            btn_reg[i] <= 1'b0;
        else if (btn_pulse[i] == 1'b1)
            btn_reg[i] <= 1'b1;
        else
            btn_reg[i] <= btn_reg[i];
    end
end

// Set interrupt request
always @(posedge clk) begin
    if (resetN == 1'b0 || int_clr == 1'b1)
        int_req <= 1'b0; // Must read if int clear or reset
    else if (btn_pushed == 1'b1 && int_clr == 1'b0)
        int_req <= 1'b1; // Issue interrupt if any btn is pushed
    else
        int_req <= int_req;
end

always @(*) begin // Address decoding for reading registers
    // 현재는 register 값을 출력하나 차후 응용에 따라 다른 내부 값으로 바뀔 수 있다
    case (axi_araddr [ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB]) // = axi_araddr [4 : 2]
        // address 는 byte 단위이므로 32 비트 data인 경우 addr 하위 2 bit 는 불필요하다
        // 그리고 register 가 8 개 이므로 [4:2]
        3'h0 : reg_out <= r0;
        3'h1 : reg_out <= btn_reg;
        3'h2 : reg_out <= r2;
        3'h3 : reg_out <= r3;
        3'h4 : reg_out <= int_req; // btn in by polling
        3'h5 : reg_out <= r5;
        3'h6 : reg_out <= r6;
        3'h7 : reg_out <= r7;
        default : reg_out <= 0;
    endcase
end
endmodule
