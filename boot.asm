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
	mov ax, 0x0203
	mov bx, 0x7e00
	mov cx, 0x0002
	mov dh, 0
	int 0x13

	; Get kernelproc from disk
	mov ax, 0x0201
	mov bx, 0x9000
	mov cx, 0x0005
	mov dh, 0
	int 0x13

	; Store TSC clock to logging stats
	rdtsc
	mov dword[0x600], eax
	mov dword[0x604], ecx

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
	dq 0x00cfba000000ffff
	dq 0x00cfb2000000ffff
	dq 0x00cffa000000ffff
	dq 0x00cff2000000ffff
	dq 0x3f4089fff5001b00
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

	mov edi, 0x5000
	mov ecx, 0x800
	xor eax, eax
	rep stosd

	mov dword[0x608], 0 ; TID

	; Initialize kernel data pages
	mov dword[0x5e0], 0x5001
	mov dword[0x5f8], 0x6001
	mov dword[0x5000], 0x83
	mov dword[0x5008], 0x4003
	mov dword[0x5ff8], 0x3003
	; TSS setup
	mov dword[0x504], 0x7b00
	mov word[0x508], 0x10
	mov word[0x560], 0x1300
	mov dword[0x3ff8], 0x0003

	; Initialize VRAM data pages
	mov edi, 0x6c00

	; Get VRAM size in megabytes
	; EBX=width,ECX=height
	mov	ebx, 1280
	mov ecx, 1024
	imul ecx, ebx
	shr ecx, 22
	inc ecx

	; Get VRAM pointer
	mov eax, dword[0x1228]
	and eax, 0xffdf0000
	mov al, 0x38

pageCreateVRAM:
	stosd
	add edi, 4
	add eax, 0x200000
	loop pageCreateVRAM

	; Set up page directory
	mov eax, 0x5e0
	mov cr3, eax

	; Set CR4.PSE for larger pages and CR4.PAE
	mov eax, cr4
	or eax, 0x00000030
	mov cr4, eax
	
	; Start paging
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax

	call initializeMemory

	; Start PID=0
	mov edi, 0x9000
	mov ax, 0x0014
	mov bx, 0x0000
	call registerContainer ; CODE DATA
	mov ax, dx
	mov bl, 0xdf
	mov ecx, kprocName_end-kprocName
	mov esi, kprocName
	call createProcedure

	mov ax, 0x38
	ltr ax

	; Run procedures
	jmp startScheduler
kprocName:
	db "kernelproc"
kprocName_end:
times 510 - ($ - $$) db 0
	dw 0xaa55
%include "kernel/memory.asm"
%include "kernel/container.asm"
%include "kernel/procedure.asm"
%include "kernel/link.asm"
%include "kernel/scheduler.asm"
times 512 * 4 - ($ - $$) db 0
	cli
	hlt
times 512 * 5 - ($ - $$) db 0