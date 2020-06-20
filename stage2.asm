global _stage2
extern real_mode_print_char

BITS 16

_stage2:
    mov al, '2'
    call real_mode_print_char

loop:
    jmp loop