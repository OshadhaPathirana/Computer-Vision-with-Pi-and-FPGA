module uart_tx_f_map(
    input clk,
    input reset,
    input transmit,
    input [7:0] data [0:5][0:5],  // Match feature_map's 8-bit width
    output reg TxD,
    output reg done_transmitting
);
    reg [5:0] row = 0;
    reg [5:0] col = 0;
    reg [7:0] tx_byte;
    reg start_tx = 0;
    
    reg [15:0] delay_counter = 0;  // Delay counter
    reg delay_done = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            row <= 0;
            col <= 0;
            TxD <= 1;
            done_transmitting <= 0;
            delay_counter <= 0;
            delay_done <= 0;
        end else if (transmit) begin
            if (!delay_done) begin
                delay_counter <= delay_counter + 1;
                if (delay_counter == 16'd50000) begin  // Adjust this value for timing
                    delay_done <= 1;
                    delay_counter <= 0;
                end
            end else begin
                tx_byte <= data[row][col];  // Send 8-bit data correctly
                start_tx <= 1;
                delay_done <= 0;

                if (col < 5) begin
                    col <= col + 1;
                end else begin
                    col <= 0;
                    row <= row + 1;
                end

                if (row == 5 && col == 5) begin
                    done_transmitting <= 1;
                end
            end
        end
    end

endmodule
