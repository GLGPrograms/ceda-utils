#!/usr/bin/python3

import sys
import struct

filename = sys.argv[1]

ofile = open(filename + ".pkt", 'wb')

ifile = open(filename, 'rb')
content = ifile.read()

ofile.write(struct.pack("<HH", 0x1000, len(content)))
ofile.write(content)
