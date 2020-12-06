`timescale 1ns / 1ps
module TFF_3bits_tb(); // No in/out

    reg clk, reset, start_sim;
    reg [2:0] din;
    wire [3:0] led;
    wire [3:0] btn = {reset, din};
    
    // Structural description
    TFF_3bits UUT ( // UUT: instance name
        .sysclk(clk), .btn(btn), .led(led)
    ); // .called(caller)
    
    initial begin
        clk = 1'b1;
        reset = 1'b0;
        start_sim = 0;
        #30 // Delay 30ns
        reset = 1'b1;
        #20
        reset = 1'b0;
        #20
        start_sim = 1;
    end
    
    always begin // Clock gen (50MHz)
        #10
        clk = ~clk;
    end
    
    always @(posedge clk) // Input data given
        if (reset == 1'b1)
            din <= 3'b000;
        else if (start_sim == 1)
            din <= din + 1;
endmodule
