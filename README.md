# CEDA Utils

You've your Sanco retrocomputer, but you have no peripherals and no disks, so you have no idea how to interact with it.
Here you can find some utilities to jump start your computer from scratch!

## Bill of materials

- RS232 DB-25 cable
  - depending on your supplies, if you are working in the 3rd millenium, maybe you also need some adapters (eg. USB/RS-232), "ancient" cables (eg. old fashioned DB-9/DB-25 serial cable), and maybe a DB gender changer (no pun intended)
- EEPROM programmer for 28C32 (or larger)
  - you can even build one with an Arduino
- 28C32 blank EEPROM
- common hardware tools (eg. screwdrivers)

:warning: Mess with electronics only if you know what you are doing. Beware: you may harm your computer, or even yourself! Everything you do is at your own risk.

## Utilities

### Floppy
[floppy](floppy-utils/)
: Format, read and write floppy disks using your PC as data source (or sink).

### Compile a C program:
```sh
zcc +z80 -create-app --no-crt -pragma-define:REGISTER_SP=0xC000 -m -o build/main main.c
```
Important: this is a linker-less and C-runtime-less compilation, so be very very careful what you do.
Example minimal starter:
```c
int entrypoint(void) {
    __asm
    ld sp,0xc000
    __endasm;

    main();
    for (;;)
      ;
}
```

