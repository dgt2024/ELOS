registerInterrupt:
	movzx eax, al
	cmp word[0x3000+eax*2], 0
	jne registerInterrupt_err

	mov word[0x3000+eax*2], bx

	mov dword[0x802+eax*8], 0xae000019
	mov word[0x800+eax*8], IRQCall
	clc
	ret

registerInterrupt_err:
	stc
	ret

IRQCall:
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
	iretd