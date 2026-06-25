sysinit.main:
	; 0x80 kernel 0x40 ram 0x01 I/O
	mov al, 0x30
	out 0x70, al
	in al, 0x71
	mov bl, al
	mov al, 0x31
	out 0x70, al
	in al, 0x71
	mov bh, al
	movzx ebx, bx
	shl ebx, 10
	add ebx, 0x100000
	mov dword[0x1a18], ebx
	mov ecx, 0x7a00-0x4b0
	mov edi, sysinit_memory.main
	mov ah, 0x07
	int 0x30
	call master.poll
	mov edi, 0x00800003
	mov bx, 2
	call master.recv
	int 0x30
	call master.poll
	movzx ebx, word[0x1a6e]
	add edi, ebx
	mov ecx, edi
	mov edi, sysinit_pci.main
	mov ah, 0x07
	int 0x30
	call master.poll
	mov edi, 0x80000003
	mov bx, 2
	call master.recv
	int 0x30
	jmp $