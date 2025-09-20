include config.mk

# one-file utilities in assembly, for CP/M
# each file is compiled and linked indipendently
# and produces a final binary executable
SRC := \
		   cpm/grabkey.asm      \
		   cpm/hellocpm.asm     \
		   #

COM := $(patsubst %.asm,%.com,$(addprefix $(OUTDIR)/,$(SRC)))

all: $(COM)

$(OUTDIR)/%.com: %.asm
	z80asm -b -l -O$(OUTDIR) -ocpm/$(notdir $@) $<

