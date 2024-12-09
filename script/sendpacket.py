#!/usr/bin/python3

import serial
import time
import sys

ser = serial.Serial('/dev/ttyUSB0', 9600)

while True:
    c = sys.stdin.buffer.read(1)
    if len(c) == 0:
        break
    ser.write(c)
    # sys.stdout.buffer.write(c)
    time.sleep(0.001)

