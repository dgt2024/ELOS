giveContainer:
	movzx eax, ax

	cmp word[eax*8+0x1fffa], bx
	jne giveContainer_error

	mov ebp, dword[ebx*8+0x1fffc]
	and bp, 0xf000
	or bp, 0x0005

	; Map PDHNDL to temporary virtual address
	mov dword[0x6400], ebp
	invlpg[0x100000]

	inc byte[0x10002c]

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

mapContainer:
	mov ebp, dword[ebx*8+0x1fffc]
	and bp, 0xf000
	or bp, 0x0005

	; Map PDHNDL to temporary virtual address
	mov dword[0x6400], ebp

	push ebp
	add ebp, 0x1000
	mov dword[0x6404], ebp
	pop ebp

	invlpg[0x100000]
	invlpg[0x101000]

	; find first empty slot in PD
	push eax ; save raw HNDL

	mov edi, 0x101000
	xor eax, eax
	mov ecx, 0x200

	repne scasd
	pop eax
	jne mapContainer_error

	mov ebp, dword[edi-4]

	test word[0x100034], 0x1ff
	jz mapContainer_newPT
mapContainer_afterNewPT:
	inc word[0x100034]

	mov dword[0x6400], ebp
	invlpg[0x100000]

	movzx eax, ax
	mov ebx, dword[eax*8+0x1fffc]

	cli
	hlt

mapContainer_newPT:
	; Allocates new page table and maps it to PDHNDL
	push eax ; Save raw HNDL
	mov al, 0
	call pageAllocate
	mov edi, edx
	mov ax, 0x0020
	call registerContainer
	mov ax, dx
	call getRawContainer
	call giveContainer

	inc byte[0x10002f] ; inc PDHNDL->PT#

	mov dword[edi-4], eax ; Store page table in PD
	mov ebp, eax
	pop eax
	jmp mapContainer_afterNewPT

mapContainer_error:
	stc
	ret