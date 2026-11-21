registerDriver:
	push eax ; Store driver ptr

	mov edi, 0x180000
	mov ecx, 0x10000
	xor eax, eax

	repne scasd
	jnz registerDriver_error

	pop eax
	mov dword[edi-4], eax

	not cx
	mov dx, cx

	inc dx

	clc
	ret

registerDriver_error:
	stc
	ret

runDriver:
	movzx ebx, bl
	and bl, 0x7

	call mapDriver
	jc runDriver_null

	mov eax, dword[0x80000000+ebx*4]
	test eax, eax

	jz runDriver_null

	call eax

	clc
	ret

runDriver_null:
	stc
	ret