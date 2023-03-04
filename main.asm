    org 0x1000

prhex = $c174
putchar = $c45e

PUBLIC _main
_main:
    ld      hl,$0000

main_loop:
    ld      a,$0e
    out     ($a0),a
    ld      a,h
    out     ($a1),a

    ld      a,$0f
    out     ($a0),a
    ld      a,l
    out     ($a1),a

    call    delay
    inc     hl
    jp      main_loop

    jp      ASMPC


delay:
    push    de
    ld      de,$0000
delay_loop:
    dec     de
    ld      a,d
    or      e
    jr      nz,delay_loop

    pop     de
    ret