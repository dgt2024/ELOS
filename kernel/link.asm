giveContainer:
	movzx eax, ax
	movzx ebx, bx

	cmp word[eax*8+0x1fffa], bx
	jne giveContainer_error

	mov ebp, dword[ebx*8+0x1fffc]
	and bp, 0xf000
	or bp, 0x0005

	; Map PDHNDL to temporary virtual address
	mov dword[0x4000], ebp

	mov edx, 0x200000
	int 0x30

	inc byte[0x20002c]

	mov edi, 0x200200

	mov edx, eax
	xor ax, ax
	mov ecx, 0x100
	; dx=hndl

	; Place HNDL in first empty slot
	repne scasw
	jne giveContainer_error

	mov word[edi-2], dx
	inc byte[edx*8+0x1fffc] ; Increments HNDL->LINK#

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
	mov dword[0x4000], ebp

	push ebp
	add ebp, 0x1000 ; CR3
	mov dword[0x4008], ebp
	pop ebp

	mov edx, 0x200000
	int 0x30
	mov edx, 0x201000
	int 0x30

	; find first empty slot in PD
	push eax ; save raw HNDL

	mov edi, 0x201000
	xor eax, eax
	mov ecx, 0x200

mapContainer_loop:
	scasd
	je mapContainer_found
	add edi, 4
	loop mapContainer_loop

	pop eax
	jmp mapContainer_error

mapContainer_found:
	pop eax

	mov ebp, dword[edi-12]

	test word[0x200034], 0x1ff
	jz mapContainer_newPT

mapContainer_afterNewPT:
	inc word[0x200034]

	or bp, 0x3
	mov dword[0x4000], ebp

	mov edx, 0x200000
	int 0x30

	movzx eax, ax
	mov ebx, dword[eax*8+0x1fffc] ; low 32-bit
	mov cl, byte[eax*8+0x1fff8]
	xor eax, eax ; high 32-bit

	or bl, 0x01 ; present

	test cl, 0x07
	jz mapContainer_kernelMap
	or bl, 0x04 ; supervisor
mapContainer_kernelMap:
		
	test cl, 0x02
	jz mapContainer_writeMap
	or bl, 0x02 ; r/w bit
mapContainer_writeMap:

	test cl, 0x04
	jnz mapContainer_codeMap
	or eax, 0x80000000
mapContainer_codeMap:

	push eax ; save high 64-bit
	; Find empty PTE
	mov edi, 0x200000
	mov ecx, 0x200
	xor eax, eax

mapContainer_loopPTE:
	scasd
	je mapContainer_foundPTE
	add edi, 4
	loop mapContainer_loopPTE

	pop eax
	jmp mapContainer_error

mapContainer_foundPTE:
	pop eax

	mov dword[edi-4], ebx
	mov dword[edi], eax

	clc
	ret

mapContainer_newPT:
	; Allocates new page table and maps it to PDHNDL
	push eax ; Save raw HNDL
	push edi ; Save PD

	mov al, 0
	call pageAllocate
	mov edi, edx
	mov ax, 0x0020
	call registerContainer
	mov ax, dx
	call getRawContainer
	push edx
	call giveContainer
	pop edx

	inc byte[0x20002f] ; inc PDHNDL->PT#

	pop edi ; save PD

	or dx, 0x0001
	mov dword[edi-4], edx ; Store page table in PD
	mov ebp, edx

	pop eax
	jmp mapContainer_afterNewPT

mapContainer_error:
	stc
	ret

mapDriver:
	movzx eax, ax

	; Calculate page directory address
	mov eax, dword[0x180000-4+eax*4]
	test eax, eax

	jz mapDriver_error

	add eax, 0x1000
	and ax, 0xf000
	or ax, 0x0001

	mov dword[0x200070], eax ; PDPT[3]

	mov edx, 0x80000000
	int 0x30
	ret

mapDriver_error:
	stc
	ret