; This is the ELOS7 Source Code
; Memory Map
; QWORD		0x600 TSC start
; DWORD		0x608 LFB ptr
; DWORD[]	0x5000 PD
; DWORD[]	0x6000 PT <1MB ident.

; TODO:
; - Get drive parameters (currently hardcoded to native primary master ATA)
; - Make Disk driver an LCF module
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
	mov ax, 0x0201
	mov bx, 0x7e00
	mov cx, 0x0002
	mov dh, 0
	int 0x13
	rdtsc
	mov dword[0x600], eax
	mov dword[0x604], ecx
	mov ax, 0x4f00
	mov di, 0x1000
	mov dword[di], "2EBV"
	push es
	int 0x10
	pop es
	cmp ax, 0x004f
	jne videoError
	mov di, 0x1000
	cmp dword[di], "VESA"
	jne videoError
	mov si, word[di+0x0e]
	mov ax, word[di+0x10]
	mov ds, ax
videoSearch:
	lodsw
	cmp ax, 0xffff
	je videoError
	mov cx, ax
	mov ax, 0x4f01
	mov di, 0x1200
	push si
	push es
	int 0x10
	pop es
	pop si
	cmp byte[0x1219], 32
	jne videoSearch
	cmp word[0x1212], 1280
	jne videoSearch
	cmp word[0x1214], 1024
	jne videoSearch
	mov eax, dword[0x1228]
	mov dword[0x608], eax
	mov bx, word[si-2]
	or bx, 0x4000
	mov ax, 0x4f02
	int 0x10
	; Set RAM sectors
	xor ebx, ebx
	mov ax, 0x6000
	mov es, ax
	mov di, 0x0000
	mov byte[0x608], 0
bootRamFind:
	mov eax, 0xe820
	mov ecx, 24
	mov edx, 0x534D4150
	int 0x15
	cmp eax, 0x534D4150
	jne bootRamFind
	cmp ebx, 0
	je bootRamFind_end
	cmp dword[es:di+0x4], 0
	jne bootRamFind
	cmp dword[es:di+0x10], 1
	jne bootRamFind
	mov eax, dword[es:di]
	cmp eax, 0x100000
	jb bootRamFind
	add di, 16
	inc byte[0x608]
	jmp bootRamFind
bootRamFind_end:
	; Start protected mode
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
	; Initialize <1MB PD/PT
	mov dword[0x5000], 0x6003
	mov eax, 1
	mov edi, 0x6000
	mov ecx, 0x400
pageCreateSystemMB:
	stosd
	add eax, 0x1000
	loop pageCreateSystemMB
	; Initialize VRAM PD
	mov edi, 0x5f00
	movzx ebx, word[0x608]
	movzx ecx, word[0x60a]
	imul ecx, ebx
	shr ecx, 22
	inc ecx
	mov eax, dword[0x1228]
	and eax, 0xffdf0000
	mov al, 0x83
pageCreateVRAM:
	stosd
	add eax, 0x400000
	loop pageCreateVRAM
	; Start paging (CR4.PSE set)
	mov eax, 0x5000
	mov cr3, eax
	mov eax, cr4
	or eax, 0x00000010
	mov cr4, eax
	mov eax, cr0
	or eax, 0x80000001
	mov cr0, eax
	call initializeMemory
	call kernelPageAllocate
	mov edi, edx
	mov ax, 0xffff
	mov bx, 0x0001
	call registerContainer
	mov edi, 0x10000
	mov eax, 1
	call readDiskSector
	cli
	hlt
times 510 - ($ - $$) db 0
	dw 0xaa55
%include "kernel/memory.s"
%include "kernel/container.s"
%include "kernel/disk.s"
