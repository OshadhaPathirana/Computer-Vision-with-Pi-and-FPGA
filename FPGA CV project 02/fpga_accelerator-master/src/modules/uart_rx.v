module uart_rx
  (
   input        i_Clock,
   input        reset,
   input        receive,       // Can we receive?
   input        i_Rx_Serial,   // Input serial data
   output       o_Rx_DV,       // Done reading byte (1-cycle pulse)
   output [7:0] o_Rx_Byte      // Buffered received byte
   );

  parameter CLKS_PER_BIT  = 434; // //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Baud Rate
  parameter s_IDLE        = 3'b000;
  parameter s_CAN_RECV    = 3'b001;
  parameter s_RX_START_BIT= 3'b010;
  parameter s_RX_DATA_BITS= 3'b011;
  parameter s_RX_STOP_BIT = 3'b100;
  parameter s_CLEANUP     = 3'b101;

  reg [2:0]   r_SM_Main     = s_IDLE; // State machine register
  reg         r_Rx_Data_R   = 1'b1;
  reg         r_Rx_Data     = 1'b1;
  reg [17:0]  r_Clock_Count = 0;
  reg [2:0]   r_Bit_Index   = 0; // 8-bit counter
  reg [7:0]   r_Rx_Byte     = 0;
  reg         r_Rx_DV       = 0;

  // Double-register input data to prevent metastability
  always @(posedge i_Clock) begin
    r_Rx_Data_R <= i_Rx_Serial;
    r_Rx_Data   <= r_Rx_Data_R;
  end

  // UART RX State Machine
  always @(posedge i_Clock) begin
    if (reset) begin
      r_SM_Main     <= s_IDLE;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
      r_Rx_Byte     <= 0;
      r_Rx_DV       <= 0;
    end else begin
      case (r_SM_Main)
        s_IDLE: begin
          r_Rx_DV <= 1'b0;
          if (receive) begin
            r_SM_Main <= s_CAN_RECV;
          end
        end

        s_CAN_RECV: begin
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          if (r_Rx_Data == 1'b0) begin // Start bit detected
            r_SM_Main <= s_RX_START_BIT;
          end
        end

        s_RX_START_BIT: begin
          if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
            if (r_Rx_Data == 1'b0) begin
              r_Clock_Count <= 0;
              r_SM_Main     <= s_RX_DATA_BITS;
            end else begin
              r_SM_Main <= s_CAN_RECV; // False start bit, go back
            end
          end else begin
            r_Clock_Count <= r_Clock_Count + 1;
          end
        end

        s_RX_DATA_BITS: begin
          if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
          end else begin
            r_Clock_Count <= 0;
            r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
            if (r_Bit_Index < 7) begin
              r_Bit_Index <= r_Bit_Index + 1;
            end else begin
              r_Bit_Index <= 0;
              r_SM_Main   <= s_RX_STOP_BIT;
            end
          end
        end

        s_RX_STOP_BIT: begin
          if (r_Clock_Count < CLKS_PER_BIT-1) begin
            r_Clock_Count <= r_Clock_Count + 1;
          end else begin
            r_Rx_DV       <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= s_CLEANUP;
          end
        end

        s_CLEANUP: begin
          r_SM_Main <= s_IDLE;
          r_Rx_DV   <= 1'b0;
        end

        default: begin
          r_SM_Main <= s_IDLE;
        end
      endcase
    end
  end

  assign o_Rx_DV   = r_Rx_DV;
  assign o_Rx_Byte = r_Rx_Byte;

endmodule
