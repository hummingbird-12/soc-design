`timescale 1ns / 1ps

module s161577_gcd32_tb();
    reg clk, resetn, start;
    wire gcd_done;
    wire [31:0] gcd_out;
    reg [31:0] x_in, y_in, ans;
    
    reg fread_en;
    integer fp_in, fp_out;
    
    parameter half_period = 10;
    
    // Initialize
    initial begin
        clk = 1'b1;
        resetn = 1'b1;
        start = 1'b0;
        x_in = 0;
        y_in = 0;
        
        fread_en = 1'b0;
        fp_in = $fopen("C:\\WORK\\gcd_in.txt", "r");
        fp_out = $fopen("C:\\WORK\\gcd_out.txt", "w");
        
        #half_period resetn = 1'b0; // After 10ns
        #(3 * half_period) fread_en = 1'b1; // After 30ns
        $display("[TB INFO] Initialize");
    end
    
    s161577_gcd32 UUT (
        .clk(clk), .resetn(resetn), .x_in(x_in), .y_in(y_in), .start(start), .gcd_out(gcd_out), .done(gcd_done)
    );
    
    // resetn signal pulse
    always @(posedge clk) begin
        if (resetn == 0) begin
            #half_period resetn <= 1'b1;
            $display("[TB INFO] Reset");
        end
    end
    
    // Read a line from the input file
    always @(posedge clk) begin
        if (fread_en == 1'b1) begin
            if ($feof(fp_in)) begin
                $fclose(fp_in);
                $fclose(fp_out);
                $display("[TB INFO] End of simulation");
                $stop;
            end
            $fscanf(fp_in, "%d %d %d\n", x_in, y_in, ans);
            fread_en <= 1'b0;
            start <= 1'b1;
//            #(2 * half_period) start <= 1'b1;
            $display("[TB INFO] Input:\tx = %0d\ty = %0d\tanswer = %0d", x_in, y_in, ans);
        end
    end
    
    // start signal pulse
    always @(posedge clk) begin
        if (start == 1'b1) begin
            start <= 1'b0;
            $display("[TB INFO] Start UUT");
        end
    end
    
    // Check for done status
    always @(posedge clk) begin
        if (gcd_done) begin
            $fdisplay(fp_out, "%10d %10d %10d", x_in, y_in, gcd_out);
            fread_en = 1'b1;
            $display("[TB INFO] Result:\tx = %0d\ty = %0d\tresult = %0d", x_in, y_in ,gcd_out);
            $display("");
        end
    end
    
    // Clock generator (20MHz)
    always begin
        #half_period clk = ~clk;
    end
endmodule
