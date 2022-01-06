/*
MIT License

Copyright (c) 2021 Philipp Schuster

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
    /* Not 100% sure but the presence of this macro forces the Linker to do some
       (apparently) important internal calculations. */
    . += SIZEOF_HEADERS;

    .text : ALIGN (4096)
    {
        *(.text .text.*)
    } : rx

    .rodata : ALIGN (4096)
    {
        *(.rodata .rodata.*)
    } : ro

    .data : ALIGN (4096)
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
    .eh_frame : ALIGN (4096)
    {
        *(.eh_frame*)
    } : ro

}
