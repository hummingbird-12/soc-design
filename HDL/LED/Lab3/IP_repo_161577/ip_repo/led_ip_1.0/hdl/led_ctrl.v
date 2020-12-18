`timescale 1ns / 1ps

module User_Template # (
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    parameter integer OPT_MEM_ADDR_BITS = 2
)
(
    input wire clk, resetN, // reset if resetN = 0(low active)
    input wire [C_S_AXI_ADDR_WIDTH - 1:0] axi_araddr, // 5 bit addr
    input wire [C_S_AXI_DATA_WIDTH - 1:0] r0, r1, r2, r3, r4, r5, r6, r7,
    output reg [C_S_AXI_DATA_WIDTH - 1:0] reg_out
);
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;

always @(*) begin // Address decoding for reading registers
    // 현재는 register 값을 출력하나 차후 응용에 따라 다른 내부 값으로 바뀔 수 있다
    case (axi_araddr [ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB]) // = axi_araddr [4 : 2]
        // address 는 byte 단위이므로 32 비트 data인 경우 addr 하위 2 bit 는 불필요하다
        // 그리고 register 가 8 개 이므로 [4:2]
        3'h0 : reg_out <= r0;
        3'h1 : reg_out <= r1;
        3'h2 : reg_out <= r2;
        3'h3 : reg_out <= r3;
        3'h4 : reg_out <= r4;
        3'h5 : reg_out <= r5;
        3'h6 : reg_out <= r6;
        3'h7 : reg_out <= r7;
        default : reg_out <= 0;
    endcase
end
endmodule
