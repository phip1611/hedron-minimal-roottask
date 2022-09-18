/*
MIT License

Copyright (c) 2022 Philipp Schuster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/* The "start"-symbol from start.S. */
ENTRY(start)

OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH("i386:x86-64")

PHDRS
{
    rx    PT_LOAD FLAGS(5); /* 0b101 */
    ro    PT_LOAD FLAGS(4); /* 0b100 */
    rw    PT_LOAD FLAGS(6); /* 0b110 */
}

SECTIONS {

    /* Link Address: 4 MiB */
    . = 0x400000;


    /* Syntax is described here: https://sourceware.org/binutils/docs/ld/Output-Section-Attributes.html */
    /* Always align link address and offset within the ELF-file to a 4k (=page) boundary. */
    .text ALIGN(4K) : ALIGN(4K)
    {
        /* Assembly Code */
        *(.text.init)
        /* Rust Code */
        *(.text .text.*)
    } : rx

    .rodata ALIGN(4K) : ALIGN(4K)
    {
        *(.rodata .rodata.*)
    } : ro

    .data ALIGN(4K) : ALIGN(4K)
    {
        *(.data .data.*)
        *(COMMON)

        /* put .bss in .data
         Otherwise the linker creates a LOAD-segment where file size != mem size.
         Hedron doesn't support this, because it maps the ELF directly into memory
         without further allocations etc. */
        *(.bss .bss.*)
    } : rw

    /* Information for unwinding & backtraces */
    /DISCARD/ :
    {
        *(.eh_frame*)
    } : ro

}
