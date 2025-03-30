import serial
import time

# UART configuration
uart_port = "/dev/ttyS0"  # UART port on Raspberry Pi
baud_rate = 115200 #115200

# Open UART connection
uart = serial.Serial(uart_port, baud_rate, timeout=10)

def send_pixel_data(pixel_data):
    """Send pixel data to the FPGA."""
    if 0 <= pixel_data <= 255:  # Ensure it's a single byte
        uart.write(bytes([pixel_data]))
    else:
        print("Error: Pixel data out of range (0-255)")

def receive_processed_data():
    """Receive processed pixel data from the FPGA."""
    if uart.in_waiting > 0:
        data = uart.read(1)  # Read one byte
        print(f"Received byte: {data}")
        print(f"Binary: {bin(int.from_bytes(data, 'big'))[2:].zfill(8)}")
        return data[0] if data else None
    return None

# Example usage
if __name__ == "__main__":
    try:
        # Send pixel data to FPGA
        pixel_data = 0b11010011  # Example pixel value
        send_pixel_data(pixel_data)
        print("Data sent:", pixel_data)

        # Wait for FPGA to process the data
        time.sleep(0.01)

        # Receive processed pixel data
        processed_data = receive_processed_data()
        if processed_data is not None:
            print(f"Processed pixel data: {processed_data}")
        else:
            print("No data received from FPGA.")
    except serial.SerialException as e:
        print(f"Serial error: {e}")
    finally:
        uart.close()