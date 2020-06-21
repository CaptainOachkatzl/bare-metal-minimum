global _start
global real_mode_print_string
extern _stage2

BITS 16

_start:
; init registers
    xor ax, ax
    mov es, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00      ; right before MBR, counting upwards

    mov ax, 0x7C0       ; set DS to 0x7c0 so pointing at 0x0 resolves to 0x7C0:x0000 = 0x7C00
    mov ds, ax

    cld                 ; set direction flag to make string operations count forward

 ; mark start of stage 1 by printing loading string
    mov si, stage1_loading_string
    call real_mode_print_string
    call real_mode_new_line

enable_a20:
; enable A20-Line via IO-Port 92
    in al, 0x92
    test al, 2
    jnz post_a20_enabled
    or al, 2
    and al, 0xFE
    out 0x92, al
post_a20_enabled:

load_sector2:
; boot drive is stored in DL by bios
    mov  al, 0x01           ; load 1 sector
    mov  bx, 0x7E00         ; destination, right after your bootloader
    mov  cx, 0x0002         ; cylinder 0, sector 2
    xor  dh, dh             ; head 0
    call read_sectors_16
    jnc execute_stage2           ; if carry flag is set, disk read failed
    jmp error

execute_stage2:
    jmp _stage2                 ; start execude instructions of _stage2

error:
; print error message
    mov si, error_loading_string
    call real_mode_print_string

; infinite loop
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

; print string
; IN
;   si : pointer to string
; CLOBBER
;   al
real_mode_print_string:
    lodsb
    or al, al
    jz .done
    call real_mode_print_char
    jmp real_mode_print_string
.done: 
    ret

real_mode_new_line:
    mov al, 0x0D
    call real_mode_print_char
    mov al, 0x0A
    call real_mode_print_char
    ret

real_mode_print_char:
    push bx
    xor bx, bx              ; Attribute=0/Current Video Page=0
    mov ah, 0x0e
    int 0x10                ; Display character
    pop bx
    ret

stage1_loading_string:
    db 'Stage 1...', 0
error_loading_string:
    db 'Error while loading stage 2 from disk!', 0

gdt32info:
    dw gdt32_end - gdt32 - 1    ; size - decrement by 1 because size = 0 is not allowed 
                                ; and this way size can be the full 65536 bytes
    dw gdt32                    ; offset/start of table

gdt32:
    dq 0   ; first segment descriptor of GDT -> unused
codedesc:
    ; code segment descriptor, Executable bit Ex must be set, RW set to make segment readable
    ; with Gr set to 1 the granularity is set to 4KiB, combined with limit = 0xFFFFFF,  64GB of memory is addressable
    ; because of 32 bit address registers -> 4GB addressable
    ; L has to be zero if Sz is set because combination is reserved and will throw an exception otherwise
    dw 0xFFFF       ; limit/segment 0-15
    dw 0x0000       ; base addr 0-15
    db 0x00         ; base addr 16-23
    db 0b10011010   ; access byte -> in order: Pr - Privi2 - Privi1 - S - Ex - DC - RW - Ac
    db 0b11001111   ; first 4 bits = flags, Gr - Sz - L - 0; last 4 bits = limit/segment 16-19
    db 0x00         ; base addr 24-31
datadesc:
    ; data segment descriptor, Executable bit Ex must not be set, RW set to make segment writeable
    dw 0xFFFF       ; limit/segment 0-15
    dw 0x0000       ; base addr 0-15
    db 0x00         ; base addr 16-23
    db 0b10010010   ; access byte -> in order: Pr - Privi2 - Privi1 - S - Ex - DC - RW - Ac
    db 0b11001111   ; first 4 bits = flags, Gr - Sz - L - 0; last 4 bits = limit/segment 16-19
    db 0x00         ; base addr 24-31
gdt32_end:

; boot signature
    TIMES 510-($-$$) db 0
    dw 0xAA55