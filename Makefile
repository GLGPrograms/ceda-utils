.POSIX:

ECHO	:=	@echo
QUIET	:=	@

OUTDIR		:= build
SERIALPORT	:= /dev/ttyUSB0

$(OUTDIR)/main.bin: main.asm
	$(ECHO) '	ASM'
	$(QUIET) mkdir -p $(OUTDIR)
	$(QUIET) zcc +z80 -subtype=none -o $(OUTDIR)/main.bin main.asm

.PHONY: send
send: $(OUTDIR)/main.bin.pkt
	$(ECHO) '	SEND'
	$(QUIET) stty -F $(SERIALPORT) 9600 -crtscts
	$(QUIET) cat "$<" > $(SERIALPORT)

$(OUTDIR)/%.bin.pkt: $(OUTDIR)/%.bin
	$(ECHO) '	PKT'
	$(QUIET) python3 makepacket.py "$<"

.PHONY: clean
clean:
	$(ECHO) '	RM'
	$(QUIET) rm -rf $(OUTDIR)

