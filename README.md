# CEDA Utils

You've your Sanco retrocomputer, but you have no peripherals and no disks, so you have no idea how to interact with it.
Or, you have them, but something is not quite working right? Or, you need to transfer data from/to your computer?
Here you can find some utilities to jump start your computer from scratch!

You may also be interested in the [ceda-demo](https://github.com/GLGPrograms/ceda-demo) repository, which shows how to link C and assembly programs for the Sanco, how to interact with its peripherals, exploit some custom hardware features, and, of course, test custom mods 😎

# Bill of materials
If your computer does not come with a CP/M disk, you need to jumpstart it using a custom bootloader in the BIOS ROM, and a serial cable.

- RS232 DB-25 cable
  - depending on your supplies, if you are working in the 3rd millenium, maybe you also need some adapters (eg. USB/RS-232), "ancient" cables (eg. old fashioned DB-9/DB-25 serial cable), and maybe a DB gender changer (no pun intended)
- EEPROM programmer for 28C32 (or larger)
  - you can even build one with an Arduino
- 28C32/28C64 blank EEPROM
- common hardware tools (eg. screwdrivers)

⚠ Mess with electronics only if you know what you are doing. Beware: you may harm your computer, or even yourself! Everything you do is at your own risk.

# Build
Install the [z88dk](https://z88dk.org/site/) suite in your path, and then just:

```
make
```

Output binaries are in the `build` directory, including the patched ROM with the serial bootloader.

## BIOS Utils
These utils can be run even if you only have a BIOS, and can be used to jumpstart your computer from scratch (eg. if you don't have a CP/M disk).
But, you need a custom bootloader in the BIOS ROM (see above).

Once compiled, each specific raw output binary is embedded in a `.pkt` (packet) file.
To send it to the patched bootloader, connect your serial cable, then just:

```
python3 script/sendpacket.py < build/<util.pkt>
```

- [interrupt.asm](bin/interrupt.asm)
Configure the CTC (timer counter) peripheral in order to send interrupts periodically to the Z80, and install an interrupt vector to handle them.

- [loadfloppy.asm](bin/loadfloppy.asm)
This small program add the capability to format, read, write data to physical disk at low level.
The program supports only one floppy drive, and is used in tandem with the corresponding [loadfloppy.py](bin/loadfloppy.py) Python script.
It was used just to create our first Sanco floppy disk using an image found on the internet.

## CPM Utils
These utils can be run under CP/M.
In order to use them, you need to boot from a CP/M disk.

- [grabkey.asm](cpm/grabkey.asm) Logs every keystroke on the screen.
- [hellocpm.asm](cpm/hellocpm.asm) Example CP/M program to print the alphabet.

# Contributing
This repository is part of the [ceda](https://github.com/GLGPrograms/ceda-home) documentation project by [Retrofficina GLG](https://retrofficina.glgprograms.it/).