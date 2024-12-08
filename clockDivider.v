`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 05:07:18 PM
// Design Name: 
// Module Name: clockDivider
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


module clockDivider #(parameter n = 50000000)(input clk, reset, enable, output reg clk_out); // A standard parameterized clock divider module.
wire [31:0] count;
    counter_x_bit #(32, n) counterMod (.clk(clk), .reset(reset), .enable(1'b1), .count(count)); // A Counter which is used to signify when n clock cycles have been completed.
always @ (posedge clk, posedge reset) begin
    if (reset)
        clk_out <= 0;
    else if (count == n-1)
        clk_out <= ~ clk_out; // The clock signal is inverted whenever the counter has reached the limit.
end
always @(posedge clk or posedge reset) begin
    if (reset)
        $display("ClockDivider: Reset activated.");
    else
        $display("Time: %0t | clk: %b | clk_out: %b", $time, clk, clk_out);
end

endmodule

