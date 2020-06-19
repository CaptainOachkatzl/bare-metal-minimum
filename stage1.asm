global _start
extern _stage2

BITS 16

_start:
    xor ax, ax
    mov ds, ax
    mov ss, ax

    mov al, '1'
    call bios_print_char

loop:
    jmp _stage2

bios_print_char:
    push bx
    xor bx, bx              ; Attribute=0/Current Video Page=0
    mov ah, 0x0e
    int 0x10                ; Display character
    pop bx
    ret

; boot signature
TIMES 510-($-$$) db 0
dw 0xAA55