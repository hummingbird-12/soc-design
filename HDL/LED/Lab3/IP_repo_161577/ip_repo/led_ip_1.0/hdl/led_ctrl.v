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
    // ����� register ���� ����ϳ� ���� ���뿡 ���� �ٸ� ���� ������ �ٲ� �� �ִ�
    case (axi_araddr [ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB]) // = axi_araddr [4 : 2]
        // address �� byte �����̹Ƿ� 32 ��Ʈ data�� ��� addr ���� 2 bit �� ���ʿ��ϴ�
        // �׸��� register �� 8 �� �̹Ƿ� [4:2]
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
