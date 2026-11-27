import serial
ser = serial.Serial("COM13", 115200, timeout=1)
names = ["Z", "C", "B", "N", "V", "EQ", "GT", "LT"]
while True:
    op, a, b = int(input("op (hex): "), 16), int(input("A: ")), int(input("B: "))
    ser.write(bytes([0xA5, op, a, b, op ^ a ^ b]))
    r = ser.read(6); x = (r[2] << 8) | r[3]
    print(x, hex(r[2] << 8 | r[3]), "| status:", {0: "OK", 1: "invalid opcode", 2: "bad checksum", 3: "incomplete"}[r[1]], "| flags 0x%02X:" % r[4], [n for i, n in enumerate(names) if r[4] >> i & 1] or "none")