//module bin_conv_uart #(parameter BAUD_DIV = 115200) (
//    input clk,
//    input rst_n,
//    input rx,
//    output tx,
//    output [7:0] leds
//);
//    wire [7:0] rx_data;
//    wire rx_done;
//    reg [7:0] uart_tx_data;
//    reg tx_start;
//    wire tx_busy;
//    reg [7:0] image [0:783];  // 28x28 image storage
//    reg [7:0] conv_result [0:9];  // 10 values of 8 bits each  // Output feature map (10 values)
//    
//    reg [7:0] kernel [0:8]; // 3x3 binary kernel
//    initial begin
//        kernel[0] = 8'b11100011; kernel[1] = 8'b00011000; kernel[2] = 8'b11100011;
//        kernel[3] = 8'b11100011; kernel[4] = 8'b00011000; kernel[5] = 8'b11100011;
//        kernel[6] = 8'b11100011; kernel[7] = 8'b00011000; kernel[8] = 8'b11100011;
//    end
//    
//    integer i, j, k, row, col;
//    integer window_start;
//    integer sum;
//    
//    reg [9:0] pixel_count;
//    reg [3:0] result_count;
//    reg conv_done;
//    reg computing;
//     
//    //delay
//    parameter DELAY_VALUE = 12;  // Adjust number of clock cycles as needed
//    reg [3:0] delay_counter;  // Adjust width based on DELAY_VALUE
//    
//    // Constants for image dimensions
//    parameter IMG_WIDTH = 28;
//    parameter IMG_HEIGHT = 28;
//    parameter KERNEL_SIZE = 3;
//    
//    // UART Receiver Instance
//    uart_rx #( 
//        .BAUD_DIV(BAUD_DIV)
//    ) uart_receiver (
//        .clk(clk),
//        .rst_n(rst_n),
//        .rx(rx),
//        .data_out(rx_data),
//        .data_valid(rx_done),
//        .leds(leds)
//    );
//    
//    // UART Transmitter Instance
//    uart_tx #( 
//        .BAUD_DIV(BAUD_DIV)
//    ) uart_transmitter (
//        .clk(clk),
//        .rst_n(rst_n),
//        .tx_start(tx_start),
//        .data_in(uart_tx_data),
//        .tx_busy(tx_busy),
//        .tx(tx)
//    );
//
//    // Main control logic
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            for (i = 0; i < 784; i = i + 1)
//                image[i] <= 0;
//            for (i = 0; i < 10; i = i + 1)
//                conv_result[i] <= 0;
//            pixel_count <= 0;
//            result_count <= 0;
//            conv_done <= 0;
//            computing <= 0;
//            tx_start <= 0;
//            delay_counter <= 0;
//        end else begin
//            // Default assignments
//            tx_start <= 0;
//            
//            // Image receiving
//            if (rx_done && pixel_count < 784) begin
//                image[pixel_count] <= rx_data;
//                pixel_count <= pixel_count + 1;
//            end
//            
//            // Start convolution when image is received
//            if (pixel_count == 784 && !computing && !conv_done) begin
//                computing <= 1;
//                
//                // Compute convolution for 10 different windows
//                for (k = 0; k < 10; k = k + 1) begin
//                    // Calculate starting position for each window
//                    // We'll take windows from different regions of the image
//                    row = (k / 3) * 8;  // Distribute vertically
//                    col = (k % 3) * 8;  // Distribute horizontally
//                    window_start = row * IMG_WIDTH + col;
//                    
//                    sum = 0;
//                    // Process 3x3 window
//                    for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
//                        for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
//                            // Calculate position in the image
//                            sum = sum + (^ (image[window_start + i*IMG_WIDTH + j] ~^ kernel[i*KERNEL_SIZE + j]));
//                        end
//                    end
//                    conv_result[k] <= sum;  // Store the actual computed sum
//                end
//                conv_done <= 1;
//            end
//            
//            // Transmit results
//            if (conv_done && !tx_busy) begin
//                if (result_count < 10) begin
//                    uart_tx_data <= conv_result[result_count];  // Send actual result
//                    
//                    if (delay_counter == 0) begin  // Start new transmission
//                        tx_start <= 1;
//                        delay_counter <= delay_counter + 1;
//                    end else if (delay_counter == 1) begin  // Clear start signal
//                        tx_start <= 0;
//                        delay_counter <= delay_counter + 1;
//                    end else if (delay_counter == DELAY_VALUE) begin  // Wait for delay
//                        delay_counter <= 0;
//                        result_count <= result_count + 1;
//                    end else begin
//                        delay_counter <= delay_counter + 1;
//                    end
//                end
//            end
//        end
//    end
//
//endmodule





























//module bin_conv_uart #(parameter BAUD_DIV = 115200) (
//    input clk,
//    input rst_n,
//    input rx,
//    output tx,
//    output [7:0] leds
//);
//
//    wire [7:0] rx_data;
//    wire rx_done;
//    reg [7:0] uart_tx_data;
//    reg tx_start;
//    wire tx_busy;
//
//    reg [7:0] image [0:783];  // 28x28 image storage
//	 reg [9:0] conv_result [0:9];  // Output feature map (dummy 10 values)
//    
//	 reg [7:0] kernel [0:8]; // 3x3 binary kernel
//	 initial begin
//		kernel[0] = 8'b11100011; kernel[1] = 8'b00011000; kernel[2] = 8'b11100011;
//		
//		kernel[3] = 8'b11100011; kernel[4] = 8'b00011000; kernel[5] = 8'b11100011;
//		
//		kernel[6] = 8'b11100011; kernel[7] = 8'b00011000; kernel[8] = 8'b11100011;
//	 end
//    
//    integer i, j, sum;
//    reg [9:0] pixel_count;
//
//    // UART Receiver Instance
//    uart_rx #( 
//        .BAUD_DIV(BAUD_DIV)
//    ) uart_receiver (
//        .clk(clk),
//        .rst_n(rst_n),
//        .rx(rx),
//        .data_out(rx_data),
//        .data_valid(rx_done),
//        .leds(leds)
//    );
//
//    // UART Transmitter Instance
//    uart_tx #( 
//        .BAUD_DIV(BAUD_DIV)
//    ) uart_transmitter (
//        .clk(clk),
//        .rst_n(rst_n),
//        .tx_start(tx_start),
//        .data_in(uart_tx_data),
//        .tx_busy(tx_busy),
//        .tx(tx)
//    );
//
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            for (i = 0; i < 784; i = i + 1)
//                image[i] <= 0;
//            pixel_count <= 0;
//        end else if (rx_done && pixel_count < 784) begin
//            image[pixel_count] <= rx_data;
//            pixel_count <= pixel_count + 1;
//        end
//    end
//
//    always @(posedge clk) begin
//        if (pixel_count == 784) begin  // Start convolution after receiving full image
//            for (i = 0; i < 9; i = i + 1) begin
//                sum = 0;
//                for (j = 0; j < 9; j = j + 1) begin
//                    sum = sum + (^ (image[i*9+j] ~^ kernel[j])); // XNOR + Popcount
//                end
//                conv_result[i] <= sum;
//            end
//        end
//    end
//
//    always @(posedge clk) begin
//        if (!tx_busy) begin
//            uart_tx_data <= conv_result[0];
//            tx_start <= 1;
//        end else begin
//            tx_start <= 0;
//        end
//    end
//endmodule
