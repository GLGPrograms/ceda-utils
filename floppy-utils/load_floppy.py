#!/bin/python3

import serial
import time
import sys

class FdcFormatType:
    BPS128 = 0
    BPS256 = 1
    BPS512 = 2
    BPS1024 = 3

    @staticmethod
    def compute_bps(format_type):
        if format_type == FdcFormatType.BPS128:
            return 128
        elif format_type == FdcFormatType.BPS256:
            return 256
        elif format_type == FdcFormatType.BPS512:
            return 512
        elif format_type == FdcFormatType.BPS1024:
            return 1024
        raise Exception(f"Unsupported format type {format_type}")

    @staticmethod
    def compute_spt(format_type):
        if format_type == FdcFormatType.BPS1024:
            return 5
        elif format_type in [FdcFormatType.BPS512,
                             FdcFormatType.BPS256,
                             FdcFormatType.BPS128]:
            return 16
        raise Exception(f"Unsupported format type {format_type}")


class FdcReturnBuffer:
    st0: int
    st1: int
    st2: int
    cylinder: int
    head: int
    record: int
    nbytes: int

    def __init__(self, buffer):
        if len(buffer) != 7:
            raise Exception("Invalid Return Buffer size")
        self.st0 = buffer[0]
        self.st1 = buffer[1]
        self.st2 = buffer[2]
        self.cylinder = buffer[3]
        self.head = buffer[4]
        self.record = buffer[5]
        self.nbytes = buffer[6]

    def success(self) -> bool:
        return (self.st0 & 0xC0) == 0x00

    def dump(self):
        print("======== ST0 ========")
        print(f"Unit select: {self.st0 & 0x03}")
        print(f"Head addr:   {1 if (self.st0 & 0x04) else 0}")
        print(f"Not ready:   {bool(self.st0 & 0x08)}")
        print(f"Equip check: {bool(self.st0 & 0x10)}")
        print(f"Seek end:    {bool(self.st0 & 0x20)}")
        print(f"Error code:  {self.st0 >> 6}")
        print("======== ST1 ========")
        print(f"Missing mark:{bool(self.st1 & 0x01)}")
        print(f"Not writ:    {bool(self.st1 & 0x02)}")
        print(f"No data:     {bool(self.st1 & 0x04)}")
        print(f"Overrun:     {bool(self.st1 & 0x10)}")
        print(f"CRC error:   {bool(self.st1 & 0x20)}")
        print(f"End of Cyl:  {bool(self.st1 & 0x80)}")
        print("======== ST2 ========")
        print(f"Missing addr:{bool(self.st1 & 0x01)}")
        print(f"Bad cyl:     {bool(self.st1 & 0x02)}")
        print(f"Scan fail:   {bool(self.st1 & 0x04)}")
        print(f"Scan equal:  {bool(self.st1 & 0x08)}")
        print(f"Wrong cyl:   {bool(self.st1 & 0x10)}")
        print(f"Data error:  {bool(self.st1 & 0x20)}")
        print(f"Control mark:{bool(self.st1 & 0x40)}")
        print("====== Others =======")
        print(f"cylinder:    {self.cylinder}")
        print(f"head:        {self.head}")
        print(f"record:      {self.record}")
        print(f"nbytes:      {self.nbytes}")


class CedaSerialFdcInterface:
    # Commands
    CMD_READ = 0
    CMD_WRITE = 1
    CMD_FORMAT = 2
    CMD_DUMMY = 3

    def __init__(self, port_name):
        self.ser = serial.Serial(port_name, 9600,
                                 rtscts=False, xonxoff=False,
                                 inter_byte_timeout=10)


    @staticmethod
    def _create_command(command, track, side, sector, format_type) -> bytearray:
        data = bytearray()
        data += b'\xff'
        data += command.to_bytes()
        data += track.to_bytes()
        data += sector.to_bytes()
        data += side.to_bytes()
        data += format_type.to_bytes()
        return data


    def _send_command(self, command, track, side, sector, format_type):
        command = self._create_command(command, track, side, sector, format_type)

        # Send the command
        self.ser.write(command)

        # Wait the ack
        ack = self.ser.read(1)


    def _sector_read(self, track, side, sector, format_type) -> bytearray:
        bps = FdcFormatType.compute_bps(format_type)

        self._send_command(CedaSerialFdcInterface.CMD_READ, track, side, sector, format_type)

        # Read the status register
        sr = FdcReturnBuffer(self.ser.read(7))

        # Read the data buffer
        data = self.ser.read(bps)

        if not sr.success():
            sr.dump()
            raise Exception(f"Error completing operation")

        # Get only the populated part
        bps = FdcFormatType.compute_bps(format_type)
        return data[0:bps]


    def _sector_write(self, track, side, sector, format_type, data):
        bps = FdcFormatType.compute_bps(format_type)

        sector_size = len(data)
        if sector_size > bps:
            raise Exception(f"Unexpected buffer size {sector_size} > {bps}")

        self._send_command(CedaSerialFdcInterface.CMD_WRITE, track, side, sector, format_type)

        # Write data to the buffer and complete with padded bytes where needed
        self.ser.write(data)
        self.ser.write(b"\x00" * (bps - sector_size))

        # Read the status register
        sr = FdcReturnBuffer(self.ser.read(7))
        if not sr.success():
            sr.dump()
            raise Exception(f"Error completing operation")


    def track_format(self, track : int, side : int, format_type):
        self._send_command(CedaSerialFdcInterface.CMD_FORMAT, track, side, 0, format_type)

        # Read the status register
        sr = FdcReturnBuffer(self.ser.read(7))
        if not sr.success():
            sr.dump()
            raise Exception(f"Error completing operation")


    def track_read(self, track : int, side : int, format_type) -> bytearray:
        # Compute buffer size
        bps = FdcFormatType.compute_bps(format_type)
        spt = FdcFormatType.compute_spt(format_type)

        self._send_command(CedaSerialFdcInterface.CMD_READ, track, side, 0, format_type)

        # Read the status register
        sr = FdcReturnBuffer(self.ser.read(7))

        # Read the data buffer
        data = self.ser.read(bps * spt)

        if not sr.success():
            sr.dump()
            raise Exception(f"Error completing operation")

        return data


    def track_write(self, track : int, side : int, format_type, data):
        # Compute buffer size
        bps = FdcFormatType.compute_bps(format_type)
        spt = FdcFormatType.compute_spt(format_type)

        data_size = len(data)
        if data_size > bps*spt:
            raise Exception(f"Unexpected buffer size {sector_size} > {bps*spt}")

        self._send_command(CedaSerialFdcInterface.CMD_WRITE, track, side, 0, format_type)

        # Write data to the buffer and complete with padded bytes where needed
        self.ser.write(data)
        self.ser.write(b"\x00" * ((bps*spt) - data_size))

        # Read the status register
        sr = FdcReturnBuffer(self.ser.read(7))
        if not sr.success():
            sr.dump()
            raise Exception(f"Error completing operation")

# # # # # # # # # # # # # # # # # Some examples # # # # # # # # # # # # # # # #

# this should not work!
"""
def format_in_128b_mode():
    fdc_interface = CedaSerialFdcInterface("/dev/ttyUSB0")
    fdc_interface.track_format(0, 0, FdcFormatType.BPS128)
    fdc_interface._sector_read(0, 0, 0, FdcFormatType.BPS128)
"""

# This does not work!
"""
def format_in_512b_mode():
    fdc_interface = CedaSerialFdcInterface("/dev/ttyUSB0")
    fdc_interface._sector_read(0, 0, 0, FdcFormatType.BPS512)
"""

# Write CP/M floppy disk from binary image to physical disk.
# Binary image must contain sequential data ordered by increasing tracks,
# then by head (head 0, head 1), then by sectors.
# Please note that head 0, track 0 has different format type than the rest of
# the disk.
def load_cpm(filename):
    fdc_interface = CedaSerialFdcInterface("/dev/ttyUSB0")

    # Format the floppy, 1024 bytes per sector, except for head 0, track 0,
    # which is 256 bytes per sector
    for t in range(80):
        for h in range(0,2):
            print(f"Formatting {t=}, {h=}")
            if t == 0 and h == 0:
                fdc_interface.track_format(track=t, head=h,
                                           format_type=FdcFormatType.BPS256)
            else:
                fdc_interface.track_format(track=t, head=h,
                                           format_type=FdcFormatType.BPS1024)

    with open(filename, "rb") as f:
        for t in range(80):
            for h in range(0,2):
                print(f"Writing and comparing {t=}, {h=}")
                # Read whole sector from binary file
                if t == 0 and h == 0:
                    data = f.read(256*16)
                    format_type = FdcFormatType.BPS256
                else:
                    data = f.read(1024*5)
                    format_type = FdcFormatType.BPS1024

                # Write and compare
                fdc_interface.track_write(track=t, head=h,
                                          format_type=format_type,
                                          data=data)
                if (data != fdc_interface.track_read(track=t, head=h,
                                                     format_type=format_type)):
                    raise Exception("Sector mismatch")

# Read a pair of tracks and write them to file
def dump_track_0():
    fdc_interface = CedaSerialFdcInterface("/dev/ttyUSB0")

    with open("t0h0.bin", "wb") as f:
        f.write(fdc_interface.track_read(0, 0, FdcFormatType.BPS256))

    with open("t0h1.bin", "wb") as f:
        f.write(fdc_interface.track_read(0, 1, FdcFormatType.BPS1024))
