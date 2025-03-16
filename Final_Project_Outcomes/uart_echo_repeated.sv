module uart_echo_repeated (
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
	 
	parameter DELAY_VALUE = 10;  // Adjust number of clock cycles as needed (optional for delay)
	 
	// RX and TX Signals
    logic [7:0] rx_data;
    logic rx_done;
    logic tx_start;
    logic tx_busy;
	
	// Internal Registers
    reg [7:0] data_buffer = 8'd0;      // Store received data
    reg [3:0] tx_count = 4'd0;         // Count how many times data has been transmitted (up to 10)
    reg [3:0] delay_counter = 0;       // Optional delay counter for spacing between transmissions
    reg transmitting = 0;              // Flag to indicate ongoing 10x transmission

    // Instantiate RX
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

    // Instantiate TX
    uart_tx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(data_buffer),  // Use buffered data, not live rx_data
        .tx_busy(tx_busy),
        .tx(uart_tx)
    );

    // Main Control Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_start <= 1'b0;
            led_rx <= 1'b0;
            led_tx <= 1'b0;
            data_buffer <= 8'd0;
            tx_count <= 4'd0;
            transmitting <= 1'b0;
            delay_counter <= 0;
        end else begin
            // If new data received and not currently transmitting 10 times
            if (rx_done && !transmitting) begin
                data_buffer <= rx_data;  // Store received byte
                tx_count <= 4'd0;        // Reset transmit counter
                transmitting <= 1'b1;    // Start transmission sequence
                led_rx <= 1'b1;          // RX indicator
            end

            // Handle 10 times transmission
            if (transmitting) begin
                // If not busy, start TX
                if (!tx_busy && !tx_start) begin
                    // Optional delay between sends
                    if (delay_counter < DELAY_VALUE) begin
                        delay_counter <= delay_counter + 1;
                        tx_start <= 1'b0;
                    end else begin
                        tx_start <= 1'b1;  // Trigger transmit
                        delay_counter <= 0; // Reset delay counter
                    end
                end else if (tx_start && tx_busy) begin
                    tx_start <= 1'b0;  // Clear start once busy
                end

                // Count completed transmissions
                if (!tx_busy && !tx_start && delay_counter == 0) begin
                    if (tx_count < 4'd9) begin
                        tx_count <= tx_count + 1;
                    end else begin
                        transmitting <= 1'b0;  // Done transmitting 10 times
                        led_rx <= 1'b0;        // Turn off RX indicator
                    end
                end
            end

            // LED TX indicator
            if (tx_busy || tx_start) begin
                led_tx <= 1'b1;
            end else begin
                led_tx <= 1'b0;
            end
        end
    end

endmodule
