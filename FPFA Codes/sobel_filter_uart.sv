module sobel_filter_uart (
    input clk,
    input rst,
    input rx,          // UART receive line
    output reg tx,     // UART transmit line
    output reg [7:0] pixel_out,
    output reg pixel_out_valid
);
    // UART parameters
    parameter CLOCK_FREQ = 50000000;  // 50 MHz clock
    parameter BAUD_RATE = 115200;     // Baud rate
    parameter DATA_BITS = 8;          // 8 data bits
    parameter STOP_BITS = 1;          // 1 stop bit

    // UART signals
    reg [7:0] uart_rx_data;
    reg uart_rx_valid;
    reg [7:0] uart_tx_data;
    reg uart_tx_start;
    wire uart_tx_busy;

    // Instantiate UART receiver
    uart_rx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data(uart_rx_data),
        .valid(uart_rx_valid)
    );

    // Instantiate UART transmitter
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .tx(tx),
        .data(uart_tx_data),
        .start(uart_tx_start),
        .busy(uart_tx_busy)
    );

    // Sobel filter logic
    reg [7:0] line_buffer_0 [0:319];  // First row buffer
    reg [7:0] line_buffer_1 [0:319];  // Second row buffer
    reg [7:0] window [0:2][0:2];      // 3x3 pixel window

    parameter logic signed [7:0] GX [0:2][0:2] = '{
        '{-1, 0, 1},
        '{-2, 0, 2},
        '{-1, 0, 1}
    };
    parameter logic signed [7:0] GY [0:2][0:2] = '{
        '{-1, -2, -1},
        '{0, 0, 0},
        '{1, 2, 1}
    };

    // Shift pixels into the window
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset buffers and window
            for (int i = 0; i < 320; i = i + 1) begin
                line_buffer_0[i] <= 0;
                line_buffer_1[i] <= 0;
            end
            for (int i = 0; i < 3; i = i + 1) begin
                for (int j = 0; j < 3; j = j + 1) begin
                    window[i][j] <= 0;
                end
            end
        end else if (uart_rx_valid) begin
            // Shift pixels into the window
            window[0][0] <= window[0][1];
            window[0][1] <= window[0][2];
            window[0][2] <= line_buffer_0[319];
            window[1][0] <= window[1][1];
            window[1][1] <= window[1][2];
            window[1][2] <= line_buffer_1[319];
            window[2][0] <= window[2][1];
            window[2][1] <= window[2][2];
            window[2][2] <= uart_rx_data;

            // Shift line buffers
            for (int i = 319; i > 0; i = i - 1) begin
                line_buffer_0[i] <= line_buffer_0[i - 1];
                line_buffer_1[i] <= line_buffer_1[i - 1];
            end
            line_buffer_0[0] <= uart_rx_data;
            line_buffer_1[0] <= line_buffer_0[319];
        end
    end

    // Sobel filter computation
    always @(posedge clk) begin
        if (uart_rx_valid) begin
            integer gx, gy;
            gx = 0;
            gy = 0;
            for (int i = 0; i < 3; i = i + 1) begin
                for (int j = 0; j < 3; j = j + 1) begin
                    gx = gx + window[i][j] * GX[i][j];
                    gy = gy + window[i][j] * GY[i][j];
                end
            end
            pixel_out <= (gx * gx + gy * gy) > 128 ? 255 : 0;  // Thresholding
            pixel_out_valid <= 1;

            // Send processed pixel back via UART
            uart_tx_data <= pixel_out;
            uart_tx_start <= 1;
        end else begin
            pixel_out_valid <= 0;
            uart_tx_start <= 0;
        end
    end
endmodule