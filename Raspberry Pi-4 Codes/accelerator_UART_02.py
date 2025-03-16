import serial
import time
import numpy as np

# Configure serial communication
SERIAL_PORT = "/dev/serial0"  # UART on Raspberry Pi
BAUD_RATE = 115200

# Initialize serial connection
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

def send_image(image):
    """Send an 8x8 binary image to the FPGA via UART."""
    for row in image:
        for pixel in row:
            ser.write(bytes([pixel]))  # Send each pixel as a byte
            time.sleep(0.001)  # Small delay to ensure proper transmission
    print("Image sent.")

def receive_feature_map():
    """Receive the 6x6 feature map from the FPGA."""
    feature_map = np.ones((6, 6), dtype=np.uint8)
    for i in range(6):
        for j in range(6):
            data = ser.read(1)  # Read one byte
            print("data= ",data)
            if data:
                feature_map[i][j] = ord(data)
    print("Feature map received.")
    return feature_map

if __name__ == "__main__":
    # Example 8x8 binary image (random values)
    image = np.random.randint(0, 2, (8, 8), dtype=np.uint8)
    print("Sending Image:\n", image)
    
    send_image(image)
    time.sleep(1)  # Wait for FPGA processing
    
    feature_map = receive_feature_map()
    print("Received Feature Map:\n", feature_map)
