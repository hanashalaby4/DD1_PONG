`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2024 03:57:40 PM
// Design Name: 
// Module Name: display
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

module display (input clk, reset, p1up, p1down, p2up, p2down, dark, enable, output reg [3:0] r, g, b, output hsync, vsync, output [6:0] segments, output [3:0] anode_active, output p1s, p2s);

parameter paddleHeight = 150; // parameters which store the dimensions of the important objects of the game to avoid longer conditions.
parameter paddleWidth = 5;
parameter ball_radius = 5;

wire clk_out; // a wire which stores the 25.175 MHz clock for the display

clk_wiz_0 clk_gen (
    .clk_in1(clk),      // Input clock (100 MHz)
    .reset(reset),      // Reset signal
    .clk_out1(clk_out), // Output clock (25.175 MHz)
    .locked(locked)     // Locked signal (indicates stable clock output)
); // Clock Wizard is a built-in tool in Vivado's IP Catalog which allows us to get a more precise frequency.

// Internal signals for VGA synchronization
wire display_on;
wire [9:0] hpos;
wire [9:0] vpos;

// Instantiate the VGA synchronization module
vgaSync vgaDriver (.clk(clk_out), .reset(reset), .hsync(hsync), .vsync(vsync), .display_on(display_on), .hpos(hpos), .vpos(vpos));

wire [8:0] p1coordinate; // values to store the vertical coordinates of the paddles. The horizontal coordinates are fixed and therefore not stored.
wire [8:0] p2coordinate;

// Instantiate the Paddles for player 1 and player 2.
paddleCtrl paddle1 (.clk(clk_out), .reset(reset), .pushup(p1up), .pushdown(p1down), .vpos(480), .coord(p1coordinate));
paddleCtrl paddle2 (.clk(clk_out), .reset(reset), .pushup(p2up), .pushdown(p2down), .vpos(480), .coord(p2coordinate));

wire [9:0] ball_xCoord; // Wires to store the vertical and horizontal coordinates of the ball.
wire [8:0] ball_yCoord;
reg vCol, hCol; // registers that signify when a collision is detected.
wire ball_clk; // A wire to store the frequency of the ball's clock divider to control ball speed.
reg paused;
reg paused2;
reg gameOver;  // Wires to signify when the game ends to pause the game.
reg gameOver2;

// Modify ball and paddle control logic to respect paused state
clockDivider #(50000) clkdivBall (
    .clk(clk_out),
    .reset(reset || paused || paused2), // Stop clock when paused
    .enable(enable && (~paused|| ~paused2)), // Disable movement when paused
    .clk_out(ball_clk)
);
ballCtrl ball (
    .clk(ball_clk),
    .reset(reset || paused || paused2), // Reset ball logic when paused
    .vCol(vCol),
    .hCol(hCol),
    .enable(enable && (~paused || ~paused2)),
    .xCoord(ball_xCoord),
    .yCoord(ball_yCoord),
    .score1(p1s),
    .score2(p2s)
);
wire [11:0] ballColours; // wires to store the object colours to allow for easier and better customization
wire [11:0] paddleColours;
wire [11:0] backgroundColours;
reg [3:0] p1Score = 4'b0000;
reg [3:0] p2Score = 4'b0000;

assign ballColours = dark ? 12'b111100000000 : 12'b111100000000; // The colours are multiplexed by the dark mode switch
assign paddleColours = dark ? 12'b111111111111 : 12'b000000000000;
assign backgroundColours  = dark ? 12'b000000000000 : 12'b111111111111;

always @(posedge clk_out) begin // Collision Detection Block
    if (reset) begin // Whenever the game is reset, the collision wires are triggered to reverse the direction of the ball
        vCol <= 1'b1;
        hCol <= 1'b1;
    end else if (
    (ball_xCoord >= 30 && ball_xCoord <= 30 + paddleWidth + ball_radius &&
     ((ball_yCoord + ball_radius >= p1coordinate) || (ball_yCoord - ball_radius >= p1coordinate)) &&
     ((ball_yCoord + ball_radius <= p1coordinate + (paddleHeight / 2)) || (ball_yCoord - ball_radius <= p1coordinate + (paddleHeight / 2))))
    ||
    (ball_xCoord + ball_radius >= 602 && ball_xCoord - ball_radius <= 602 + paddleWidth &&
     ((ball_yCoord + ball_radius >= p2coordinate) || (ball_yCoord - ball_radius >= p2coordinate)) &&
     ((ball_yCoord + ball_radius <= p2coordinate + (paddleHeight / 2)) || (ball_yCoord - ball_radius <= p2coordinate + (paddleHeight / 2))))
    )begin
        hCol <= 1'b1; // The condition checks whether the ball is in the paddles region, if it is then a horizontal collision is detected 
    end else if (ball_yCoord <= ball_radius || ball_yCoord >= 480 - ball_radius) begin
        vCol <= 1'b1; // The condition checks whether the ball reaches the top or bottom walls, and when it does then a vertical collision is detected
    end else begin
        hCol <= 0; // If the ball is in neither of the above regions, then no collision is detected.
        vCol <= 0;
   end
end

always @(posedge p1s or posedge reset) begin // P1 Score Detection Block is triggered whenever p1s has a positive edge, meaning the ball just entered the scoring region for this player
        if (reset) begin // Whenever the game is reset, the player's score is reset to 0 and the game pause is stopped 
        p1Score <= 4'b0000;
        paused <= 1'b0; // Resume the game on anode_active 
        gameOver <= 0;
        end else if(p1Score == 4'b1001) begin // If the player reaches 9 points, the game is paused.
        p1Score <= p1Score; // Keep the score at 9
        paused <= 1'b1;     // Pause the game
        gameOver <= 1;
        end else if (~paused) p1Score <= p1Score + 1; // If the game hasn't ended and wasn't reset, the score is incremented when a positive edge is detected.
end

always @(posedge p2s or posedge reset) begin // Identical to P1's score detection block however it updates the appropriate player's score
    if (reset) begin
        p2Score <= 4'b0000;
        paused2 <= 1'b0; // Resume the game on reset
        gameOver2 <= 0;
    end else if (p2Score == 4'b1001) begin
        p2Score <= p2Score; // Keep the score at 9
        paused2 <= 1'b1; 
        gameOver2 <= 1;
    end else if (~paused2) begin
        p2Score <= p2Score + 1;
    end
end

// Seven-Segment Display Control
reg [1:0] en; // Enables each digit sequentially
reg [3:0] current_num; // The number to display on the active digit

wire secClk;
    clockDivider #(62500) clkdivSec (.clk(clk_out), .reset(reset), .enable(enable), .clk_out(secClk)); // This clock divider gets the appropriate frequency so that the seven segment display does not flicker

always @(posedge secClk) begin // Whenever the decoder's block has a positive edge, the enable is incremented so that the next digit can be displayed
    en <= en + 1;
end

// Assign numbers for the seven-segment display
always @(posedge clk_out) begin
    case (en)
        2'b00: current_num = p1Score; // P1 Score on left digit
        2'b01: current_num = 4'b0001; // Blank for unused digit
        2'b10: current_num = 4'b0001; // P2 Score on right digit
        2'b11: current_num = p2Score; // Blank for unused digit
        default: current_num = 4'b0000;
    endcase
end

    // Instantiate the seven segment decoder to display the scores
SevenSegDecWithEn sevenSeg (.en(en),.num(current_num), .segments(segments), .anode_active(anode_active));


    // The pong text module is instantiated to return the ascii bit of the current coordinates to display the score
wire ascii_bit;
pong_text text(.clk(clk_out), .dig0(p2Score) , .dig1(p1Score), .x(hpos) , .y(vpos), .ascii_bit(ascii_bit));


    // The game over text module is instantiated to display the game over screen at the end.
wire ascii_2;
gameOverText GO ( .clk(clk_out) , .x(hpos), .y(vpos), .ascii_bit(ascii_2));

    //This block renders the objects on the screen
always @(posedge clk_out or posedge reset) begin
    if (reset) begin // Whenever the reset is on, the screen is set to black
        r <= 4'b0000;
        g <= 4'b0000;
        b <= 4'b0000;
    end else if (display_on) begin
        if (hpos >= 30 && hpos <= 30+paddleWidth && vpos >= p1coordinate && vpos <= p1coordinate+(paddleHeight/2)) begin // The condition checks if the current pixel is where a paddle should be. If it is, then it is set to the colour of the paddles.
            r <= paddleColours[11:8]; 
            g <= paddleColours[7:4];
            b <= paddleColours[3:0];
        end else if (hpos >= 600 && hpos <= 600+paddleWidth && vpos >= p2coordinate && vpos <= p2coordinate+(paddleHeight/2)) begin // Identical to the previous condition however for the other paddle
            r <= paddleColours[11:8]; 
            g <= paddleColours[7:4];
            b <= paddleColours[3:0];
        end else if ((hpos - ball_xCoord) * (hpos - ball_xCoord) + (vpos - ball_yCoord) * (vpos - ball_yCoord) <= (ball_radius * ball_radius)) begin // Identical to the previous condition however for the ball. This utilizes the equation for a circle
            r <= ballColours[11:8]; 
            g <= ballColours[7:4];
            b <= ballColours[3:0];
        end else if ((vpos >= 32) && (vpos < 64) && (hpos[9:4] < 16)) begin // This condition checks whether the pixel is where the score should be displayed.
            if (ascii_bit) begin // If the ascii bit is 1,  meaning it should be coloured for the current number / character, it is given the ball's colours, otherwise the background colours.
                r <= ballColours[11:8]; 
                g <= ballColours[7:4];
                b <= ballColours[3:0];
            end else begin
                r <= backgroundColours[11:8];
                g <= backgroundColours[7:4];
                b <= backgroundColours[3:0];
            end
        end else if ((gameOver || gameOver2) && (vpos >= 232) && (vpos < 264) && (hpos[9:4] < 64)) begin // Identical to the previous condition however for the game over text, utilizing the game over wire.
            if (ascii_2) begin
                r <= ballColours[11:8]; 
                g <= ballColours[7:4];
                b <= ballColours[3:0];
            end else begin
                r <= backgroundColours[11:8];
                g <= backgroundColours[7:4];
                b <= backgroundColours[3:0];
            end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
        end else begin
            r <= backgroundColours[11:8]; // If none of the conditions are met, the background colour is given.
            g <= backgroundColours[7:4];
            b <= backgroundColours[3:0];
        end
    end else begin
        r <= 4'b0000;
        g <= 4'b0000;
        b <= 4'b0000;
    end
end

endmodule
