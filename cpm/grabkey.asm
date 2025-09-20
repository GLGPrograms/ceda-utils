    org 0x0100

;; CP/M BDOS system calls
SYSRESET:   = $0000
SYSCALL:    = $0005
C_WRITE:    = $02
C_WRITESTR: = $09

;; CEDA peripherals and reserved addresses
io_speaker:   = $da
io_kbdstatus: = $b3
io_kbddata:   = $b2

p_bs_off:     = $ffa4
p_bs_on:      = $ffa7
putc_attr:    = $ffcc
; Note: this value and the pointed contents are in AUX RAM!
p_keymap_base: = $b821
keymap_offset: = $0080

KBD_BOOTKEY:    = $4d
KBD_SHIFTFLAG   = $0
KBD_ALTFLAG     = $2
KBD_CTRLFLAG    = $3

PUBLIC _main
_main:
    ; reset stack pointer
    ld      sp,$0080

    ; Clear screen
    ld      de,STR_CLEAR
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    ; Put a welcome message describing this program
    ld      de,STR_WELCOME
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    ; beep, just for fun
    out     (io_speaker),a

    ; Manually fetch a key from the SIO, overriding the interrupt routine
    ; I need the raw data from the keyboard!
    ; TODO: can the ISR be temporary disabled?
loop_grabkey:
    ; place here the scancode and the flags
    ld      hl,bKbdScancode

    di
wait4scancode:
    call    readSio
    bit     7,a
    jr      nz,wait4scancode
    inc     hl
wait4flags:
    call    readSio
    bit     7,a
    jr      z,wait4flags
    ei

    ; Check if termination command was inserted
    ld      b,(hl)                          ; flags
    dec     hl
    ld      c,(hl)                          ; scancode
    ld      a,c
    bit     KBD_ALTFLAG,b                   ; check for ALT, else go on
    jr      z,continue
    bit     KBD_CTRLFLAG,b                  ; check for CTRL, else go on
    jr      z,continue
    cp      KBD_BOOTKEY                     ; check for BOOT
    jp      z,terminate                     ; CTRL + ALT + BOOT, terminate

continue:
    ;; Display the scancode
    ld      de,STR_SCANCODE
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    ld      a,(hl)
    call    prhex

    ;; Display the flags
    ld      de,STR_FLAGS
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    inc     hl
    ld      a,(hl)
    call    prhex

    ;; Display the matching ASCII code from the keymap table
    ld      de,STR_ASCII
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    ;; Address ASCII char from keymap table
    call    fetch_ascii
    push    af                  ; preserve a, PRHEX is destructive
    ; Print the HEX value of ASCII char
    call    prhex
    ; add a space
    ld      a,' '
    call    putch
    ; Print the actual ASCII char, even if non-printable
    ld      a,(putc_attr)
    ld      (bTmp),a            ; preserve the content of the "putchar" status register
    ld      a,1                 ; set putchar status to 1: now it will print non-printable characters
    ld      (putc_attr),a
    pop     af
    call    putch               ; restore ASCII character in a and print it
    ld      a,(bTmp)
    ld      (putc_attr),a           ; restore putchar status

    ;; Newline, then start back
    ld      de,STR_ENDL
    ld      c,C_WRITESTR
    call    GUARD_SYSCALL

    jr      loop_grabkey

terminate:
    jp      SYSRESET


readSio:
    in      a,(io_kbdstatus)
    bit     0,a
    jr      z,readSio
L01d2:
    in      a,(io_kbddata)
    ld      (hl),a
    ret


    ; prhex(a) - note: changes content of a!
prhex:
    push    af
    rra
    rra
    rra
    rra                                     ; a >>= 4
    call    prhexnibble
    pop     af
    call    prhexnibble
    ret
    ; prhexnibble(a)
prhexnibble:
    and     $0f
    cp      $0a
    jr      c,isNumber
    add     $07
isNumber:
    add     $30
    ; putch(a)
putch:
    ld      e,a
    ld      c,C_WRITE
    call    GUARD_SYSCALL
    ret

GUARD_SYSCALL:
    push    bc
    push    de
    push    hl
    call    SYSCALL
    pop     hl
    pop     de
    pop     bc
    ret

bs_off:
    ld      hl,(p_bs_off)
    jp      (hl)
    ; ret is in (p_bs_off)

bs_on:
    ld      hl,(p_bs_on)
    jp      (hl)
    ; ret is in (p_bs_on)

;; Address the keymap table and fetch the ASCII code matching the keypress
;; Copied and adapted from CEDA's CP/M BIOS
fetch_ascii:
    ; Bank switch off
    call    bs_off

    ld      a,(bKbdFlags)
    ld      b,a
    ld      a,(bKbdScancode)
    ld      c,a

    ld      hl,p_keymap_base
    ld      de,keymap_offset
    bit     KBD_ALTFLAG,b                   ; check if ALT
    jr      nz,is_alt
    bit     KBD_SHIFTFLAG,b                 ; check if shift
    jr      z,key_epilogue
    add     hl,de                           ; move table +$80
    jr      key_epilogue
is_alt:
    add     hl,de
    add     hl,de                           ; move table +$0100
key_epilogue:
    ld      e,c
    ld      d,$00
    add     hl,de
    ld      a,(hl)
    ; Bank switch on
    call bs_on
    ret

bKbdScancode:
    DB 0
bKbdFlags:
    DB 0
bTmp:
    DB 0

STR_CLEAR:
    DB      "\x1A$"
STR_BANKSW:
    DB      "\x0D\x0Ain 81 = $"
STR_WELCOME:
    DB      "\x0D\x0A\x09\x09\x09\x1B\x37\x1B\x41"
    DB      "** GRABKEY **"
    DB      "\x1B\x42\x1B\x58\x0D\x0A"
    DB      "241228 v1.0 by RetrOfficina GLG (retrofficina.glgprograms.it)\x0D\x0A"
    DB      "Press CTRL+ALT+BOOT to quit\x0D\x0A"
    DB      "$"
STR_SCANCODE:
    DB      "scancode: 0x$"
STR_FLAGS:
    DB      "\x09; flags: 0x$"
STR_ASCII:
    DB      "\x09; ASCII: 0x$"
STR_ENDL:
    DB      "\x0D\x0A"
    DB      "$"
