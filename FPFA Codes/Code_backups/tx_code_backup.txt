module uart_tx #(
    parameter BAUD_DIV = 434
) (
    input logic clk,
    input logic rst_n,
    input logic tx_start,
    input logic [7:0] data_in,
    output logic tx_busy,
    output logic tx
);
    logic [9:0] tx_shift;  // 10 bits: Start(1) + 8 Data + Stop(1)
    logic [3:0] bit_count;
    logic [11:0] baud_counter;
    logic tx_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_active <= 0;
            baud_counter <= 0;
            tx_busy <= 0;
            tx <= 1;  // Default idle state
        end else begin
            if (tx_start && !tx_active) begin
                tx_active <= 1;
                tx_shift <= {1'b1, data_in, 1'b0};  // Correct 10-bit frame
                baud_counter <= BAUD_DIV;
                bit_count <= 0;
                tx_busy <= 1;
            end else if (tx_active) begin
                if (baud_counter == 0) begin
                    baud_counter <= BAUD_DIV;
                    tx <= tx_shift[0];  // Send LSB first
                    tx_shift <= {1'b1, tx_shift[9:1]};  // Shift in correct order
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin  // Stop after 10 bits
                        tx_active <= 0;
                        tx_busy <= 0;
                    end
                end else begin
                    baud_counter <= baud_counter - 1;
                end
            end
        end
    end
endmodule
