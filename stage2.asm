global _stage2
extern real_mode_print_string
extern real_mode_print_hex

STACK32_TOP EQU 0x200000
VIDEOMEM    EQU 0x0b8000
MBR_ENTRY_ADDRESS EQU 0x7C00
CODE_SEG EQU codedesc - gdt32   ; offset of the code segment selector in the GDP
DATA_SEG EQU datadesc - gdt32   ; offset of the data segment selector in the GDP

ALIGN 4

BITS 16

debug:
    mov bx, 0xDEB0
    call real_mode_print_hex
loop16:
    jmp loop16

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

    ; jmp instruction clears prefetch
    jmp clear_prefetch
    nop
    nop

clear_prefetch:
    ; set segment registers to GDT data selector
    mov ax, DATA_SEG        ; 0x10 is flat selector for data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, STACK32_TOP

halt:
    cli
    hlt
    jmp halt

    ; long jmp to 0x8:code_bit32
    db 0x66
    db 0xEA
    dd code_32bit
    dw CODE_SEG

BITS 32
code_32bit:
    ; write character to VGA buffer
    mov eax,0xb8000
    mov word [Eax],0x4141

loop32:
    jmp loop32    

stage2_loading_string:
    db 'Stage 2...', 0

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