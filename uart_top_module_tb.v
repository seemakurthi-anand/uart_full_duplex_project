`timescale 1ns/1ps

module uart_top_module_tb;

    // ============================================================
    // Clock signals
    // ============================================================

    reg clk_A = 0;
    reg clk_B = 0;




    // ============================================================
    // Data signals
    // ============================================================

    reg [7:0] data_A;
    reg [7:0] data_B;


    // ============================================================
    // Control signals
    // ============================================================

    reg Tx_start_A;
    reg Tx_start_B;

    reg Rx_en_A;
    reg Rx_en_B;

    reg ready_clr_A;
    reg ready_clr_B;
	 
	 wire Tx_A;
	 wire Tx_B;


    // ============================================================
    // UART A signals
    // ============================================================

    wire loopback_A;

    wire Tx_busy_A;
    wire ready_A;
    wire [7:0] Rx_data_A;


    // ============================================================
    // UART B signals
    // ============================================================

    wire loopback_B;

    wire Tx_busy_B;
    wire ready_B;
    wire [7:0] Rx_data_B;


    // ============================================================
    // UART A
    // ============================================================

    uart_top_module #(
        .CLK_FREQ(50_000_000)
    ) uart_A (
        .clk(clk_A),
        .data_in(data_A),
        .Tx_start(Tx_start_A),
        .Rx(Tx_B),
        .Rx_en(Rx_en_A),
        .ready_clr(ready_clr_A),
        .Tx(Tx_A),
        .Tx_busy(Tx_busy_A),
        .ready(ready_A),
        .data_out(Rx_data_A)
    );


    // ============================================================
    // UART B
    // ============================================================

    uart_top_module #(
        .CLK_FREQ(40_000_000)
    ) uart_B (
        .clk(clk_B),
        .data_in(data_B),
        .Tx_start(Tx_start_B),
        .Rx(Tx_A),
        .Rx_en(Rx_en_B),
        .ready_clr(ready_clr_B),
        .Tx(Tx_B),
        .Tx_busy(Tx_busy_B),
        .ready(ready_B),
        .data_out(Rx_data_B)
    );


    // ============================================================
    // Initial conditions
    // ============================================================

    initial begin

        $dumpfile("uart.vcd");
        $dumpvars(0, uart_top_module_tb);

        // Initial data
        data_A = 8'h00;
        data_B = 8'h10;

        // Initial control signals
        Tx_start_A = 1'b0;
        Tx_start_B = 1'b0;

        Rx_en_A = 1'b1;
        Rx_en_B = 1'b1;

        ready_clr_A = 1'b0;
        ready_clr_B = 1'b0;


        // --------------------------------------------------------
        // Request first TX for UART A
        // --------------------------------------------------------

        @(posedge clk_A);
        Tx_start_A = 1'b1;

        @(posedge clk_A);
        Tx_start_A = 1'b0;


        // --------------------------------------------------------
        // Request first TX for UART B
        // --------------------------------------------------------

        @(posedge clk_B);
        Tx_start_B = 1'b1;

        @(posedge clk_B);
        Tx_start_B = 1'b0;

    end


    // ============================================================
    // UART A ready
    // ============================================================

    integer count_A;

    initial begin
        count_A = 0;
    end
	 
	 
     // UART A = 50 MHz
    always #10 clk_A = ~clk_A;

    // UART B = 40 MHz
    always #12.5 clk_B = ~clk_B;
	 
	 
// This below is when module A connected to module B	 

	always @(posedge ready_A) begin

		 #20 ready_clr_A <= 1'b1;  // Clear the ready signal after a delay to process the received data
		 #20 ready_clr_A <= 1'b0;  // Reset the ready clear signal // anand changed to 20

		 if (Rx_data_A != data_B) begin

			  // A received data from UART B
			  $display("FAIL UART A: [time: %0t] Rx data %x does not match with data sent from Tx of moduleB %x",
						  $time, Rx_data_A, data_B);
			  //$finish;  // End the simulation

		 end
		 else begin

			  $display("SUCCESS UART A: [time: %0t] Rx data %x match with data sent from Tx of moduleB %x",
						  $time, Rx_data_A, data_B);

			  // Prepare for the next test iteration
			  data_B <= data_B + 1'b1;  // Increment data to be sent by UART B

			  Tx_start_B <= 1'b0;        // Keep TX start inactive
			  Rx_en_A <= 1'b1;           // Keep UART A receiver enabled

			  @(posedge clk_B);
			  Tx_start_B <= 1'b1;        // Request one TX from UART B

			  @(posedge clk_B);
			  Tx_start_B <= 1'b0;        // Disable TX again
		 end
	end


	always @(posedge ready_B) begin

		 #25 ready_clr_B <= 1'b1;  // Clear the ready signal after a delay to process the received data
		 #25 ready_clr_B <= 1'b0;  // Reset the ready clear signal // anand changed to 20

		 if (Rx_data_B != data_A) begin

			  // B received data from UART A
			  $display("FAIL UART B: [time: %0t] Rx data %x does not match with data sent from Tx of moduleA %x",
						  $time, Rx_data_B, data_A);
			  //$finish;  // End the simulation

		 end
		 else begin

			  $display("SUCCESS UART B: [time: %0t] Rx data %x match with data sent from Tx of moduleA %x",
						  $time, Rx_data_B, data_A);

			  // Prepare for the next test iteration
			  data_A <= data_A + 1'b1;  // Increment data to be sent by UART A

			  Tx_start_A <= 1'b0;        // Keep TX start inactive
			  Rx_en_B <= 1'b1;           // Keep UART B receiver enabled

			  @(posedge clk_A);
			  Tx_start_A <= 1'b1;        // Request one TX from UART A

			  @(posedge clk_A);
			  Tx_start_A <= 1'b0;        // Disable TX again
		 end
	end

	 
// This below data sending , test is for loopback case	 

//    always @(posedge ready_A) begin
//
//        #20 ready_clr_A <= 1'b1;  // Clear the ready signal after a delay to process the received data
//        #20 ready_clr_A <= 1'b0;  // Reset the ready clear signal // anand changed to 20
//
//
//        if (Rx_data_A != data_A) begin
//
//            // If the received data does not match the sent data, print an error message
//            $display("FAIL UART A: [time: %0t] rx data %x does not match tx %x",
//                     $time, Rx_data_A, data_A);
//            //$finish;  // End the simulation
//
//        end
//        else begin
//
//            // Check for specific data value to determine end of the test
//            //            if (Rx_data_A == 8'h09) begin
//            //                $display("SUCCESS UART A: all bytes verified");
//            //$finish;  // End the simulation
//            //            end
//
//            $display("SUCCESS UART A: [time: %0t] rx data %x match tx %x",
//                     $time, Rx_data_A, data_A);
//
//
//            // ----------------------------------------------------
//            // Prepare for the next test iteration
//            // ----------------------------------------------------
//
//            if (count_A < 9) begin
//
//                count_A = count_A + 1;
//
//                data_A <= data_A + 1'b1;
//
//                Tx_start_A <= 1'b0;       // Re-enable the transmitter
//                Rx_en_A <= 1'b1;          // Keep the receiver enabled
//
//
//                //            #20 enable <= 1'b0;    // Toggle enable signals to mimic behavior //Anand commented as bcz en is active low again again the fsm of transmistter is started although data is same.so it shld be made back to '1'(off bcz active low)
//
//
//                @(posedge clk_A);
//                Tx_start_A <= 1'b1;       // request one TX
//
//                @(posedge clk_A);
//                Tx_start_A <= 1'b0;       // Disable TX again
//
//            end
//
//        end
//
//    end
//
//
//    // ============================================================
//    // UART B ready
//    // ============================================================
//
//    integer count_B;
//
//    initial begin
//        count_B = 0;
//    end
//
//    always @(posedge ready_B) begin
//
//        #20 ready_clr_B <= 1'b1;  // Clear the ready signal after a delay to process the received data
//        #20 ready_clr_B <= 1'b0;  // Reset the ready clear signal // anand changed to 20
//
//
//        if (Rx_data_B != data_B) begin
//
//            // If the received data does not match the sent data, print an error message
//            $display("FAIL UART B: [time: %0t] rx data %x does not match tx %x",
//                     $time, Rx_data_B, data_B);
//            //$finish;  // End the simulation
//
//        end
//        else begin
//
//            // Check for specific data value to determine end of the test
//            //            if (Rx_data_B == 8'h19) begin
//            //                $display("SUCCESS UART B: all bytes verified");
//            //$finish;  // End the simulation
//            //            end
//
//            $display("SUCCESS UART B: [time: %0t] rx data %x match tx %x",
//                     $time, Rx_data_B, data_B);
//
//
//            // ----------------------------------------------------
//            // Prepare for the next test iteration
//            // ----------------------------------------------------
//
//            if (count_B < 9) begin
//
//                count_B = count_B + 1;
//
//                data_B <= data_B + 1'b1;
//
//                Tx_start_B <= 1'b0;       // Re-enable the transmitter
//                Rx_en_B <= 1'b1;          // Keep the receiver enabled
//
//
//                //            #20 enable <= 1'b0;    // Toggle enable signals to mimic behavior //Anand commented as bcz en is active low again again the fsm of transmistter is started although data is same.so it shld be made back to '1'(off bcz active low)
//
//
//                @(posedge clk_B);
//                Tx_start_B <= 1'b1;       // request one TX
//
//                @(posedge clk_B);
//                Tx_start_B <= 1'b0;       // Disable TX again
//
//            end
//
//        end
//
//    end

endmodule

//`timescale 1ns/1ps
//
//module uart_top_module_tb();
//
//    // ============================================================
//    // Clock signals
//    // ============================================================
//
//    reg clk_A = 0;
//    reg clk_B = 0;
//
//    // UART A clock = 50 MHz
//    // Period = 20 ns
//    always #10 clk_A = ~clk_A;
//
//    // UART B clock = 40 MHz
//    // Period = 25 ns
//    always #12.5 clk_B = ~clk_B;
//
//
//    // ============================================================
//    // Data signals
//    // ============================================================
//
//    reg [7:0] data_A = 0;
//    reg [7:0] data_B = 0;
//
//
//    // ============================================================
//    // Control signals
//    // ============================================================
//
//    reg Tx_start_A = 0;
//    reg Tx_start_B = 0;
//
//    reg Rx_en_A = 1;
//    reg Rx_en_B = 1;
//
//    reg ready_clr_A = 0;
//    reg ready_clr_B = 0;
//
//
//    // ============================================================
//    // UART A signals
//    // ============================================================
//
//    wire Tx_A;
//    wire Tx_busy_A;
//    wire ready_A;
//    wire [7:0] Rx_data_A;
//
//    wire loopback_A;
//
//
//    // ============================================================
//    // UART B signals
//    // ============================================================
//
//    wire Tx_B;
//    wire Tx_busy_B;
//    wire ready_B;
//    wire [7:0] Rx_data_B;
//
//    wire loopback_B;
//	 integer i,j;
//
//    // ============================================================
//    // UART A
//    // ============================================================
//
//    uart_top_module #(
//        .CLK_FREQ(50_000_000)
//    ) uart_A (
//        .clk(clk_A),
//        .data_in(data_A),
//        .Tx_start(Tx_start_A),
//        .Rx(loopback_A),
//        .Rx_en(Rx_en_A),
//        .ready_clr(ready_clr_A),
//        .Tx(loopback_A),
//        .Tx_busy(Tx_busy_A),
//        .ready(ready_A),
//        .data_out(Rx_data_A)
//    );
//
//
//    // ============================================================
//    // UART B
//    // ============================================================
//
//    uart_top_module #(
//        .CLK_FREQ(40_000_000)
//    ) uart_B (
//        .clk(clk_B),
//        .data_in(data_B),
//        .Tx_start(Tx_start_B),
//        .Rx(loopback_B),
//        .Rx_en(Rx_en_B),
//        .ready_clr(ready_clr_B),
//        .Tx(loopback_B),
//        .Tx_busy(Tx_busy_B),
//        .ready(ready_B),
//        .data_out(Rx_data_B)
//    );
//
//
//    // ============================================================
//    // Test
//    // ============================================================
//
//    initial begin
//
//        $dumpfile("uart.vcd");
//        $dumpvars(0, uart_top_module_tb);
//
//        // Initial values
//        data_A = 8'h00;
//        data_B = 8'h10;
//
//        Tx_start_A = 0;
//        Tx_start_B = 0;
//
//        Rx_en_A = 1;
//        Rx_en_B = 1;
//
//        ready_clr_A = 0;
//        ready_clr_B = 0;
//	 end	  
//		  
//	 initial begin
//
////        @(posedge clk_A);
//
//		 // Send 10 bytes from UART A
//		 for ( i = 0; i < 10; i = i + 1) begin
//
//			  @(posedge clk_A);
//			  Tx_start_A <= 1;
//
//			  @(posedge clk_A);
//			  Tx_start_A <= 0;
//
//			  // Wait until current transmission is complete
////			  wait(Tx_busy_A == 0); //Anand commented
//
//			  data_A <= data_A + 1'b1;
//		 end
//
//	 end
//	 initial begin
//        
////		 @(posedge clk_B);
//
//		 // Send 10 bytes from UART B
//		 for ( j = 0; j < 10; j = j + 1) begin
//
//			  @(posedge clk_B);
//			  Tx_start_B <= 1;
//
//			  @(posedge clk_B);
//			  Tx_start_B <= 0;
//
//			  // Wait until current transmission is complete
////			  wait(Tx_busy_B == 0);
//
//			  data_B <= data_B + 1'b1;
//		 end		 
//		 
//
//
//    end
//
//
//    // ============================================================
//    // Check UART A receiver
//    // ============================================================
//
//    always @(posedge ready_A) begin
//
//        if (Rx_data_A == data_A) begin
//            $display("SUCCESS UART A: Rx_data = %h, expected = %h",
//                     Rx_data_A, data_A);
//        end
//        else begin
//            $display("FAIL UART A: Rx_data = %h, expected = %h",
//                     Rx_data_A, data_A);
//        end
//
//        // Clear ready
//        @(posedge clk_A);
//        ready_clr_A <= 1;
//
//        @(posedge clk_A);
//        ready_clr_A <= 0;
//
//    end
//
//
//    // ============================================================
//    // Check UART B receiver
//    // ============================================================
//
//    always @(posedge ready_B) begin
//
//        if (Rx_data_B == data_B) begin
//            $display("SUCCESS UART B: Rx_data = %h, expected = %h",
//                     Rx_data_B, data_B);
//        end
//        else begin
//            $display("FAIL UART B: Rx_data = %h, expected = %h",
//                     Rx_data_B, data_B);
//        end
//
//        // Clear ready
//        @(posedge clk_B);
//        ready_clr_B <= 1;
//
//        @(posedge clk_B);
//        ready_clr_B <= 0;
//
//    end
//
//endmodule
//
//
//
//
////// Testbench Module: uart_TB
////// Description: This testbench is designed to verify the functionality of a UART module 
////// by implementing a serial loopback. It transmits data bytes and checks if the received 
////// data matches the transmitted data. This ensures both the transmitter and receiver 
////// components of the UART are functioning correctly.
////
//////`include "uart.v" // Include the UART module definition
////`timescale 1ns/1ps
////module uart_top_module_tb();
////
////
////
////	reg clk_A = 0;
////	reg clk_B = 0;
////
////	reg [7:0] data_A = 0;
////	reg [7:0] data_B = 0;
////
////	reg Tx_start_A = 0;
////	reg Tx_start_B = 0;
////
////	reg Rx_en_A = 1;
////	reg Rx_en_B = 1;
////
////	reg ready_clr_A = 0;
////	reg ready_clr_B = 0;
////
////	wire Tx_A;
////	wire Tx_B;
////
////	wire ready_A;
////	wire ready_B;
////
////	wire [7:0] Rx_data_A;
////	wire [7:0] Rx_data_B;
////
////	wire Tx_busy_A;
////	wire Tx_busy_B;	
////	
////    // Testbench control signals
////
////    // Loopback wire for connecting Tx and Rx internally
////    wire loopback;
////
////    // Instantiation of the both UART modules
////    uart_top_module #(.CLK_FREQ(50000000))uart_module_1(
////        .clk(clk_A),
////        .data_in(data_A),
////        .Tx_start(Tx_start_A),
////		  .Rx(loopback_A),
////        .Rx_en(Rx_en_A),       // Connect the Rx_en signal
////        .ready_clr(ready_clr_A),
////        .Tx(loopback_A),
////        .Tx_busy(Tx_busy_A),
////        .ready(ready_A),
////        .data_out(Rx_data_A)
////    );
////	 
////	 
////     uart_top_module #(.CLK_FREQ(40000000))uart_module_2(
////        .clk(clk_B),
////        .data_in(data_B),
////        .Tx_start(Tx_start_B),
////		  .Rx(loopback_B),
////        .Rx_en(Rx_en_B),       // Connect the Rx_en signal
////        .ready_clr(ready_clr_B),
////        .Tx(loopback_B),
////        .Tx_busy(Tx_busy_B),
////        .ready(ready_B),
////        .data_out(Rx_data_B)
////    );
////
////
////
////	initial begin
////		 $dumpfile("uart.vcd");  // Set up the VCD file for waveform analysis
////		 $dumpvars(0, uart_top_module_tb);  // Record simulation data for all variables in the testbench
////		 
////        // Initial values
////        data_A = 8'h55;
////        data_B = 8'hA3;
////
////        Tx_start_A = 0;
////        Tx_start_B = 0;
////
////        Rx_en_A = 1;
////        Rx_en_B = 1;
////
////        ready_clr_A = 0;
////        ready_clr_B = 0;
////
////
////        // --------------------------------------------------------
////        // Start transmission from UART A
////        // --------------------------------------------------------
////
////        @(posedge clk_A);
////        Tx_start_A <= 1;
////
////        @(posedge clk_A);
////        Tx_start_A <= 0;
////
////
////    // Clock generation
////    always begin
////        #10 clk_A = ~clk_A;  // Toggle the clock every time unit to simulate a 50MHz clock 
////		  // anand changed to 10 instead of 1
////    end
////	 
////    always begin
////        #12.5 clk_B = ~clk_B;  
////    end	 
////	 
////	always @(posedge ready) begin
////
////		 #20 ready_clr <= 1;  // Clear the ready signal after a delay to process the received data
////		 #20 ready_clr <= 0;  // Reset the ready clear signal // anand changed to 20
////
////		 if (Rx_data != data) begin
////			  // If the received data does not match the sent data, print an error message
////			  $display("FAIL: [time: %0t] rx data %x does not match tx %x",
////						  $time, Rx_data, data);
////
////		 end else begin
////			  // Check for specific data value to determine end of the test
////
////
////			  $display("SUCCESS: [time: %0t] rx data %x match tx %x",
////						  $time, Rx_data, data);
////
////			  // Prepare for the next test iteration
////			  data <= data + 1'b1;  // Increment the data to send
////
////			  Tx_start <= 1'b0;       // Re-enable the transmitter
////			  Rx_en <= 1'b1;        // Keep the receiver enabled
////
////			  //            #20 enable <= 1'b0;    // Toggle enable signals to mimic behavior //Anand commented as bcz en is active low again again the fsm of transmistter is started although data is same.so it shld be made back to '1'(off bcz active low)
////
////			  @(posedge clk);
////			  Tx_start <= 1'b1;       // request one TX
////
////			  @(posedge clk);
////			  Tx_start <= 1'b0;       // Disable TX again
////		 end
////	end
////
////
////
////
////
////endmodule