/** The "start"-symbol from start.S. */
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
