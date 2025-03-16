import cv2
import numpy as np
import serial
import struct

# Setup UART connection to FPGA
ser = serial.Serial('/dev/ttyS0', 115200, timeout=10)

def preprocess_image(image_path):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)  # Load grayscale
    img = cv2.resize(img, (28, 28))  # Resize to 28x28 (like MNIST)
    _, binarized = cv2.threshold(img, 127, 1, cv2.THRESH_BINARY)  # Convert to binary (0/1)
    return binarized.flatten()  # Flatten to 1D for transmission

def send_to_fpga(data):
    packed_data = struct.pack(f'{len(data)}B', *data)  # Pack into bytes
    ser.write(packed_data)  # Send to FPGA

def receive_from_fpga():
    response = ser.read(10)  # Read 10 bytes (assumed feature map size)
    return struct.unpack(f'{len(response)}B', response)  # Unpack bytes

# Load and process an image
image_data = preprocess_image("test_img.png")
send_to_fpga(image_data)

# Get feature map from FPGA
feature_map = receive_from_fpga()
print("Feature Map from FPGA:", feature_map)

