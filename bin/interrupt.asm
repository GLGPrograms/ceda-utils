    org 0x0100

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

    ; set $02 as the MSB of the interrupt vector table base address
    ld      a,$02
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
    ; (tells CTC to generate vectors at $0200)
    ; Note: interrupt vector is always programmed to Timer Channel 0
    ld      l,$00
    ld      c,$e0
    out     (c),l

    im      2       ; set interrupt mode 2
    ei              ; enable interrupts

halt:
    nop
    nop
    jr      halt

    ; interrupt vector for CTC timer 3 must be located at 1106
    REPT $206 - ASMPC - $100
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


