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

	push edx
	call mapDriver
	pop edx
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

endDriver:
	mov al, 2
	mov ebx, dword[0x180000-4+eax*4] 
	mov dh, 1
	int 0x34 ; free memory

	movzx eax, word[0x80000ffc]
	mov dword[0x180000-4+eax*4], 0
	ret

endDriver_error:
	stc
	ret

loadDriver:
	mov dword[loadDriver_data], eax
	mov byte[loadDriver_data+4], bl

	mov al, 2 ; allocates DDHNDL + PD + PT
	call pageAllocate

	push edx ; Save DDHNDL address for later

	mov eax, edx
	call registerDriver

	mov ebp, edx

	mov eax, dword[esp]

	and ax, 0xf000
	or ax, 0x0003
	mov dword[0x4010], eax

	mov edx, 0x202000
	int 0x30

	mov eax, dword[loadDriver_data]

	and ax, 0xf000
	or ax, 0x0003
	mov dword[0x4018], eax

	mov edx, 0x203000
	int 0x30

	mov eax, dword[loadDriver_data]

	and ax, 0x0fff

	movzx ecx, byte[loadDriver_data+4]
	shl ecx, 9

	mov esi, 0x203000
	add esi, eax

	mov edi, 0x202000
	rep movsb

	mov eax, dword[esp]
	add eax, 0x1000 ; page directory

	and ax, 0xf000
	or ax, 0x0003
	mov dword[0x4018], eax

	mov edx, 0x203000
	int 0x30

	mov eax, dword[esp]
	add eax, 0x2000 ; page table
	or ax, 0x0001
	mov dword[0x203000], eax

	and ax, 0xf000
	or ax, 0x0003
	mov dword[0x4018], eax

	mov edx, 0x203000
	int 0x30

	mov eax, dword[esp]
	or ax, 0x0003 ; code (R/W)
	mov dword[0x203000], eax

	mov ax, bp
	call mapDriver

	mov word[0x80000ffc], bp

	call 0x80000020

	pop edx
	ret

loadDriver_data:
	dd 0
	db 0