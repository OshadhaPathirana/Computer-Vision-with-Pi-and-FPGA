module bin_conv_uart #(parameter BAUD_DIV = 115200) (
    input clk,
    input rst_n,
    input rx,
    output tx,
    output [7:0] leds
);
    wire [7:0] rx_data;
    wire rx_done;
    reg [7:0] uart_tx_data;
    reg tx_start;
    wire tx_busy;
    reg [7:0] image [0:783];
    reg [7:0] conv_result [0:9];
    
    // 3x3 kernel (now properly initialized in reset)
    reg [7:0] kernel [0:8];
    
    // Convolution control signals
    reg [3:0] state;
    reg [3:0] k;        // Current window (0-9)
    reg [4:0] i, j;     // Kernel indices
    reg [9:0] start_row, start_col;
    reg [15:0] window_start;
    reg [7:0] sum;
    
    // Constants
    parameter IMG_WIDTH = 28;
    parameter IMG_HEIGHT = 28;
    parameter KERNEL_SIZE = 3;
    localparam 
        IDLE = 0,
        COMPUTE_WINDOW = 1,
        COMPUTE_KERNEL = 2,
        STORE_RESULT = 3;
    
    // UART components
    uart_rx #(.BAUD_DIV(BAUD_DIV)) uart_receiver (
        .clk(clk), .rst_n(rst_n), .rx(rx),
        .data_out(rx_data), .data_valid(rx_done), .leds(leds));
    
    uart_tx #(.BAUD_DIV(BAUD_DIV)) uart_transmitter (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start),
        .data_in(uart_tx_data), .tx_busy(tx_busy), .tx(tx));

    // Main control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers and memory
            for (integer idx = 0; idx < 784; idx = idx + 1)
                image[idx] <= 0;
            for (integer idx = 0; idx < 10; idx = idx + 1)
                conv_result[idx] <= 0;
                
            // Initialize kernel values
            kernel[0] <= 8'b11100011; kernel[1] <= 8'b00011000; kernel[2] <= 8'b11100011;
            kernel[3] <= 8'b11100011; kernel[4] <= 8'b00011000; kernel[5] <= 8'b11100011;
            kernel[6] <= 8'b11100011; kernel[7] <= 8'b00011000; kernel[8] <= 8'b11100011;
            
            // Control signals
            state <= IDLE;
            k <= 0;
            sum <= 0;
            start_row <= 0;
            start_col <= 0;
            window_start <= 0;
            tx_start <= 0;
            uart_tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (rx_done) begin
                        // Store received pixel
                        image[window_start] <= rx_data;
                        window_start <= window_start + 1;
                    end
                    
                    // Start convolution when image is fully received
                    if (window_start == 784) begin
                        state <= COMPUTE_WINDOW;
                        k <= 0;
                        start_row <= (0 / 3) * 8;  // Initial window position
                        start_col <= (0 % 3) * 8;
                    end
                end
                
                COMPUTE_WINDOW: begin
                    window_start <= start_row * IMG_WIDTH + start_col;
                    i <= 0;
                    j <= 0;
                    sum <= 0;
                    state <= COMPUTE_KERNEL;
                end
                
                COMPUTE_KERNEL: begin
                    if (i < KERNEL_SIZE) begin
                        if (j < KERNEL_SIZE) begin
                            // Calculate XOR and count bits
                            sum <= sum + (^ (image[window_start + i*IMG_WIDTH + j] ~^ kernel[i*3 + j]));
                            j <= j + 1;
                        end else begin
                            j <= 0;
                            i <= i + 1;
                        end
                    end else begin
                        state <= STORE_RESULT;
                    end
                end
                
                STORE_RESULT: begin
                    conv_result[k] <= sum;
                    if (k < 9) begin
                        k <= k + 1;
                        start_row <= ((k + 1) / 3) * 8;
                        start_col <= ((k + 1) % 3) * 8;
                        state <= COMPUTE_WINDOW;
                    end else begin
                        state <= IDLE;  // Convolution complete
                        window_start <= 0;  // Reset for next image
                    end
                end
            endcase
            
            // UART Transmission logic
            if (state == IDLE && window_start == 784) begin
                if (!tx_busy && k < 10) begin
                    uart_tx_data <= conv_result[k];
                    tx_start <= 1;
                    k <= k + 1;
                end else begin
                    tx_start <= 0;
                end
                
                // Auto-reset after transmission
                if (k == 10) begin
                    window_start <= 0;
                    k <= 0;
                    for (integer idx = 0; idx < 784; idx = idx + 1)
                        image[idx] <= 0;
                end
            end
        end
    end
endmodule