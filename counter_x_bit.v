`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 04:58:03 PM
// Design Name: 
// Module Name: counter_x_bit
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


module counter_x_bit #(parameter x = 9, n = 480)(input clk, reset, enable, updown, output reg [x-1:0] count); // A standard counter module which takes the number of bits (x) and the max value (n) as parameters
    always @(posedge clk or posedge reset) begin // The count is only updated at the positive edge of the input clock.
        if (reset)
            count <= n/2;
        else if (enable) begin
            if (count == n-1)
                count <= 0;
            else if(updown) // It increments when updown has value 1, and decrements when updown has value 0
                count <= count + 1;
            else
                count <= count - 1;
        end
    end
endmodule
