    org 0x1000

prhex = $c174
putchar = $c45e

fdc_rwfs_c19d = $c19d

PUBLIC _main
_main:
    ; Boot trampoline executed when BOOT key is pressed
bios_bootkey:
    ld      de,$0000                        ;[c088] d = track = 0; e = sector = 0
    ld      bc,$4000                        ;[c08b] b = cmd = read ($40); c = drive = 0
    ld      hl,$0080                        ;[c08e] load in $0080
    ld      a,$01                           ;[c091] formatting mode, seems to be 384 bytes per sector
    call    fdc_rwfs_c19d                   ;[c093] invoke reading
    cp      $ff                             ;[c096] check for error...
    jr      nz,bios_bootdisk                ;[c098] ...if ok, go on with loading
    out     ($da),a                         ;[c09a] ... else, beep and try again
    jr      bios_bootkey                    ;[c09c]
    ; if disk has been correctly copied into RAM, execute it
bios_bootdisk:
    ld      a,$06                           ;[c09e] load A with $06
    out     ($b2),a                         ;[c0a0] send to keyboard
    out     ($da),a                         ;[c0a2] sound speaker beep
    jp      $0080                           ;[c0a4] execute fresh code from ram

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