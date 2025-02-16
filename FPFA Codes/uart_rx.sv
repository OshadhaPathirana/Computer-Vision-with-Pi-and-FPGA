module uart_rx #(
    parameter BAUD_DIV = 434  // Adjusted for 115200 baud with 50MHz clock
) (
    input logic clk,
    input logic rst_n,
    input logic rx,
    output logic [7:0] data_out,
    output logic data_valid,
	 	output logic [7:0] leds
);
    logic [11:0] baud_counter;
    logic [3:0] bit_count;
    logic [7:0] rx_shift;
    logic rx_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 0;
            bit_count <= 0;
            rx_active <= 0;
            data_valid <= 0;
            rx_shift <= 8'b0;  // <--- Ensure shift register starts from zero
        end else begin
            if (!rx_active && !rx) begin
                rx_active = 1;
                baud_counter = BAUD_DIV / 2;
                bit_count = 0;
                rx_shift = 8'b0;  // <--- Reset shift register before receiving
            end else if (rx_active) begin
                if (baud_counter == 0) begin
                    baud_counter <= BAUD_DIV;
                    if (bit_count < 9) begin
                        rx_shift = {rx, rx_shift[7:1]};  // Shift in new bit
                        bit_count = bit_count + 1;
                    end else begin
                        rx_active <= 0;
                        data_out = rx_shift; // Correctly store received byte
								leds = rx_shift;
                        data_valid = 1;
                    end
                end else begin
                    baud_counter <= baud_counter - 1;
                end
            end else begin
                data_valid <= 0;
            end
        end
    end
endmodule
