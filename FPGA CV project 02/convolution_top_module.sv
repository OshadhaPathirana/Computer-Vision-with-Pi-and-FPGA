module convolution_top_module(
    input clk,
    input in_RxD,
    input sw_reset,
	 output reg [7:0] led,
    output reg out_TxD
);

    localparam s_IDLE = 3'b000;
    localparam s_RX = 3'b001;
    localparam s_COMPUTE = 3'b010;
    localparam s_TX = 3'b011;
    localparam s_CLEANUP = 3'b100;

    reg [2:0] r_SM_Main = 0;
    
    // Image buffer and kernel
    reg [7:0] image_matrix [0:7][0:7];  // 8×8 binary image received from UART
    reg [3:0] feature_map [0:5][0:5];   // Increased bit width for 9-bit sums

    // Temporary storage for receiving data
    reg [7:0] rx_byte;
    reg [3:0] row = 0;
    reg [3:0] col = 0;

    // State control
    wire done_reading;
    wire done_transmitting;
    reg r_transmit = 0;
    reg r_done_reading = 0;
    reg r_done_transmitting = 0;

    // Kernel for convolution (binary)
    reg [7:0] kernel [0:2][0:2] = '{ '{1, 0, 1}, 
                                     '{0, 1, 0}, 
                                     '{1, 0, 1} }; 

    always @(posedge clk) begin
        if (sw_reset) begin
            r_SM_Main <= s_IDLE;
            row <= 0;
            col <= 0;
            r_done_reading <= 0;
            r_done_transmitting <= 0;
            r_transmit <= 0;
        end else begin
            case (r_SM_Main)
                s_IDLE: begin
                    row <= 0;
                    col <= 0;
                    r_SM_Main <= s_RX;
                end

                s_RX: begin
                    if (r_done_reading) begin
                        image_matrix[row][col] <= rx_byte;
                        if (col < 7) begin
                            col <= col + 1;
                        end else begin
                            col <= 0;
                            row <= row + 1;
                        end

                        if (row == 7 && col == 7) begin
                            r_SM_Main <= s_COMPUTE;
                        end
                        r_done_reading <= 0;
                    end else begin
                        r_done_reading <= done_reading;
                    end
                end

                s_COMPUTE: begin
                    r_SM_Main <= s_TX;
                end

                s_TX: begin
                    if (r_done_transmitting) begin
                        r_SM_Main <= s_CLEANUP;
                        r_transmit <= 0;
                    end else begin
                        r_transmit <= 1;
                        r_done_transmitting <= done_transmitting;
                    end
                end

                s_CLEANUP: begin
                    r_SM_Main <= s_IDLE;
                end

                default: r_SM_Main <= s_IDLE;
            endcase
        end
    end

    // UART receiver for image data
    uart_rx recv(clk, reset, 1'b1, RxD, done_reading, data_byte);
	 assign led = data_byte;

    // Convolution accelerator
    binary_convolution compute(
        .clk(clk), 
        .image(image_matrix), 
        .kernel(kernel), 
        .feature_map(feature_map)
    );

    // UART transmitter for feature map
    uart_tx_f_map transmitter(
        .clk(clk), 
        .reset(sw_reset), 
        .transmit(r_transmit), 
        .data(feature_map), 
        .TxD(out_TxD), 
        .done_transmitting(done_transmitting)
    );

endmodule

// Binary Convolution Module
module binary_convolution(
    input clk,
    input [7:0] image [0:7][0:7],  
    input [7:0] kernel [0:2][0:2], 
    output reg [3:0] feature_map [0:5][0:5]  // Increased to hold values up to 9
);
    integer i, j, ki, kj;
    always @(posedge clk) begin
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                feature_map[i][j] = 0;
                for (ki = 0; ki < 3; ki = ki + 1) begin
                    for (kj = 0; kj < 3; kj = kj + 1) begin
                        feature_map[i][j] = feature_map[i][j] + (image[i+ki][j+kj] * kernel[ki][kj]);
                    end
                end
            end
        end
    end
endmodule
