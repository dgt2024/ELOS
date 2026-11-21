kernelProcMain:
	; note drivers were loaded from file descriptor table
	; Setup terminal output
	mov esi, fileDescriptorTable+6 ; 3rd index on

kernelProcMain_initLoop:
	push esi ; Save FDT entry

	mov al, 2 ; allocates DDHNDL + PD + PT
	mov dh, 0
	int 0x31

	push edx ; Save DDHNDL for later

	mov eax, edx
	mov dh, 8
	int 0x31

	mov ebp, edx

	mov eax, dword[esp]

	mov dh, 14
	int 0x31

	movzx esi, dword[esp+4]
	movzx eax, word[esi]
	shl eax, 4

	mov dh, 13
	int 0x31

	mov esi, 0x3ff000
	mov edi, 0x3fe000
	mov ecx, 0x200
	rep movsb

	mov eax, dword[esp]
	add eax, 0x1000 ; page directory

	mov dh, 13
	int 0x31

	mov eax, dword[esp]
	add eax, 0x2000 ; page table
	or ax, 0x0001
	mov dword[0x3ff000], eax

	mov dh, 13
	int 0x31

	mov eax, dword[esp]
	or ax, 0x0003 ; code (R/W)
	mov dword[0x3ff000], eax

	mov ax, bp
	mov dh, 9
	int 0x31

	mov word[0x80000ffc], bp
	call 0x80000020

	pop edx
	pop esi

	add esi, 3
	cmp esi, fileDescriptorTable_end
	jb kernelProcMain_initLoop

	; change color to white on black
	mov cl, 0x0f
	mov ax, 0
	mov dh, 11
	mov bl, 7
	int 0x31

	; print string2
	mov edi, str
	mov ecx, str_end-str
	mov ax, 0
	mov dh, 11
	mov bl, 6
	int 0x31

	cli
	jmp $

str:
	db "Hello, World!"
str_end: