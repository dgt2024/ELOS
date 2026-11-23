runDevice:
	sub esp, 8

	test byte[esp+15], 0x80
	jz runDevice_driverCall

	push eax ; save eax (ops will ocurr)

	add edi, 0x40000000

	mov eax, dword[0x200078]
	mov dword[esp+4], eax

	mov eax, dword[0x20007c]
	mov dword[esp+8], eax

	mov eax, dword[0x200070]
	mov dword[0x200078], eax ; 0x80000000 -> 0xc0000000

	mov eax, dword[0x200074]
	mov dword[0x20007c], eax
	int 0x32

	pop eax ; reload

runDevice_driverCall:

	movzx eax, ax

	cmp byte[0x100000+eax*8], 0
	je runDevice_error

	mov edx, dword[0x100004+eax*8]
	mov ax, word[0x100002+eax*8]

	call runDriver

	pushf

	test byte[esp+19], 0x80
	jz runDevice_driverCallReturn

	mov eax, dword[0x200078]
	mov dword[0x200070], eax

	mov eax, dword[0x20007c]
	mov dword[0x200074], eax

	mov eax, dword[esp+4]
	mov dword[0x200078], eax

	mov eax, dword[esp+8]
	mov dword[0x20007c], eax
	int 0x32
	
runDevice_driverCallReturn:
	popf

	add esp, 8

	ret

runDevice_error:
	stc
	ret

createDevice:
	push eax ; save type

	movzx edi, al
	shl edi, 9
	add edi, 0x1e0000 ; device type dev_type

	xor ax, ax
	mov ecx, 0x100

	repne scasw
	jnz createDevice_error

	not cl
	inc cl
	mov dl, cl ; save ID for later

	mov esi, 0x100000
	xor ax, ax
	mov ecx, 0x10000

createDevice_loop:
	cmp byte[esi], 0
	je createDevice_found

	add esi, 8
	loop createDevice_loop
createDevice_found:
	not cx
	inc cx

	pop eax

	mov byte[esi], dl
	mov byte[esi+1], al
	mov dx, word[0x80000ffc] ; DDHNDL of current driver
	; Only drivers can create devices unless
	; its a ring 1 device and you have driver loaded

	mov word[esi+2], dx
	mov dword[esi+4], ebx

	mov word[edi-2], dx ; write ID

	mov dx, cx
	
	clc
	ret

createDevice_error:
	stc
	ret

searchDevice:
	mov edi, 0x100004
	mov ecx, 0x10001

searchDevice_loop:
	scasd
	je searchDevice_found

	loop searchDevice_loop

	stc
	ret

searchDevice_found:
	not cx
	mov dx, cx
	
	clc
	ret
