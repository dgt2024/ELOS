; This is the ELOS7 Source Code
; 0x5000 PD
; 0x6000 PT <1MB IP
; Memory Map
; 0x500 X res
; 0x502 Y res
; 0x504 LFB (physical)
; 0x508 TSC start
; 0x510 Object Count
; 0x511 Process Count
section .boot
global start
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
	rdtsc
	mov dword[0x508], eax
	mov dword[0x50c], ecx
	mov ax, 0x0201
	mov bx, 0x7c00
	mov cx, 0x0001
	mov dh, 0
	int 0x13
	mov ax, 0x4f15
	xor bx, bx
	xor cx, cx
	mov es, bx
	xor di, di
	int 0x10
	cmp ax, 0x004f
	jne vesa_error
	mov ax, 0x4f15
	mov bl, 0x01
	xor dx, dx
	mov di, 0x1000
	int 0x10
	cmp ax, 0x004f
	jne vesa_error
	; Get X resolution
	mov al, byte[0x1038]
	mov byte[0x500], al
	mov al, byte[0x103a]
	shr al, 0x04
	mov byte[0x501], al
	; Get Y resolution
	mov al, byte[0x103b]
	mov byte[0x502], al
	mov al, byte[0x103d]
	shr al, 0x04
	mov byte[0x503], al
	; Get LFB address
	mov ax, 0x4f01
	mov cx, word[0x500]
	shr cx, 3
	sub cx, 32
	mov ch, 0x41
	mov di, 0x1000
	push cx
	int 0x10
	test byte[0x1000], 0x80
	jz vesa_error
	; Store and set videomode
	mov eax, dword[0x1028]
	mov dword[0x504], eax
	mov ax, 0x4f02
	pop bx
	int 0x10
	; Set RAM sectors
	xor ebx, ebx
	mov ax, 0x6000
	mov es, ax
	mov di, 0x0000
	mov byte[0x504], 0
ram_find:
	mov eax, 0xe820
	mov ecx, 24
	mov edx, 0x534D4150
	int 0x15
	jc ram_find
	cmp eax, 0x534D4150
	jne ram_find
	cmp ebx, 0
	je ram_find_end
	cmp dword[es:di+0x4], 0
	jne ram_find
	cmp dword[es:di+0x10], 1
	jne ram_find
	mov eax, dword[es:di]
	cmp eax, 0x100000
	jb ram_find
	add di, 16
	inc byte[0x504]
	jmp ram_find
ram_find_end:
	; Start protected mode
	lgdt [gdt_table]
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax
	jmp 0x08:main
	hlt
vesa_error:
	cli
	hlt
gdt_table:
	dw gdt_descriptor_table_end - gdt_descriptor_table - 1
	dd gdt_descriptor_table
gdt_descriptor_table:
	dq 0
	dq 0x00cf9a000000ffff
	dq 0x00cf92000000ffff
gdt_descriptor_table_end:
use32
main:
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
page_dir_sys_mb:
	stosd
	add eax, 0x1000
	loop page_dir_sys_mb
	; Initialize VRAM PD
	mov edi, 0x5f00
	movzx ebx, word[0x500]
	movzx ecx, word[0x502]
	imul ecx, ebx
	shr ecx, 22
	inc ecx
	mov eax, dword[0x504]
	and eax, 0xffdf0000
	mov al, 0x83
page_dir_vram:
	stosd
	add eax, 0x400000
	loop page_dir_vram
	; Start paging (CR4.PSE set)
	mov eax, 0x5000
	mov cr3, eax
	mov eax, cr4
	or eax, 0x00000010
	mov cr4, eax
	mov eax, cr0
	or eax, 0x80000001
	mov cr0, eax
	; Clear KABM
	mov ecx, 0x40000
	mov edi, 0x20000
	mov al, 0xff
	rep stosb
	; Initialize KABM
	movzx ecx, byte[0x504]
	mov edi, 0x60000
kabm_init_loop:
	push ecx
	mov eax, dword[edi]
	shr eax, 11
	sub eax, 0x200
	mov ecx, dword[edi+8]
	shr ecx, 11
	inc ecx
kabm_bit_loop:
	btr dword[0x20000], eax
	inc eax
	loop kabm_bit_loop
	pop ecx
	loop kabm_init_loop
	cli
	hlt
section .signature
	dw 0xaa55
