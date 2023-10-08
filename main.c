#include <stdint.h>

char* const VIDEO_MEMORY = (char* const)0xd000;

static void vprint(int row, int column, const char* str);
static void out(uint8_t ioaddr, uint8_t value);

int entrypoint() {
    __asm
    ld sp,0xc000
    __endasm;

    vprint(20,10,"hello world");
    out(0x81, 0x80);
    vprint(20,15,"aaaaa");

    for (;;)
        ;
}

static void out(uint8_t ioaddr, uint8_t value) {
    __asm
    ld  ix,$0000
    add ix,sp
    ld  b,(ix + 5)
    ld  c,(ix + 4)
    out (c),b
    __endasm;
}

static void cls(void) {
    for (int i = 0; i < 2000; ++i) {
        VIDEO_MEMORY[i] = 0x20;
    }
}

static void vprint(int row, int column, const char* str) {
    char* p = VIDEO_MEMORY + row * 80 + column;
    while (*str != '\0') {
        *p++ = *str++;
    }
}

