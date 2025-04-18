`timescale 1ps / 1ps
module tb_bin_conv_uart;

    // Inputs
    reg clk;
    reg rst_n;
    reg rx;
    
    // Outputs
    wire tx;
    wire [7:0] leds;
    
    // Instantiate the module
    bin_conv_uart #(.BAUD_DIV(12)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),
        .leds(leds)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        rst_n = 0;
        rx = 1;  // Idle state for UART
        #100;
        
        // Release reset
        rst_n = 1;
        #100;
        
        // Simulate UART RX sending a 28x28 image
        for (integer i = 0; i < 784; i = i + 1) begin
            rx = 0;  // Start bit
            #10416;  // 1 bit time for 9600 baud rate
            for (integer j = 0; j < 8; j = j + 1) begin
                rx = $random;  // Random data for testing
                #10416;
            end
            rx = 1;  // Stop bit
            #10416;
        end
        
        // Wait for convolution to complete
        #1000000;
        
        // Check UART TX output (use a waveform viewer or print statements)
        $display("Simulation complete.");
        $stop;
    end
endmodule