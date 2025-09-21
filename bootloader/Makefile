include config.mk

BUILDDIR := $(OUTDIR)/bootloader

all: $(BUILDDIR)/v101.bootloader.bin

$(BUILDDIR)/v101.bootloader.bin: $(BUILDDIR)/v101.bin
	xxd $< > $(BUILDDIR)/v101.xxd
	patch $(BUILDDIR)/v101.xxd bootloader/bootloader.patch
	xxd -r < $(BUILDDIR)/v101.xxd > $@

$(BUILDDIR)/v101.bin: | $(BUILDDIR)
	wget -O $@ https://github.com/GLGPrograms/ceda-home/raw/refs/heads/main/assets/v1.01_rom.bin
	truncate -s 4096 $@

$(BUILDDIR):
	mkdir -p $@
