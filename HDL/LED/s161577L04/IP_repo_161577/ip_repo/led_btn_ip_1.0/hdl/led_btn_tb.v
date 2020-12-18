`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/29 11:40:17
// Design Name: 
// Module Name: led_btn_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led_btn_tb(
    );
   // parameter definitions
   parameter integer S_AXI_DATA_WIDTH = 32;
   parameter integer S_AXI_ADDR_WIDTH = 5;
   parameter integer LED_WIDTH = 4;
   parameter integer BTN_WIDTH = 4;
   
   parameter integer LED_BTN_BASEADDR  = 32'h43C00000;		
   parameter integer LED_OFFSET        = 0;
   parameter integer BTN_OFFSET        = 4;
   parameter integer INT_CTRL_OFFSET   = 12;
   parameter integer INT_EN_BIT        = 0;
   parameter integer INT_CLR_BIT       = 1;
   
   parameter integer INT_EN = 4'b0001, INT_DEN = 4'b0000;
   parameter integer INT_CLR = 4'b0010, INT_CLR_RST = 4'b0000;
   parameter integer MSD = 28'h0000000;
   
   
   parameter s0 = 0, s1 = 1, s2 = 2, s3 = 3, s4 = 4;
   
   // AXI signals
   reg S_AXI_ACLK    = 1'b1;
   reg S_AXI_ARESETN = 1'b1;
   reg [S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR = 0;
   reg S_AXI_AWVALID = 1'b0;
   reg [S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA = 0;
   wire [(S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB = 3'b111;  // full 32bit transfer
   reg  S_AXI_WVALID  = 1'b0;
   reg  S_AXI_BREADY;
   reg  [S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR = 0;
   reg S_AXI_ARVALID = 1'b0;
   reg  S_AXI_RREADY  = 1'b0;
   wire S_AXI_ARREADY;
   wire [S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
   wire [1:0] S_AXI_RRESP;
   wire S_AXI_RVALID;
   wire S_AXI_WREADY;
   wire [1:0] S_AXI_BRESP;
   wire S_AXI_BVALID;
   wire S_AXI_AWREADY;
   wire [2:0] S_AXI_AWPROT = 0;    // write protection type
   wire [2:0] S_AXI_ARPROT = 0;    // read protection type
   // end of AXI signals
 
   reg  [BTN_WIDTH-1 : 0] btn = 4'b0000;
   wire [LED_WIDTH-1 : 0] led;
   wire [LED_WIDTH-1 : 0] btn_read_val;
   wire irq;
   
   integer step = 0, icnt = 0, doing_int_handler = 0;
   wire [31 : 0] BASE_ADDR = LED_BTN_BASEADDR;
   

   reg S_AXI_WVALID_D;    // one clock delay of S_AXI_WVALID  
   always @(posedge S_AXI_ACLK)   // to escape vivado bug?
      S_AXI_WVALID_D <= S_AXI_WVALID;
      
   assign btn_read_val = S_AXI_RDATA[LED_WIDTH-1 : 0];
   
   always @(posedge S_AXI_ACLK) begin //***************start simulation steps ***************//
      case (step)
         4 : #1 S_AXI_AWADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + INT_CTRL_OFFSET;
         5 : begin
                #1 S_AXI_AWVALID <= 1'b1;
                S_AXI_WVALID  <= 1'b1;
                //S_AXI_WDATA[INT_EN_BIT] <= INT_EN;
                S_AXI_WDATA <= {MSD, INT_EN};
             end
        8 :
            #1 btn <= 4'b1010;  // push button push
        10 :
            #1 btn <= 4'b0000;
        37 :
            #1 btn <= 4'b0101;  // push button push
        39 :
            #1 btn <= 4'b0000;   
        //default:     
      endcase
 
      if ( S_AXI_AWVALID == 1'b1 && S_AXI_AWREADY == 1'b1)
         #1 S_AXI_AWVALID <= 1'b0;
      
      //if ( S_AXI_WVALID  == 1'b1 && S_AXI_WREADY == 1'b1 )
      if ( S_AXI_WVALID  == 1'b1 && S_AXI_WVALID_D == 1'b1 )
          S_AXI_WVALID <= 1'b0;
      
      if ( S_AXI_ARVALID == 1'b1 && S_AXI_ARREADY == 1'b1)
         #1 S_AXI_ARVALID <= 1'b0;
      
      case (icnt)   // interrupt handling phase
         1 : begin
                #1 S_AXI_AWADDR <=  BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + INT_CTRL_OFFSET;
             end
         2 : begin  // INT Disable
                #1 S_AXI_AWVALID <= 1'b1;
                   S_AXI_WVALID  <= 1'b1;
                   //S_AXI_WDATA[INT_EN_BIT]   <= INT_DEN; // interrupt disable
                   S_AXI_WDATA <= {MSD, INT_DEN};
            end
        5 : begin
                #1 S_AXI_ARADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + BTN_OFFSET; // read btn value
            end
        6 : begin    // READ LED
                #1 S_AXI_ARVALID <= 1'b1;
            end
        9 : begin
                #1 S_AXI_AWADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + INT_CTRL_OFFSET; // interrupt clr address 
            end
       10 : begin    // CLEAR Interrupt
                #1 S_AXI_AWVALID <= 1'b1;
                   S_AXI_WVALID  <= 1'b1;
                   //S_AXI_WDATA[INT_CLR_BIT]   <= INT_CLR; // interrupt clear
                   S_AXI_WDATA <= {MSD, INT_CLR};
            end
       13 : begin
               #1 S_AXI_AWADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + INT_CTRL_OFFSET; // interrupt clr address 
            end
       14 : begin    // CLEAR Intrrupt signal reset
               #1 S_AXI_AWVALID <= 1'b1;
               S_AXI_WVALID  <= 1'b1;
               //S_AXI_WDATA[INT_CLR_BIT]   <= INT_CLR_RST; // interrupt clear
               S_AXI_WDATA <= {MSD, INT_CLR_RST};
            end
       17 : begin
                #1 S_AXI_AWADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + LED_OFFSET; // write to led
            end
       18 : begin    // WRITE LED value
                #1 S_AXI_AWVALID <= 1'b1;
                   S_AXI_WVALID  <= 1'b1;
                   S_AXI_WDATA   <= btn_read_val; // btn_value
            end
       21 : begin
                #1 S_AXI_AWADDR <= BASE_ADDR[S_AXI_ADDR_WIDTH-1 : 0] + INT_CTRL_OFFSET;
            end
       22 : begin    // INT Enable
                #1 S_AXI_AWVALID <= 1'b1;
                   S_AXI_WVALID  <= 1'b1;
                   //S_AXI_WDATA[INT_EN_BIT]   <= 1'b1;       // interrupt enable
                   S_AXI_WDATA <= {MSD, INT_EN};
            end     
      endcase
   end  //***************end of main steps ***************//
   
   always @(posedge S_AXI_ACLK)    //  icnt counter
      if (doing_int_handler == 1)
         icnt <= icnt + 1;
      else
         icnt <= 0;
        
   always @(posedge S_AXI_ACLK)    //  S_AXI_BREADY gen
      if ( irq == 1 ) 
         doing_int_handler <= 1;
      else if (icnt == 24) 
         doing_int_handler <= 0;
 
   always @(posedge S_AXI_ACLK) begin    //  S_AXI_BREADY gen
      if ( S_AXI_ARESETN == 1'b0 || S_AXI_BVALID == 1'b1)
         S_AXI_BREADY <= 1'b0;
      else if (S_AXI_WVALID == 1'b1)
         S_AXI_BREADY <= 1'b1;
   end
    
   always @(posedge S_AXI_ACLK) begin    // S_AXI_RREADY gen
      if ( S_AXI_ARESETN == 1'b0 || S_AXI_RREADY == 1'b1)
         S_AXI_RREADY <= 1'b0;
      else if (S_AXI_RVALID == 1'b1)
         S_AXI_RREADY <= 1'b1;
   end
   
   always @(posedge S_AXI_ACLK)      // reset generation
      if (step == 1)
         #1 S_AXI_ARESETN <= 1'b0;
      else if (step == 2)
         #1 S_AXI_ARESETN <= 1'b1;  
   
   always begin                     // clock gen(200MHz)
      #5  S_AXI_ACLK = ~S_AXI_ACLK;
   end
      
   always @(posedge S_AXI_ACLK)     // step counter
      step <= step + 1; 
              
   led_btn_ip_v1_0 # (
       .LED_WIDTH(LED_WIDTH),
       .BTN_WIDTH(BTN_WIDTH),
       .C_S00_AXI_DATA_WIDTH(S_AXI_DATA_WIDTH),
       .C_S00_AXI_ADDR_WIDTH(S_AXI_ADDR_WIDTH)
   )
   led_btn_ip_v1_0_inst (
      .led(led), .btn(btn), .irq(irq),
      .s00_axi_aclk(S_AXI_ACLK),
      .s00_axi_aresetn(S_AXI_ARESETN),
      .s00_axi_awaddr(S_AXI_AWADDR),
      .s00_axi_awprot(S_AXI_AWPROT),
      .s00_axi_awvalid(S_AXI_AWVALID),
      .s00_axi_awready(S_AXI_AWREADY),
      .s00_axi_wdata(S_AXI_WDATA),
      .s00_axi_wstrb(S_AXI_WSTRB),
      .s00_axi_wvalid(S_AXI_WVALID),
      .s00_axi_wready(S_AXI_WREADY),
      .s00_axi_bresp(S_AXI_BRESP),
      .s00_axi_bvalid(S_AXI_BVALID),
      .s00_axi_bready(S_AXI_BREADY),
      .s00_axi_araddr(S_AXI_ARADDR),
      .s00_axi_arprot(S_AXI_ARPROT),
      .s00_axi_arvalid(S_AXI_ARVALID),
      .s00_axi_arready(S_AXI_ARREADY),
      .s00_axi_rdata(S_AXI_RDATA),
      .s00_axi_rresp(S_AXI_RRESP),
      .s00_axi_rvalid(S_AXI_RVALID),
      .s00_axi_rready(S_AXI_RREADY)
   );    
endmodule
