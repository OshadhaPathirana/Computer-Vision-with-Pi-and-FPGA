module uart_echo_continuos #(
    parameter BUFFER_SIZE = 1024,  // Maximum number of bytes to store
    parameter TIMEOUT_CYCLES = 100000  // 2ms timeout at 50MHz
)(
    input logic clk,
    input logic rst_n,
    input logic uart_rx,
    output logic uart_tx,
    output logic led_rx,
    output logic led_tx,
    output logic [7:0] leds
);

    // UART Parameters
    parameter CLOCK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter BAUD_DIV = CLOCK_FREQ / BAUD_RATE;

    // UART Components
    logic [7:0] rx_data;
    logic rx_done;
    logic tx_start;
    logic tx_busy;
 

    // Buffer and control logic
    logic [7:0] buffer [BUFFER_SIZE-1:0];
    logic [$clog2(BUFFER_SIZE)-1:0] wr_ptr;
    logic [$clog2(BUFFER_SIZE)-1:0] rd_ptr;
    logic [31:0] timeout_counter;
    logic [7:0] tx_data;

    typedef enum {
        IDLE,
        RECEIVING,
        TRANSMITTING
    } state_t;

    state_t state;

   
    uart_rx #(.BAUD_DIV(BAUD_DIV)) rx_inst (
        .clk, .rst_n, .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_done),
        .leds()
    );

    uart_tx #(.BAUD_DIV(BAUD_DIV)) tx_inst (
        .clk, .rst_n,
        .tx_start,
        .data_in(tx_data),
        .tx_busy,
        .tx(uart_tx)
    );



    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            wr_ptr <= 0;
            rd_ptr <= 0;
            timeout_counter <= 0;
            tx_start <= 0;
            led_rx <= 0;
            led_tx <= 0;
            for (int i = 0; i < BUFFER_SIZE; i++) buffer[i] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (rx_done) begin
                        buffer[wr_ptr] <= rx_data;
                        wr_ptr <= wr_ptr + 1;
                        state <= RECEIVING;
                        timeout_counter <= 0;
                        led_rx <= 1;
                    end
                end

                RECEIVING: begin
                    if (rx_done) begin
                        if (wr_ptr < BUFFER_SIZE-1) begin
                            buffer[wr_ptr] <= rx_data;
                            wr_ptr <= wr_ptr + 1;
                        end
                        timeout_counter <= 0;
                        led_rx <= 1;
                    end else begin
                        led_rx <= 0;
                        if (timeout_counter < TIMEOUT_CYCLES) begin
                            timeout_counter <= timeout_counter + 1;
                        end else begin
                            state <= TRANSMITTING;
                            rd_ptr <= 0;
                        end
                    end
                end

                TRANSMITTING: begin
                    if (!tx_busy && rd_ptr < wr_ptr) begin
                        tx_data <= buffer[rd_ptr];
                        tx_start <= 1;
                        rd_ptr <= rd_ptr + 1;
                        led_tx <= 1;
                    end else begin
                        tx_start <= 0;
                        led_tx <= 0;
                    end

                    if (rd_ptr == wr_ptr) begin
                        state <= IDLE;
                        wr_ptr <= 0;
                        rd_ptr <= 0;
                    end
                end
            endcase
        end
    end
endmodule