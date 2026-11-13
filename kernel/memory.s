initializeMemory:
	; Clear KABM
	mov ecx, 0x40000
	mov edi, 0x20000
	mov al, 0xff
	rep stosb
	; Initialize KABM
	movzx ecx, byte[0x504]
	mov edi, 0x60000
initializeMemory_loop:
	push ecx
	mov eax, dword[edi]
	shr eax, 11
	sub eax, 0x200
	mov ecx, dword[edi+8]
	shr ecx, 11
	inc ecx
initializeMemory_bitloop:
	btr dword[0x20000], eax
	inc eax
	loop initializeMemory_bitloop
	pop ecx
	loop initializeMemory_loop
	ret
