global _stage2
extern real_mode_print_string

BITS 16

_stage2:
    mov si, stage2_loading_string
    call real_mode_print_string

loop:
    jmp loop

stage2_loading_string:
    db 'Stage 2...', 0