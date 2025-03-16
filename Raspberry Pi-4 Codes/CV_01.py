import serial
import time
import RPi.GPIO as GPIO

# UART configuration
uart_port = "/dev/ttyS0"  # UART port on Raspberry Pi
baud_rate = 115200  # Baud rate

# GPIO configuration
data_ready_pin = 17  # GPIO pin number connected to FPGA's 'data_ready'
FPGA_reset_pin = 27
GPIO.setmode(GPIO.BCM)
GPIO.setup(data_ready_pin, GPIO.IN)
GPIO.setup(FPGA_reset_pin, GPIO.OUT)


# Open UART connection
uart = serial.Serial(uart_port, baud_rate, timeout=10)


def send_pixel_data(data_list):
    """
    Send 64 bytes of pixel data to the FPGA.
    :param data_list: List of integers (0-255), length must be 64.
    """
    if len(data_list) != 64:
        print("Error: Data list must contain exactly 64 bytes.")
        return
    
    GPIO.output(FPGA_reset_pin, GPIO.HIGH)
    time.sleep(0.001)
    GPIO.output(FPGA_reset_pin, GPIO.LOW)
    time.sleep(0.01)  # Keep it ON for 1 millisecond
    GPIO.output(FPGA_reset_pin, GPIO.HIGH)
    time.sleep(0.1)
    
    uart.write(bytes(data_list))  # Send all 64 bytes at once
    print("64 bytes of pixel data sent.")


def receive_processed_data():
    """
    Wait for data ready pin and receive 36 bytes of processed data from the FPGA.
    :return: List of received bytes.
    """
    print("Waiting for FPGA to be ready to send data...")
    while GPIO.input(data_ready_pin) == GPIO.LOW:
        time.sleep(0.001)  # Polling interval, adjust as necessary

    print("FPGA is ready, receiving data...")
    expected_bytes = 36
    received_data = uart.read(expected_bytes)

    if len(received_data) == expected_bytes:
        print(f"Received {expected_bytes} bytes: {received_data}")
        return list(received_data)
    else:
        print(f"Error: Expected {expected_bytes} bytes but received {len(received_data)} bytes.")
        return list(received_data)


# Example usage
if __name__ == "__main__":
    try:
        pixel_data_list = [0b11000001] * 64  # Example data

        send_pixel_data(pixel_data_list)
        processed_data_list = receive_processed_data()

        if processed_data_list:
            print("Processed data received:")
            for i, byte in enumerate(processed_data_list):
                print(f"Byte {i}: {byte} ({bin(byte)[2:].zfill(8)})")

    except serial.SerialException as e:
        print(f"Serial error: {e}")

    finally:
        uart.close()
        GPIO.cleanup()
