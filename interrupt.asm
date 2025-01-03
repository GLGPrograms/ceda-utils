    org 0x1000

prhex = $c174
putchar = $c45e

fdc_rwfs_c19d = $c19d

PUBLIC _main
_main:
    ; hello
    nop
    nop
    nop
    ld      a,$41
    ld      ($d050),a

    ; disable interrupts (just in case)
    di

    ; set $11 as the MSB of the interrupt vector table base address
    ld      a,$11
    ld      i,a

    ; timer control word
    ld      l,$b7
    ld      c,$e3
    out     (c),l

    ; timer costant
    ld      l,$40
    ld      c,$e3
    out     (c),l

    ; set $00 as the LSB of the interrupt vector table base address
    ; (tells CTC to generate vectors at $1100)
    ld      l,$00
    ld      c,$e3
    out     (c),l

    im      2       ; set interrupt mode 2
    ei              ; enable interrupts

halt:
    nop
    nop
    jr      halt

    ; interrupt vector for CTC timer 3 must be located at 1106
    REPT $1106 - ASMPC - $1000
    nop
    ENDR
    BYTE (timer_isr & $FF)
    BYTE (timer_isr >> 8)

    ; ISR routine
timer_isr:
    ld      a,($d000)
    inc     a
    ld      ($d000),a
    ei
    reti


