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
	mov dword[0x614], esp
	mov word[0x580], 0x21
	mov dword[0x57c], 0x7400
	mov dword[0x578], 0x1202
	mov word[0x574], 0x19
	mov dword[0x570], IRQCall_r1

	mov esp, 0x570
	iretd

IRQCall_r1:
	cli
	pushad
	mov ax, word[0x700]
	mov bl, 2
	mov cl, 1
	call runDevice
	movzx eax, byte[0x702]
	mov ax, word[0x3000+eax*2]
	mov bl, 3
	mov cl, 1
	call runDevice
	mov ax, word[0x700]
	mov bl, 6
	mov cl, 0
	call runDevice
	popad
	int 0x35

IRQCall_return:
	mov esp, dword[0x614]
	iretd