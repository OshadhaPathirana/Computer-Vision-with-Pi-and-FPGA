import serial
import time

# Configure the serial port
ser = serial.Serial('/dev/serial0', baudrate=115200, timeout=1)  # Check your port if different

def send_and_receive():
    try:
        print("Resetting FPGA...")
        time.sleep(2)  # Simulating initial reset delay
        
        bytes_sent = 0
        uart_rx_data = None

        while True:
            if bytes_sent == 0:
                uart_tx_data = '00100110'  # Binary string '00000101' for byte 5
                ser.write(bytes([int(uart_tx_data, 2)]))  # Convert binary string to byte and send
                print(f"Sent: {uart_tx_data}")
                bytes_sent += 1
                time.sleep(0.1)  # Wait for FPGA to process
            
            elif bytes_sent == 1:
                uart_tx_data = '00000111'  # Binary string '00000111' for byte 7
                ser.write(bytes([int(uart_tx_data, 2)]))  # Convert binary string to byte and send
                print(f"Sent: {uart_tx_data}")
                bytes_sent += 1
                time.sleep(0.1)
            
            elif bytes_sent == 2:
                uart_rx_data = ser.read(1)  # Read 1 byte from FPGA
                if uart_rx_data:
                    print(f"Received: {bin(uart_rx_data[0])[2:].zfill(8)}")
                    break
        
        print("Communication complete.")

    except Exception as e:
        print(f"Error: {e}")

    finally:
        ser.close()  # Always close the serial connection

if __name__ == "__main__":
    send_and_receive()
