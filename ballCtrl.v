`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 11:54:47 AM
// Design Name: 
// Module Name: ballCtrl
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

module ballvCount #(parameter x = 9, n = 480)(input clk, reset, rst, enable, updown, output reg [x-1:0] count); // counter to calculate the vertical coordinate of the ball on the display.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= n/2; // whenever the reset is enabled, the ball is reset to the middle vertically.
        end else if (enable) begin
            if (rst) 
                count <= n/2;
            else if(updown) // the updown input controls whether the ball is moving up or down by incrementing when its value is high
                count <= count + 1;
            else
                count <= count - 1;
        end
    end
endmodule

module ballhCount #(parameter x = 10, n = 640)(input clk, reset, rst, enable, updown, output reg [x-1:0] count); // Identical to the vertical counter however with a few extra conditions to allow resetting once the ball crosses one of the edges
    always @(posedge clk or posedge reset) begin
        if (reset || rst) begin
            count <= n/2;
        end else if (enable) begin
            if (count == 639 || count == 1 || rst) // Checks if the ball is at the edge of the screen to then reset it to the center.
                count <= n/2;
            else if(updown) // updown input controls the direction of the ball movement, with HIGH being towards the right
                count <= count + 1;
            else
                count <= count - 1;
        end
    end
endmodule

module ballCtrl(input clk, reset, vCol, hCol, enable, output reg [9:0] xCoord, output reg [8:0] yCoord, output reg score1, score2);

    reg vDirection=1; // a register storing the current vertical direction of the ball, with 1 being downwards.
    reg hDirection=1; // a refister storing the current horizontal direction of the ball, with 1 being to the right.
    reg rst = 0;
    
    wire [9:0] hCountOut; // wire vectors to store the current coordinates of the ball.
    wire [8:0] vCountOut;

    // The counter modules were instantiated using the direction as the updown input.
    ballvCount #(9,480) vcount(clk, reset, rst, enable, vDirection, vCountOut);
    ballhCount #(10,640) hcount(clk, reset, rst, enable, hDirection, hCountOut);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score1 <= 1'b0;
            score2 <= 1'b0;
        end else if (hCountOut <= 20) begin
            score2 <= 1'b1; // A signal which signifies when P2 scores, enabled when the ball is behind P1's paddle
        end else if (hCountOut >= 620) begin
            score1<= 1'b1; // A signal which signifies when P1 scores, enabled when the ball is behind P2's paddle
        end else begin
            score1 <= 1'b0; // If the ball is not in either scoring regions, both values are set to 0.
            score2 <= 1'b0;
        end
    end
   
    always @(posedge clk) begin
        if (reset || xCoord < 1 || xCoord > 639) begin // This resets the ball's position if it is outside the screen's boundaries.
            xCoord <= 320;
            yCoord <= 240;
            rst <=1;
        end else if (enable) begin // otherwise, the coordinates are stored in the output vectors.
            xCoord <= hCountOut;
            yCoord <= vCountOut;
            rst <=0;
        end
    end
    
    always @(posedge vCol) begin // Whenever there is a vertical collision, the ball's vertical direction is inverted.
        vDirection <= ~vDirection;
    end
    always @(posedge hCol) begin // Whenever there is a horizontal collision, the ball's horizontal direction is inverted.
        hDirection <= ~hDirection;
    end
    
endmodule
