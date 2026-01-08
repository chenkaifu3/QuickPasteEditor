#!/usr/bin/env python3
from PIL import Image
import numpy as np

# Load the original icon
img = Image.open('Sources/Resources/AppIcon.png').convert('RGBA')
data = np.array(img)

# Get color channels
red, green, blue, alpha = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

# Define the background color characteristics:
# - Low red values (< 45)
# - Medium-high green values (70-150)
# - Medium-high blue values (100-140)
# This captures the blue-cyan gradient background while preserving the icon colors

background_mask = (
    (red < 45) &           # Low red component
    (green > 70) & (green < 150) &  # Medium green
    (blue > 100) & (blue < 140)     # Medium-high blue
)

# Set alpha to 0 for background pixels only
data[:,:,3] = np.where(background_mask, 0, alpha)

# Create new image with transparent background
result = Image.fromarray(data, 'RGBA')

# Save the result
result.save('Sources/Resources/AppIcon.png')
print("Icon background made transparent successfully!")
print("Preserved colors: white, gray, green, and other icon elements")

# Generate iconset with multiple sizes
import os
import subprocess

iconset_path = 'Sources/Resources/AppIcon.iconset'
os.makedirs(iconset_path, exist_ok=True)

# Generate different sizes for the iconset
sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes:
    # Regular size
    subprocess.run(['sips', '-z', str(size), str(size),
                   'Sources/Resources/AppIcon.png',
                   '--out', f'{iconset_path}/icon_{size}x{size}.png'],
                   capture_output=True)
    # @2x size (except for 1024)
    if size != 1024:
        size_2x = size * 2
        subprocess.run(['sips', '-z', str(size_2x), str(size_2x),
                       'Sources/Resources/AppIcon.png',
                       '--out', f'{iconset_path}/icon_{size}x{size}@2x.png'],
                       capture_output=True)

# Convert iconset to icns
subprocess.run(['iconutil', '-c', 'icns', iconset_path,
               '-o', 'Sources/Resources/AppIcon.icns'])
print("ICNS file regenerated!")
