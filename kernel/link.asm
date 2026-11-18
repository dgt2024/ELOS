giveContainer:
	movzx eax, ax

	cmp word[eax*8+0x1fffa], bx
	jne giveContainer_error

	mov ebp, dword[ebx*8+0x1fffc]
	and bp, 0xf000
	or bp, 0x0001

	; Map PDHNDL to temporary virtual address
	mov dword[0x6400], ebp
	invlpg[0x100000]

	mov edi, 0x100200

	mov edx, eax
	xor ax, ax
	mov ecx, 0x100
	; dx=hndl

	; Place HNDL in first empty slot
	repne scasw
	jne giveContainer_error

	mov word[edi-2], dx

	clc
	ret

giveContainer_error:
	stc
	ret