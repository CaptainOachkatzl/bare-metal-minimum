ENTRY(_start)

SECTIONS {
    . = 0x500;
    /* buffer for loading the kernel */
    _kernel_buffer = .;

    _stack_start = .;
    . = 0x7c00;
    _stack_end = .;

    .bootloader :
    {
        /* first stage */
        *(.boot-first-stage)

        /* rest of bootloader */
        _rest_of_bootloader_start_addr = .;
        *(.boot)
        *(.context_switch)
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.data .data.*)
        *(.got)
        . = ALIGN(512);
        _rest_of_bootloader_end_addr = .;
        __bootloader_end = .;
    }
}