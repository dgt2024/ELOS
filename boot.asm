section .boot vstart=0x7c00
use16
start:
	cli
	cld
	
	; Setup Segment Selectors
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov sp, 0x7c00
	int 0x10
	
	; Get kernel from disk
	mov ax, 0x0201
	mov bx, 0x7e00
	mov cx, 0x0002
	mov dh, 0
	int 0x13
	
	; Store TSC clock at boot
	rdtsc
	mov dword[0x600], eax
	mov dword[0x604], ecx
	
	; Get VESA data
	mov ax, 0x4f00
	mov di, 0x1000
	mov dword[di], "2EBV"
	
	push es
	int 0x10
	pop es
	
	cmp ax, 0x004f
	jne videoError
	
	cmp dword[0x1000], "VESA"
	jne videoError
	
	; 0x1000=data
	mov si, word[0x100e]
	mov ax, word[0x1010]
	mov ds, ax
	
	; Find 1280x1024x32bpp
videoSearch:
	lodsw
	cmp ax, 0xffff
	je videoError
	
	; Get mode info
	mov cx, ax
	mov ax, 0x4f01
	mov di, 0x1200
	
	push si
	push es
	int 0x10
	pop es
	pop si
	
	; 0x1200=data
	cmp byte[0x1219], 32
	jne videoSearch ; 32bpp?
	
	cmp word[0x1212], 1280
	jne videoSearch ; 1280 width?
	
	cmp word[0x1214], 1024
	jne videoSearch ; 1024 width?
	
	mov eax, dword[0x1228]
	mov dword[0x608], eax
	
	; Set current mode
	mov bx, word[si-2]
	or bx, 0x4000
	mov ax, 0x4f02
	
	int 0x10
	
	; Set RAM sectors
	xor ebx, ebx
	mov ax, 0x6000
	mov es, ax
	mov di, 0x0000 ; Write RAM map to 0x60000
	mov byte[0x60c], 0 ; RAM map block count
	
	; Iterate RAM blocks
bootRamFind:
	; Get RAM block
	mov eax, 0xe820
	mov ecx, 24
	mov edx, 0x534D4150
	
	int 0x15
	
	cmp eax, 0x534D4150 ; Success?
	jne bootRamFind
	
	test ebx, ebx ; Circled back to first entry?
	jz bootRamFind_end
	
	cmp dword[es:di+0x4], 0 ; Block Size 0?
	jne bootRamFind
	
	cmp dword[es:di+0x10], 1 ; Usable RAM?
	jne bootRamFind
	
	; Get RAM map
	cmp dword[es:di], 0xa0000 ; Kernel Data?
	jb bootRamFind
	
	; Next item
	add di, 16
	inc byte[0x60c]
	jmp bootRamFind
bootRamFind_end:

	; Set up GDT table
	lgdt [gdtTable]
	
	; Set CR0 flags
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax
	
	; Jump
	jmp 0x08:protectedMain
	
videoError:
	cli
	hlt

; GDT table
gdtTable:
	dw gdtDescriptorTable_end - gdtDescriptorTable - 1
	dd gdtDescriptorTable
gdtDescriptorTable:
	dq 0
	dq 0x00cf9a000000ffff
	dq 0x00cf92000000ffff
gdtDescriptorTable_end:

use32
protectedMain:
	; Setup 32-bit segment selectors
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x7c00
	
	; Initialize kernel data pages
	mov dword[0x5000], 0x6003 ; Kernel data PT
	mov eax, 1 ; Flags (identity mapping)
	mov edi, 0x6000 ; Kernel data PTE
	mov ecx, 0x400 ; Count
	
	; Create PDE kernel data
pageCreateSystemMB:
	stosd
	add eax, 0x1000
	loop pageCreateSystemMB
	
	; Initialize VRAM PD
	mov edi, 0x5f00
	
	; Get VRAM size in megabytes
	movzx ebx, 1280 ; width
	movzx ecx, 1024 ; height
	imul ecx, ebx
	shr ecx, 22
	inc ecx
	
	; Initialize VRAM pages
	mov eax, dword[0x1228] ; VRAM pointers
	and eax, 0xffdf0000 ; Masking
	mov al, 0x83 ; Flags
	
	; Create PDE for VRAM data
pageCreateVRAM:
	stosd
	add eax, 0x400000
	loop pageCreateVRAM
	
	; Set CR3
	mov eax, 0x5000
	mov cr3, eax
	
	; Set CR4.PSE for VRAM
	mov eax, cr4
	or eax, 0x00000010
	mov cr4, eax
	
	; Set CR0 paging flags
	mov eax, cr0
	or eax, 0x80000001
	mov cr0, eax

	; Temporarily end
	cli
	hlt
times 510 - ($ - $$) db 0
	dw 0xaa55
%include "kernel/memory.s"
%include "kernel/container.s"
%include "kernel/disk.s"
%include "kernel/procedure.s"
