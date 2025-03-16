module uart_echo (
    input logic clk,          // 50MHz system clock
    input logic rst_n,        // Active-low reset
    input logic uart_rx,      // UART RX input
    output logic uart_tx,     // UART TX output
    output logic led_rx,      // RX indicator LED
    output logic led_tx,      // TX indicator LED
	 output logic [7:0] leds
);

    // UART Parameters
    parameter CLOCK_FREQ = 50000000;   // FPGA clock (50MHz)
    parameter BAUD_RATE  = 115200;
    parameter BAUD_DIV   = CLOCK_FREQ / BAUD_RATE;
	 
	 parameter DELAY_VALUE = 10;  // Adjust number of clock cycles as needed
	 reg [3:0] delay_counter = 0;  // Adjust width based on DELAY_VALUE

    // RX Logic
    logic [7:0] rx_data;
    logic rx_done;

    uart_rx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_done),
		  .leds(leds)
    );

    // TX Logic
    logic tx_start;
    logic tx_busy;

    uart_tx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(rx_data),//rx_data
        .tx_busy(tx_busy),
        .tx(uart_tx)
    );

    // Transmission Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_start <= 1'b0;
            led_rx   <= 1'b0;
            led_tx   <= 1'b0;
        end else begin
            if (rx_done) begin
                tx_start <= 1'b1;  // Start TX
                led_rx   <= 1'b1;  // Indicate RX
            end else if (tx_start && !tx_busy) begin
                tx_start <= 1'b0;
                led_rx   <= 1'b0;
                led_tx   <= 1'b1;  // Indicate TX
            end else if (tx_busy) begin
                led_tx   <= 1'b1;
            end else begin
                led_tx   <= 1'b0;
            end
        end
    end
endmodule
