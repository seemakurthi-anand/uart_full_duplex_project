`timescale 1ns/1ps
module uart_top_module #(

    parameter CLK_FREQ = 50_000_000

)
(
// Module: uart
// Description: This module integrates the components of a UART interface including
// a baud rate generator, a transmitter, and a receiver. It handles both transmitting
// and receiving data at a specified baud rate, controlled by enabling signals. 

    input wire clk,         // System clock at 50 MHz
    input wire [7:0] data_in,   // 8-bit input data to be transmitted
    input wire Tx_start,           // Enable signal for transmitter
//    input wire clear,           // Not used in this instantiation (consider removal if not required)
//    input wire clk_50m,         // System clock at 50 MHz
    input wire Rx,              // Received serial data input
    input wire Rx_en,           // Enable signal for receiver
    input wire ready_clr,       // Signal to clear the ready state
	 
	 output wire Tx,             // Transmitted serial data output
    output wire Tx_busy,        // Signal indicating transmitter is busy
    output wire ready,          // Signal to indicate data is ready to be read
    output wire [7:0] data_out // 8-bit output data received

//    output [7:0] LEDR,          // LED output directly reflecting input data (for debugging or status) // Anand commented on Aug 09-2026 as its not needed
//    output wire Tx2             // Duplicate of Tx for additional interfacing // Anand commented on Aug 09-2026 as its not needed
);

    // Assign LEDs to mirror input data for visual debugging or demonstration
//    assign LEDR = data_in;

    // Duplicate the Tx signal to an additional output pin for further use
//    assign Tx2 = Tx; // Anand commented on Aug 09-2026: as its not needed

    // Internal connections for baud rate enable signals
    wire Tx_clk_en, Rx_clk_en;

    // Instantiate the baud rate generator
    baudrate #(.CLK_FREQ(CLK_FREQ)) uart_baud(
        .clk(clk),
        .Rx_clk_en(Rx_clk_en),    // Enable signal for the receiver clock
        .Tx_clk_en(Tx_clk_en)     // Enable signal for the transmitter clock
    );

    // Instantiate the transmitter module
    transmitter uart_Tx(
        .data_in(data_in),
        .Tx_start(Tx_start),
        .clk(clk),
        .Tx_clk_en(Tx_clk_en),       // Use Tx clock enable for transmitter operation
        .Tx(Tx),
        .Tx_busy(Tx_busy)
    );

    // Instantiate the receiver module
    receiver uart_Rx(
        .Rx(Rx),
        .Rx_en(Rx_en),
        .ready(ready),
        .ready_clr(ready_clr),
        .clk(clk),
        .Rx_clk_en(Rx_clk_en),       // Use Rx clock enable for receiver operation
        .data(data_out)
    );

endmodule