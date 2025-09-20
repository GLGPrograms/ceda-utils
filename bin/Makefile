include config.mk

# one-file utilities in assembly, to load directly with BIOS ROM
# each file is compiled and linked indipendently
# and produces a final binary executable
SRC := \
		   bin/interrupt.asm    \
		   bin/loadfloppy.asm   \
		   #

BIN := $(patsubst %.asm,%.bin,$(addprefix $(OUTDIR)/,$(SRC)))
PKT := $(BIN:.bin=.pkt)

.PHONY: all
all: $(PKT)

%.pkt: %.bin
	python3 script/makepacket.py $< > $@

$(OUTDIR)/%.bin: %.asm
	z80asm -b -l -O$(OUTDIR) -obin/$(notdir $@) $<

