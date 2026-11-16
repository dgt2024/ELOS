section .boot vstart=0x7c00
use16
start:
	cli
	cld
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
	
	; Store TSC clock to logging stats
	rdtsc
	mov dword[0x600], eax
	mov dword[0x604], ecx
	
	; Search for 1280x1024x32bpp
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
	
	; Get mode array to iterate
	mov si, word[0x100e]
	mov ax, word[0x1010]
	mov ds, ax
	
videoSearch:
	lodsw
	cmp ax, 0xffff
	je videoError
	
	; Find VBE mode resolution
	mov cx, ax
	mov ax, 0x4f01
	mov di, 0x1200
	push si
	push es
	int 0x10
	pop es
	pop si
	
	; Check whether mode was found
	cmp byte[0x1219], 32
	jne videoSearch
	
	cmp word[0x1212], 1280
	jne videoSearch
	
	cmp word[0x1214], 1024
	jne videoSearch
	
	; Find framebuffer pointer
	mov eax, dword[0x1228]
	mov dword[0x608], eax
	
	; Set mode
	mov bx, word[si-2]
	or bx, 0x4000
	mov ax, 0x4f02
	int 0x10
	
	; Read RAM block array
	xor ebx, ebx
	mov ax, 0x6000
	mov es, ax
	mov di, 0x0000
	mov byte[0x60c], 0
bootRamFind:
	; Get RAM block
	mov eax, 0xe820
	mov ecx, 24
	mov edx, 0x534D4150
	int 0x15
	
	cmp eax, 0x534D4150
	jne bootRamFind
	
	test ebx, ebx ; Item 0
	jz bootRamFind_end
	
	cmp dword[es:di+0x4], 0 ; offset ram.size
	jne bootRamFind
	
	cmp dword[es:di+0x10], 1 ; offset ram.type (1=usable)
	jne bootRamFind
	
	; Limit to non-kernel areas
	cmp dword[es:di], 0xa0000
	jb bootRamFind

	add di, 16
	inc byte[0x60c]
	jmp bootRamFind
bootRamFind_end:
	
	; Switch to 32-bit mode
	lgdt [gdtTable]
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax
	jmp 0x08:protectedMain
	
videoError:
	cli
	hlt

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
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x7c00
	
	; Initialize kernel data pages
	mov dword[0x5000], 0x6003
	mov eax, 1
	mov edi, 0x6000
	mov ecx, 0x400
	
pageCreateSystemMB:
	stosd
	add eax, 0x1000
	loop pageCreateSystemMB
	
	; Initialize VRAM data pages
	mov edi, 0x5f00
	
	; Get VRAM size in megabytes
	movzx ebx, 1280
	movzx ecx, 1024
	imul ecx, ebx
	shr ecx, 22
	inc ecx
	
	; Get VRAM pointer
	mov eax, dword[0x1228]
	and eax, 0xffdf0000
	mov al, 0x83
	
pageCreateVRAM:
	stosd
	add eax, 0x400000
	loop pageCreateVRAM
	
	; Set up page directory
	mov eax, 0x5000
	mov cr3, eax
	
	; Set CR4.PSE for larger pages
	mov eax, cr4
	or eax, 0x00000010
	mov cr4, eax
	
	; Start paging
	mov eax, cr0
	or eax, 0x80000001
	mov cr0, eax

	cli
	hlt
times 510 - ($ - $$) db 0
	dw 0xaa55
%include "kernel/memory.s"
%include "kernel/container.s"
%include "kernel/disk.s"
%include "kernel/procedure.s"
