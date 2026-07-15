import sys

def make_hex(bin_file, mem_file):
    try:
        with open(bin_file, 'rb') as f:
            data = f.read()
        
        # Pad to 4 bytes
        while len(data) % 4 != 0:
            data += b'\x00'
            
        with open(mem_file, 'w') as f:
            # Process 32-bit words
            for i in range(0, len(data), 4):
                word = data[i:i+4]
                # Little endian to integer
                val = int.from_bytes(word, byteorder='little')
                # Write as 8-digit hex
                f.write(f'{val:08x}\n')
                
        print(f"Successfully converted {bin_file} to {mem_file} ({len(data)} bytes)")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python make_hex.py <input.bin> <output.mem>")
        sys.exit(1)
    
    make_hex(sys.argv[1], sys.argv[2])
