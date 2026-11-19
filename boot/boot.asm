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
	xor bx, bx
	mov cx, 0x0002
	mov dh, 0
	mov si, fileDescriptorTable
	mov bp, fileDescriptorTable_end

fileDescriptorRead:
	mov ax, word[si]
	mov es, ax ; segment

	mov al, byte[si+2] ; size
	mov ah, 0x02
	int 0x13

	add si, 3
	add cl, al ; next
	cmp si, bp
	jb fileDescriptorRead

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
	jmp 0x08:main