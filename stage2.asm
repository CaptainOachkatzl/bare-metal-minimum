global _stage2
extern real_mode_print_string
extern real_mode_print_hex

STACK32_TOP EQU 0x200000
VIDEOMEM    EQU 0x0b8000
MBR_ENTRY_ADDRESS EQU 0x7C00
CODE_SEG EQU codedesc - gdt32   ; offset of the code segment selector in the GDP
DATA_SEG EQU datadesc - gdt32   ; offset of the data segment selector in the GDP

VGA_SCREEN_HEIGHT EQU 25
VGA_SCREEN_WIDTH EQU 160

BITS 16
ALIGN 4

_stage2:
    mov si, stage2_loading_string
    call real_mode_print_string

load_gdt:
    cli

    lgdt [gdt32info]

    ; set protected mode bit: cr0 - bit 0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp CODE_SEG:code_32bit + MBR_ENTRY_ADDRESS

code_32bit:
BITS 32     ; add the 32 bit prefix to all the instructions after this
ALIGN 4     ; align memory to 4 byte / 32 bit

    ; set segment registers to GDT data selector
    mov eax, DATA_SEG       ; set to data selector of GDT
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax
    mov esp, STACK32_TOP    ; initialize 32bit stack
    mov ebp, STACK32_TOP

    ; print company logo on the bottom left
    mov si, company_logo + MBR_ENTRY_ADDRESS    ; need to offset the address because the GDT entry states the base address offset is 0x0
    mov ebx, VIDEOMEM + ((VGA_SCREEN_WIDTH) * (VGA_SCREEN_HEIGHT - 1))
    call print_vga_string_32bit

halt:
    cli
    hlt
    jmp halt

; print string
; IN
;   si : pointer to string
;   ebx : vga start address
; CLOBBER
;   ax
print_vga_string_32bit:
    lodsb
    or al, al
    jz .end_of_string   ; jump if last loaded byte was 0 (end of string)
    call print_vga_char_32bit
    add ebx, 2          ; move 'cursor' to the next character position
    jmp print_vga_string_32bit
.end_of_string:
    ret

print_vga_char_32bit:   
    mov ah, 0x0F        ; print white character on black background
    mov word [ebx], ax
    ret

stage2_loading_string:
    db 'Stage 2...', 0

company_logo:
    db 'XSWare', 0

gdt32info:
    dw gdt32_end - gdt32 - 1    ; size - decrement by 1 because size = 0 is not allowed 
                                ; and this way size can be the full 65536 bytes
    dw gdt32 + MBR_ENTRY_ADDRESS  ; offset/start of table + the MBR offset
    
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