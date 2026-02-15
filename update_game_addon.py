import shutil
import os

source = r"addons/tCrossBar"
destination = r"C:\catseyexi\catseyexi-client\Ashita\addons\tCrossBar"

try:
    # Remove destination if it exists
    if os.path.exists(destination):
        shutil.rmtree(destination)
    
    # Copy the directory
    shutil.copytree(source, destination)
    print(f"Successfully copied {source} to {destination}")
except Exception as e:
    print(f"Error: {e}")