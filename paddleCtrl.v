`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 01:51:02 PM
// Design Name: 
// Module Name: paddleCtrl
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

module paddleCount #(parameter x = 9, n = 480, s = 200)(input clk, reset, enable, updown, output reg [x-1:0] count); // Counter to determine the paddle's vertical position.
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= n/2; // The value is set to the middle when it is reset. 
        else if (enable) begin
            if (count == n-(75)) // The coordinates are set to the middle of the paddle, so when the middle is 75 below the top, movement is reversed for 1 pixel.
                count <= count -1;
            else if (count == 0)
                count <= count + 1;
            else if(updown)
                count <= count + 1;
            else
                count <= count - 1;
        end
    end
endmodule

module paddleCtrl(input clk, reset, pushup, pushdown, vpos, output [8:0] coord);

wire upwire, downwire;
    debouncer deb1(.clk(clk), .rst(reset), .in(pushup), .out(upwire)); // debouncers to avoid accidental or unneeded inputs.
debouncer deb2(.clk(clk), .rst(reset), .in(pushdown), .out(downwire));

wire clk_out;
    clockDivider #(50000) clkdiv (.clk(clk), .reset(reset), .enable(1'b1), .clk_out(clk_out)); // a clock divider to control the paddle's speed.

wire countEn;
assign countEn = pushup ^ pushdown; // the enable is set to the xor of the 2 as when they are both pressed there should be no movement.

paddleCount #(9,480) vcount(clk_out, reset, countEn, upwire, coord);

endmodule
