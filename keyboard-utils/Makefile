.POSIX:

ECHO	:=	@echo
QUIET	:=	@

OUTDIR		:= build
SERIALPORT	:= /dev/ttyUSB0

$(OUTDIR)/GRABKEY.COM: grabKey.asm
	$(ECHO) '	ASM'
	$(QUIET) mkdir -p $(OUTDIR)
	$(QUIET) z80asm grabKey.asm -b -l -o$(OUTDIR)/GRABKEY.COM


.PHONY: prg
prg: $(OUTDIR)/GRABKEY.COM.prg

$(OUTDIR)/%.COM.prg: $(OUTDIR)/%.COM
	$(ECHO) '	PRG'
	$(QUIET) python3 ../script/makeprg.py "$<"

.PHONY: clean
clean:
	$(ECHO) '	RM'
	$(QUIET) rm -rf $(OUTDIR)

