global _stage2
global _stage2data

BITS 16

_stage2:
    mov al, '2'
    call bios_print_char

loop:
    jmp loop

    bios_print_char:
    push bx
    xor bx, bx              ; Attribute=0/Current Video Page=0
    mov ah, 0x0e
    int 0x10                ; Display character
    pop bx
    ret

; boot signature
TIMES 510-($-$$) db 0
_stage2data:
dw 0xCC77