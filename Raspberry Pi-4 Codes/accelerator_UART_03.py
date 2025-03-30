import serial
import time
import numpy as np
import RPi.GPIO as GPIO

# Configure serial communication
SERIAL_PORT = "/dev/serial0"  # UART on Raspberry Pi
BAUD_RATE = 115200

# GPIO configuration
data_ready_pin = 17  # GPIO pin number connected to FPGA's 'data_ready'
FPGA_reset_pin = 27

GPIO.setmode(GPIO.BCM)
GPIO.setup(data_ready_pin, GPIO.IN)
GPIO.setup(FPGA_reset_pin, GPIO.OUT)

# Initialize serial connection
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

def reset_fpga():
    """Reset the FPGA before sending new data."""
    GPIO.output(FPGA_reset_pin, GPIO.HIGH)
    time.sleep(0.001)
    GPIO.output(FPGA_reset_pin, GPIO.LOW)
    time.sleep(0.01)  # Keep it OFF for 1 millisecond
    GPIO.output(FPGA_reset_pin, GPIO.HIGH)
    time.sleep(0.1)  # Allow FPGA to stabilize
    print("FPGA reset complete.")

def send_image(image):
    """Send an 8x8 binary image to the FPGA via UART."""
    reset_fpga()  # Reset FPGA before sending data
    
    for row in image:
        for pixel in row:
            ser.write(bytes([pixel]))  # Send each pixel as a byte
            time.sleep(0.001)  # Small delay to ensure proper transmission
    print("Image sent.")

def wait_for_data_ready():
    print("Waiting for FPGA to be ready to send data...")
    while GPIO.input(data_ready_pin) == GPIO.LOW:
        time.sleep(0.0001)  # Short sleep to avoid high CPU usage
    print("FPGA is ready, receiving data...")

def receive_feature_map():
    """Receive the 6x6 feature map from the FPGA."""
    wait_for_data_ready()  # Ensure FPGA is ready before reading
    
    feature_map = np.ones((6, 6), dtype=np.uint8)
    for i in range(6):
        for j in range(6):
            data = ser.read(1)  # Read one byte
            if data:
                feature_map[i][j] = ord(data)
    print("Feature map received.")
    return feature_map

if __name__ == "__main__":
    try:
        # Example 8x8 binary image (random values)
        image = np.random.randint(0, 2, (8, 8), dtype=np.uint8)
        print("Sending Image:\n", image)
        
        send_image(image)
        
        feature_map = receive_feature_map()
        print("Received Feature Map:\n", feature_map)
    
    except serial.SerialException as e:
        print(f"Serial error: {e}")
    
    finally:
        ser.close()
        GPIO.cleanup()
