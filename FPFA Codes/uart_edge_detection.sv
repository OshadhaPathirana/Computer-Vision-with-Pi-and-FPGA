module uart_edge_detection (
    input logic clk,          // 50MHz system clock
    input logic rst_n,        // Active-low reset
    input logic uart_rx,      // UART RX input
    output logic uart_tx,     // UART TX output
    output logic led_rx,      // RX indicator LED
    output logic led_tx,      // TX indicator LED
    output logic data_ready   // GPIO to indicate data ready to Pi
);

    parameter CLOCK_FREQ = 50000000;   // FPGA clock (50MHz)
    parameter BAUD_RATE  = 115200;
    parameter BAUD_DIV   = CLOCK_FREQ / BAUD_RATE;
    parameter THRESHOLD  = 4;          // Threshold for binary convolution sum

    // UART internal signals
    logic [7:0] rx_data;
    logic rx_done;
    logic [7:0] processed_data;
    logic tx_start;
    logic tx_busy;

    // Buffers and counters
    logic [7:0] image_data [0:63];    // 8x8 image buffer
    logic [7:0] conv_result [0:35];   // 6x6 convolution result buffer
    logic [5:0] rx_counter;           // Counter for receiving data (0-63)
    logic [5:0] tx_counter;           // Counter for sending data (0-35)

    // FSM state declaration
    typedef enum logic [1:0] {IDLE, RECEIVE, PROCESS, SEND} state_t;
    state_t state, next_state;

    // UART Receiver instance
    uart_rx #(
        .BAUD_DIV(BAUD_DIV)
    ) uart_receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_done)
    );

    // UART Transmitter instance
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

    // FSM State Transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM Next State Logic
    always_comb begin
        case (state)
            IDLE:      next_state = (rx_done) ? RECEIVE : IDLE;
            RECEIVE:   next_state = (rx_counter == 6'd63) ? PROCESS : RECEIVE;
            PROCESS:   next_state = SEND;
            SEND:      next_state = (tx_counter == 6'd36 && !tx_busy) ? IDLE : SEND;
            default:   next_state = IDLE;
        endcase
    end

    // RX Counter and Data Storing Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_counter <= 6'd0;
        end else if (state == RECEIVE && rx_done) begin
            image_data[rx_counter] <= rx_data;
            rx_counter <= rx_counter + 1;
        end else if (state == IDLE) begin
            rx_counter <= 6'd0;
        end
    end

    // Convolution Logic
    integer i, j, k, l;
    reg [3:0] sum;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 36; i = i + 1)
                conv_result[i] <= 8'd0;
        end else if (state == PROCESS) begin
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    sum = 0;
                    for (k = 0; k < 3; k = k + 1) begin
                        for (l = 0; l < 3; l = l + 1) begin
                            sum = sum + image_data[(i + k) * 8 + (j + l)][0];
                        end
                    end
                    conv_result[i * 6 + j] <= (sum >= THRESHOLD) ? 8'b1 : 8'b0;
                end
            end
        end
    end

    // TX Counter and Data Sending Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_counter <= 6'd0;
            tx_start <= 1'b0;
            processed_data <= 8'd0;
        end else if (state == SEND) begin
            if (!tx_busy && !tx_start) begin
                tx_start <= 1'b1;
                processed_data <= conv_result[tx_counter];
                tx_counter <= tx_counter + 1;
            end else if (tx_start && tx_busy) begin
                tx_start <= 1'b0;
            end
        end else begin
            tx_counter <= 6'd0;
            tx_start <= 1'b0;
        end
    end

    // LED and Data Ready Indicators
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_rx <= 1'b0;
            led_tx <= 1'b0;
            data_ready <= 1'b0;
        end else begin
            led_rx <= (state == RECEIVE) ? rx_done : 1'b0;
            led_tx <= (state == SEND) ? ~tx_busy : 1'b0;
            data_ready <= (state == SEND); // High when ready to send
        end
    end

endmodule
