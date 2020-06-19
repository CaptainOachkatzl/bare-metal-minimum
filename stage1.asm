global _start
extern _stage2

BITS 16

_start:
    xor ax, ax
    mov es, ax
    mov gs, ax
    mov ss, ax
    mov sp, _start
    cld

    mov al, '1'
    call bios_print_char

load_sector_2:
    mov  al, 0x01           ; load 1 sector
    mov  bx, 0x7E00         ; destination (might as well load it right after your bootloader)
    mov  cx, 0x0002         ; cylinder 0, sector 2
    ; mov  dl, [BootDrv]      ; boot drive
    xor  dh, dh             ; head 0
    call read_sectors_16
    jnc  execute_stage2           ; if carry flag is set, either the disk system wouldn't reset, or we exceeded our maximum attempts and the disk is probably shagged
    mov  al, 'E'
    call bios_print_char
    jmp loop

execute_stage2:
    jmp _stage2

    mov ax, 0x7c0
    mov ds, ax
loop:
    jmp loop

; read_sectors_16
;
; Reads sectors from disk into memory using BIOS services
;
; input:    dl      = drive
;           ch      = cylinder[7:0]
;           cl[7:6] = cylinder[9:8]
;           dh      = head
;           cl[5:0] = sector (1-63)
;           es:bx  -> destination
;           al      = number of sectors
;
; output:   cf (0 = success, 1 = failure)

read_sectors_16:
    push ax
    mov si, 0x02    ; maximum attempts - 1
.top:
    mov ah, 0x02    ; read sectors into memory (int 0x13, ah = 0x02)
    int 0x13
    jnc .end        ; exit if read succeeded
    dec si          ; decrement remaining attempts
    jc  .end        ; exit if maximum attempts exceeded
    xor ah, ah      ; reset disk system (int 0x13, ah = 0x00)
    int 0x13
    jnc .top        ; retry if reset succeeded, otherwise exit
.end:
    pop ax
    retn

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