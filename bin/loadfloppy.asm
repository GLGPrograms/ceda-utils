    org 0x0100
;; https://www.isdaman.com/alsos/hardware/fdc/floppy.htm

; Brief explanation of this piece of code:
; - if ENABLE_MAX_SECTORBURST is set to 1, the smallest chunk of data is a whole track.
;   if ENABLE_MAX_SECTORBURST is set to 0, the smallest chunk of data is a single sector.
; - only two formatting modes are supported (256 bps and 1024 bps). The others were tested, but we could not be able to make them work.
; - When reading or writing, the buffer is resized to the proper amount of data (4K for 256 bps, 5K for 1024 bps).
; - After each disk access, the FDC status is always returned (7 bytes).

;;; Flags to change compilation behavior ;;;
; Set to just load CP/M from disk and boot
BOOT_CPM = 0
; Enable support to maximum sector burst (4KB or 5KB per track, depending on the
; selected formatting mode)
ENABLE_MAX_SECTORBURST = 1

;; TODO move this in a ceda ROM library
bios_bootkey = $c088

;; CEDA peripherals
io_speaker = $da

;; BIOS ROM routines
prhex      = $c174
putchar    = $c45e
putstr     = $c18f

fdc_rwfs = $c19d

fdc_initialize_drive  = $c423
fdc_write_data        = $c1f4
fdc_read_data         = $c24a
fdc_seek              = $c3a9
fdc_track0            = $c391
fdc_format            = $c2e3

;;; Memory areas ;;;
; floppy data buffer: where to store pending data from or to floppy
fdc_buffer   = $8000
; rwfs descriptor
fdc_desc     = $ffb8
; rwfs return values (ST0, ST1, ... from FDC)
fdc_return   = $ffc0
; offsets for fdc_desc
FDC_DESC_SSF   = 0
FDC_DESC_DRVHD = 1
FDC_DESC_SBCMD = 2
FDC_DESC_SCSBE = 3
FDC_DESC_TRACK = 4
FDC_DESC_BUFAD = 5

PUBLIC _main
_main:
    ; reset stack pointer
    ld      sp,$0080

    ; beep, just for fun
    out     (io_speaker),a

IF BOOT_CPM
    jp      bios_bootkey
ELSE
cmdloop:

    ; Clear the whole rwfs descriptor (except destination address)
    ld      hl, fdc_desc
    ld      c, FDC_DESC_BUFAD
clearloop:
    ld      (hl),0
    inc     hl
    dec     c
    jr      nz, clearloop

    ; set the buffer address in rwfs descriptor
    ld      bc,fdc_buffer
    ld      (hl),bc


    ;;; Read command from serial and prepare descriptor to be passed to rwfs ;;;

    ; wait aligment FF
    call    getch
    cp      $ff
    jr      nz, cmdloop

    ; read command, keep it in c
    call    getch
    and     3
    ld      c, a

    ; read track and put in descriptor
    call    getch
    ld      (fdc_desc+FDC_DESC_TRACK),a

    ; read sector and put in descriptor
    ; sector is discarded when ENABLE_MAX_SECTORBURST
    call    getch
IF !ENABLE_MAX_SECTORBURST
    ld      (fdc_desc+FDC_DESC_SCSBE),a
ENDIF

    ; read side and put it in descriptor
    call    getch
    or      a
    jr      z, side0
    ld      hl, fdc_desc+FDC_DESC_DRVHD
    set     2,(hl)
side0:

    ; pre-reset sector burst (kept resetted if ENABLE_MAX_SECTORBURST)
    ld      a, 0
    ld      (fdc_desc+FDC_DESC_SBCMD),a
    ; read bps and put it in descriptor
    call    getch
    and     a,3
    ld      (fdc_desc+FDC_DESC_SSF),a
IF ENABLE_MAX_SECTORBURST
    ld      b,4
    ; if bps = 3, 5 sectors, else 16
    cp      $03
    jr      z, small
    ld      b,15
small:
    ; load sector burst value and set burst enable without changing sector
    ld      a, b
    ld      (fdc_desc+FDC_DESC_SBCMD),a
    ld      a, (fdc_desc+FDC_DESC_SCSBE)
    set     7,a
    ld      (fdc_desc+FDC_DESC_SCSBE),a
ENDIF

    ; use the command to jump to the appropriate operation routine
    ; through jump table.
    ; Compute table offset
    ld     h, 0
    ld     l, c
    add    hl, hl
    ld     de, exetable
    add    hl, de
    ; Load address value in hl
    ld     a, (hl)
    inc    hl
    ld     h, (hl)
    ld     l, a

    ; send ack, ready to call rwfs
    ld      a, $ff
    call    putch

    ; call (exetable + cmd)()
    ; i need at least one call, see later
    call    jump2table

    ; do this forever
    jr      cmdloop

;;; - - - - - - - - - - - - - Service routines - - - - - - - - - - - - - - - ;;;

; Blocking read from the RS232
; Put the result in a
getch:
    ; SIO control register, channel A
    in      a,($b1)
    ; check if data available
    bit     0,a
    jr      z,getch
    ; a char is available
    in      a,($b0)
    ret

; Write a value to RS232
putch:
    push    af
putch_loop:
    ; SIO control register, channel A
    in      a,($b1)
    ; wait until tx buffer is empty
    bit     2,a
    jr      z,putch_loop
    pop     af
    ; send char
    out     ($b0),a
    ret

;; Copied rwfs to avoid putting things in register.
;; I want to use the fdc_desc directly.
myfdc_rwfs:
    ld      a,$0a
    ld      ($ffbf),a
    call    fdc_initialize_drive
    ld      a,($ffba)
    and     $f0
    jp      z,fdc_sw_track0
    cp      $40
    jp      z,fdc_sw_read_data
    cp      $80
    jp      z,fdc_sw_write_data
    cp      $20
    jp      z,fdc_sw_seek
    cp      $f0
    jp      z,fdc_sw_format
    ld      a,$ff
    jp      fdc_sw_default
fdc_sw_write_data:
    call    fdc_write_data
    jr      fdc_sw_default
fdc_sw_read_data:
    call    fdc_read_data
    jr      fdc_sw_default
fdc_sw_seek:
    call    fdc_seek
    jr      fdc_sw_default
fdc_sw_track0:
    call    fdc_track0
    jr      fdc_sw_default
fdc_sw_format:
    call    fdc_format
    jr      fdc_sw_default
fdc_sw_default:
    ret

;;; - - - - - - - - - - - - Commands and execution - - - - - - - - - - - - - ;;;

; just an indirect jump
jump2table:
    jp      (hl)

; the table and the commands
exetable:
    WORD read
    WORD write
    WORD format
    WORD null

; send the content of rwfs_status after each command execution
myfdc_send_status:
    ld      c,7
    ld      hl, fdc_return
send_status_loop:
    ld      a,(hl)
    call    putch
    inc     hl
    dec     c
    jr      nz, send_status_loop
    ret

; Read a sector or a track from the FDC and send it back through serial
read:
    ; add the read command to the rwfs descriptor without changing sector burst
    ld a,(fdc_desc+FDC_DESC_SBCMD)
    or $40
    ld (fdc_desc+FDC_DESC_SBCMD),a

    ; execute the operation
    call myfdc_rwfs

    ; send back the status registers
    call myfdc_send_status

    ; dump the buffer value through serial.
    ; Please note: buffer is sent even if read has failed. Please check ST0[7:6]

    ; Compute buffer size in bc from sector size factor
IF ENABLE_MAX_SECTORBURST
    ld      bc, 1024*5
    ld      a,(fdc_desc+FDC_DESC_SSF)
    cp      $03
    jr      z,rd_1024
    ld      bc, 256*16
rd_1024:
ELSE
    ld      bc, 1024
    ld      a,(fdc_desc+FDC_DESC_SSF)
    cp      $03
    jr      z,rd_1024
    ld      bc, 256
rd_1024:
ENDIF
    ld      hl, fdc_buffer
readloop:
    ld      a,(hl)
    call    putch
    inc     hl
    dec     c
    jr      nz, readloop
    dec     b
    jr      nz, readloop

    ret

; Write a sector or a track from serial to the FDC
write:
    ; read the buffer from uart
    ld      hl, fdc_buffer
    ; Compute buffer size in bc from sector size factor
IF ENABLE_MAX_SECTORBURST
    ld      bc, 1024*5
    ld      a,(fdc_desc+FDC_DESC_SSF)
    cp      $03
    jr      z,wr_1024
    ld      bc, 256*16
wr_1024:
ELSE
    ld      bc, 1024
    ld      a,(fdc_desc+FDC_DESC_SSF)
    cp      $03
    jr      z,wr_1024
    ld      bc, 256
wr_1024:
ENDIF
writeloop:
    call    getch
    ld      (hl),a
    inc     hl
    dec     c
    jr      nz, writeloop
    dec     b
    jr      nz, writeloop

    ; add the write command to the rwfs descriptor without changing sector burst
    ld      a,(fdc_desc+FDC_DESC_SBCMD)
    or      $80
    ld      (fdc_desc+FDC_DESC_SBCMD),a

    ; execute the operation
    call    myfdc_rwfs

    ; send back the status registers
    ; (use the ret in myfdc_send_status)
    jp      myfdc_send_status

; Just format a track
format:
    ; populate sector IDs in fdc_buffer.
    ; Memory is dumbly populated with sequential sectors and regardless of how
    ; many sectors will be inside a track.
    ; The rwfs routine will use the needed size depending on SSF.
    ld c, 1
    ld hl, fdc_buffer
id_buf_loop:
    ; first field: track number
    ld      a, (fdc_desc+FDC_DESC_TRACK)
    ld      (hl),a
    inc     hl

    ; second field: side
    ld      (hl), 0
    ld      a, (fdc_desc+FDC_DESC_DRVHD)
    or      a
    jr      z, side0id
    set     0,(hl)
side0id:
    inc     hl

    ; third field: sector index
    ld      (hl),c
    inc     hl

    ; fourth field: sector size factor
    ld      a, (fdc_desc+FDC_DESC_SSF)
    ld      (hl), a
    inc     hl

    inc     c
    ld      a, 18
    cp      c
    jp      nz, id_buf_loop

    ; add the format command. The sector burst can be altered since is ignored
    ld a,$f0
    ld (fdc_desc+FDC_DESC_SBCMD),a

    ; execute the operation
    call    myfdc_rwfs

    ; send back the status registers
    ; (use the ret in myfdc_send_status)
    jp myfdc_send_status


; just beep and send back bogus status. A debug command.
null:
    ; beep
    out     (io_speaker),a
    jp      myfdc_send_status

ENDIF
