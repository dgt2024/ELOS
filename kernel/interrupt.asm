registerInterrupt:
	movzx eax, al
	cmp word[0x3000+eax*2], 0
	jne registerInterrupt_err

	mov word[0x3000+eax*2], bx

	mov dword[0x802+eax*8], 0xae000008
	mov word[0x800+eax*8], IRQCall
	clc
	ret

registerInterrupt_err:
	stc
	ret

IRQCall:
	cli
	mov dword[0x614], esp
	mov word[0x5a0], 0x21
	mov dword[0x59c], 0x7400
	mov dword[0x598], 0x1002
	mov word[0x594], 0x19
	mov dword[0x590], IRQCall_switch

	mov word[0x504], 0x7a00

	mov esp, 0x590
	iretd

IRQCall_switch:
	pushad
	mov ax, word[0x700]
	mov bl, 2
	mov cl, 1
	call runDevice
	movzx eax, byte[0x702]
	mov ax, word[0x3000+eax*2]
	mov bl, 3
	call runDevice
	mov ax, word[0x700]
	mov bl, 6
	mov cl, 0
	call runDevice
	popad
	int 0x30

IRQCall_return:
	cli
	mov word[0x504], 0x7800

	mov esp, dword[0x614]
	iretd

	push eax
	mov eax, 0x77ec
	mov dr0, eax
	mov eax, 0xd0001
	mov dr7, eax
	pop eax