global _start
extern _stage2
extern _stage2data

BITS 16

_start:
    xor ax, ax
    mov es, ax
    mov gs, ax
    mov ss, ax
    mov sp, _start
    cld

    mov ax, 0x7C0
    mov ds, ax

    mov al, '1'
    call real_mode_print_char
    call real_mode_new_line

    mov dh, 0x0
    mov dl, 0x0
    mov bx, dx
    call real_mode_print_hex

load_sector_2:
    mov  al, 0x01           ; load 1 sector
    mov  bx, 0x7E00         ; destination (might as well load it right after your bootloader)
    mov  cx, 0x0002         ; cylinder 0, sector 2
    ; mov  dl, [BootDrv]      ; boot drive
    xor  dh, dh             ; head 0
    call read_sectors_16
    jnc execute_stage2           ; if carry flag is set, either the disk system wouldn't reset, or we exceeded our maximum attempts and the disk is probably shagged
    jmp error

execute_stage2:
    mov bx, [_stage2data]
    call real_mode_print_hex

    jmp _stage2

error:
    mov al, 'E'
    call real_mode_print_char

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

# print a number in hex
# IN
#   bx: the number
# CLOBBER
#   al, cx
real_mode_print_hex:
    mov cx, 4
.lp:
    mov al, bh
    shr al, 4

    cmp al, 0xA
    jb .below_0xA

    add al, 'A' - 0xA - '0'
.below_0xA:
    add al, '0'

    call real_mode_print_char

    shl bx, 4
    loop .lp

    call real_mode_new_line

    ret

real_mode_new_line:
    mov al, 0x0D
    call real_mode_print_char
    mov al, 0x0A
    call real_mode_print_char

real_mode_print_char:
    push bx
    xor bx, bx              ; Attribute=0/Current Video Page=0
    mov ah, 0x0e
    int 0x10                ; Display character
    pop bx
    ret

; boot signature
TIMES 510-($-$$) db 0

mbr_id:
dw 0xAA55