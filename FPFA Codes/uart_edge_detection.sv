module uart_edge_detection (
    input logic clk,          // 50MHz system clock
    input logic rst_n,        // Active-low reset
    input logic uart_rx,      // UART RX input
    output logic uart_tx,     // UART TX output
    output logic led_rx,      // RX indicator LED
    output logic led_tx       // TX indicator LED
);

    parameter CLOCK_FREQ = 50000000;   // FPGA clock (50MHz)
    parameter BAUD_RATE  = 115200;
    parameter BAUD_DIV   = CLOCK_FREQ / BAUD_RATE;

    logic [7:0] rx_data;
    logic rx_done;
    logic [7:0] processed_data;
    logic tx_start;
    logic tx_busy;

    // 3x3 Pixel Buffer (Shift Register)
    logic [7:0] pixel_buffer [0:8];

    // UART Receiver
    uart_rx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_done)
    );

    // Update 3x3 Window Buffer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_buffer[0] <= 8'd0; pixel_buffer[1] <= 8'd0; pixel_buffer[2] <= 8'd0;
            pixel_buffer[3] <= 8'd0; pixel_buffer[4] <= 8'd0; pixel_buffer[5] <= 8'd0;
            pixel_buffer[6] <= 8'd0; pixel_buffer[7] <= 8'd0; pixel_buffer[8] <= 8'd0;
        end else if (rx_done) begin
            pixel_buffer[0] <= pixel_buffer[1]; 
            pixel_buffer[1] <= pixel_buffer[2]; 
            pixel_buffer[2] <= rx_data;
            
            pixel_buffer[3] <= pixel_buffer[4]; 
            pixel_buffer[4] <= pixel_buffer[5]; 
            pixel_buffer[5] <= pixel_buffer[2];

            pixel_buffer[6] <= pixel_buffer[7]; 
            pixel_buffer[7] <= pixel_buffer[8]; 
            pixel_buffer[8] <= pixel_buffer[5];
        end
    end

    // Sobel Operator Computation
    logic signed [10:0] Gx, Gy;
    logic [7:0] G;

    // Absolute Value Computation for Gx and Gy
    logic signed [10:0] abs_Gx, abs_Gy;

    always_comb begin
        Gx = (-pixel_buffer[0] + pixel_buffer[2]) + (-2 * pixel_buffer[3] + 2 * pixel_buffer[5]) + (-pixel_buffer[6] + pixel_buffer[8]);
        Gy = (-pixel_buffer[0] - 2 * pixel_buffer[1] - pixel_buffer[2]) + (pixel_buffer[6] + 2 * pixel_buffer[7] + pixel_buffer[8]);

        // Absolute values of Gx and Gy
        abs_Gx = (Gx < 0) ? -Gx : Gx;
        abs_Gy = (Gy < 0) ? -Gy : Gy;

        // Approximate gradient magnitude
        G = (abs_Gx + abs_Gy) > 255 ? 255 : (abs_Gx + abs_Gy);
    end

    // Processed Edge Pixel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_data <= 8'b0;
        end else if (rx_done) begin
            processed_data <= G;
        end
    end

    // UART Transmitter
    uart_tx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(processed_data),
        .tx_busy(tx_busy),
        .tx(uart_tx)
    );

    // Transmission Control Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_start <= 1'b0;
            led_rx   <= 1'b0;
            led_tx   <= 1'b0;
        end else begin
            if (rx_done) begin
                tx_start <= 1'b1;  
                led_rx   <= 1'b1;  
            end else if (tx_start && !tx_busy) begin
                tx_start <= 1'b0;
                led_rx   <= 1'b0;
                led_tx   <= 1'b1;
            end else if (tx_busy) begin
                led_tx   <= 1'b1;
            end else begin
                led_tx   <= 1'b0;
            end
        end
    end
endmodule
