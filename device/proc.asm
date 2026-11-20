kernelProcMain:
	; note drivers were loaded from file descriptor table
	; Setup terminal output
	mov al, 2
	mov dh, 0
	int 0x30

	push edx ; Save DDHNDL for later

	mov eax, edx
	mov dh, 8
	int 0x30

	mov eax, dword[esp]

	mov dh, 12
	int 0x30

	mov eax, 0xa000
	mov dh, 11
	int 0x30

	mov esi, 0x3ff000
	mov edi, 0x3fe000
	mov ecx, 0x1000
	rep movsb

	mov eax, dword[esp]
	add eax, 0x1000 ; page directory

	mov dh, 11
	int 0x30

	mov eax, dword[esp]
	add eax, 0x2000 ; page table
	or ax, 0x0001
	mov dword[0x3ff000], eax

	mov dh, 11
	int 0x30

	mov eax, dword[esp]
	or ax, 0x0003 ; code (R/W)
	mov dword[0x3ff000], eax

	mov ax, 0
	mov dh, 9
	int 0x30

	call 0x80000020

	; change color to white on black
	mov cl, 0x0f
	mov ax, 0
	mov dh, 10
	mov bl, 7
	int 0x30

	; print string
	mov edi, str
	mov ecx, str_end-str
	mov ax, 0
	mov dh, 10
	mov bl, 6
	int 0x30

	cli
	jmp $

str:
	db "Hello, World!"
str_end: