    org 0x100

    ; Print the alphabet under CP/M
PUBLIC _main
_main:
    ; increment letter
    ld      hl,letter
    ld      e,(hl)
    inc     e
    ld      (hl),e

    ; system call "2" - print char
    ld      c,$2
    call    $5

    ; if letter is 'Z', then end
    ld      a,$5a
    cp      e
    jr      z,end

    jp      _main

end:
    ; Return to CP/M
    ret

letter:
    BYTE    '@'

