`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Singapore University of Tech and Design
// Engineer: Xiang Maoyang 
// Create Date: 11/27/2023 11:02:18 AM
// Design Name: 
// Module Name: Segment
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Dependencies: 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module Segment(
    input rstn,
    input clk500hz,
    input [15:0] bcd_num,
    output [3:0] an,
    output [6:0] segment
);
reg [6:0] segment_r;
reg [3:0] an_r;
assign segment =  segment_r;
reg [3:0] cur_num_r;        //Register - BCD Number Display at this moment; 
assign an = ~an_r;
//Drive 7Segment Anode;
//When an_r == 0001, DIG4 will turn on;
//When an_r == 0001, at posedge clk500hz, an_r will be set to 0010(DIG3 ON);
//When an_r == 0010, at posedge clk500hz, an_r will be set to 0100(DIG2 ON);
//....
//DIG4 -> DIG3 -> DIG2 -> DIG1 -> DIG4 -> DIG3 -> DIG2 -> ...;
always @(negedge rstn,posedge clk500hz)begin
    if(!rstn)begin
        an_r <= 4'b1111;    //When system reset, empty all display;
    end
    else begin
        case(an_r)                  
        4'b1110: an_r <= 4'b1101;   //DISPLAY ON DIG3
        4'b1101: an_r <= 4'b1011;   //DISPLAY ON DIG2
        4'b1011: an_r <= 4'b0111;   //DISPLAY ON DIG1
        default: an_r <= 4'b1110;   //DISPLAY ON DIG4
        endcase
    end
end

//When DIG4 on, BCD Number Display at this moment is bcd_num[3:0];  (i.e Stop Watch - Second Unit)
//When DIG3 on, BCD Number Display at this moment is bcd_num[7:4];  (i.e Stop Watch - Second Decade)
//When DIG2 on, BCD Number Display at this moment is bcd_num[11:8]; (i.e Stop Watch - Minute Unit)
//When DIG1 on, BCD Number Display at this moment is bcd_num[15:12];(i.e Stop Watch - Minute Decade)
always @(an_r,bcd_num)begin
    case(an_r)
        4'b1110: cur_num_r <= bcd_num[3:0];
        4'b1101: cur_num_r <= bcd_num[7:4];
        4'b1011: cur_num_r <= bcd_num[11:8];
        4'b0111: cur_num_r <= bcd_num[15:12];
        default: cur_num_r <= 4'b0;
    endcase    
end

//Decode BCD NUM into corrosponding 7Segment Code;
always @(cur_num_r) begin
    case(cur_num_r)
        4'h0:segment_r <= 7'b1000000;    //NUM "0."
        4'h1:segment_r <= 7'b1001111;    //NUM "1."
        4'h2:segment_r <= 7'b0100100;    //NUM "2."
        4'h3:segment_r <= 7'b0110000;    //NUM "3."#
        4'h4:segment_r <= 7'b0011001;    //NUM "4."
        4'h5:segment_r <= 7'b0010010;    //NUM "5."#
        4'h6:segment_r <= 7'b0000010;    //NUM "6."
        4'h7:segment_r <= 7'b1111000;    //NUM "7."
        4'h8:segment_r <= 7'b0000000;    //NUM "8."
        4'h9:segment_r <= 7'b0010000;    //NUM "9."#
        4'hd:segment_r <= 7'b0100001;    //NUM "d."#
        default: segment_r <= 7'h7f;
    endcase
end

endmodule