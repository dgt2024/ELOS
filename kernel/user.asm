userAllocate:
	call pageAllocate

	mov edi, edx
	mov ax, 0x0007
	mov bx, word[0x612]
	call registerContainer

	mov ax, dx
	push eax
	mov bx, word[0x612]
	call giveContainer
	
	mov eax, dword[esp]

	mov bx, word[0x612]
	call mapContainer
	pop edx
	ret