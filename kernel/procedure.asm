createProcedure:
	push ecx ; Save title size
	push esi ; Save title addr
	push edx ; Save Parent TID
	push bx ; Save flags
	push ax ; Save code container HNDL
	
	mov al, 1
	call pageAllocate
	mov edi, edx
	or di, 0x100
	mov ax, 0x0020
	call registerContainer
	mov cx, dx ; Store HNDL in cx

	mov ax, dx
	call getRawContainer
	and dx, 0xf000 ; Remove SZ and LINK#
	or dx, 0x0001
	
	; Create temporal virtual address
	mov dword[0x6400], edx
	
	push edx
	add edx, 0x1000
	mov dword[0x6404], edx
	pop edx
	
	invlpg[0x100000]
	invlpg[0x101000]
	
	; Clear CR3 (page directory)
	push ecx
	mov edi, 0x101000
	mov ecx, 0x200
	xor eax, eax
	rep stosd
	pop ecx
	
	mov edi, 0x100000
	; edi=virtual page data,edx=physical page data,cx=PDHNDL
	
	pop ax ; code container HNDL
	call getRawContainer
	
	mov dword[edi+0x20], 0x3000 ; PDHNDL->EIP
	mov dword[edi+0x24], 0x202 ; PDHNDL->EFLAGS
	
	inc dword[0x608]
	mov eax, dword[0x608]
	mov dword[edi+0x28], eax ; PDHNDL->TID
	
	mov dword[edi+0x2c], 0x101000 ; PDHNDL->CR3
	
	pop bx ; Load flags
	mov byte[edi+0x30], bl ; PDHNDL->FLAGS (low byte)
	mov byte[edi+0x31], 0x80
	
	xor eax, eax
	mov dword[edi+0x34], eax ; PDHNDL->SENT#|SYSC#
	
	pop edx
	mov dword[edi+0x38], edx ; PDHNDL->DESC.TID
	mov dword[edi+0x3c], eax ; PDHNDL->UPTIME
	mov byte[edi+0x52], al ; PDHNDL->N#
	mov dword[edi+0x54], eax ; PDHNDL->ALLOC#
	mov dword[edi+0x58], eax ; PDHNDL->ALLOCADDR
	
	mov dx, cx ; Save PDHNDL to dx
	
	pop esi
	pop ecx
	add edi, 0x60
	
	cmp ecx, 0x20
	ja createProcedure_clamp
createProcedure_afterclamp:
	rep movsb
	
	mov ax, dx
	call registerProcedure
	ret
	
createProcedure_clamp:
	mov ecx, 0x20
	jmp createProcedure_afterclamp

registerProcedure:
	mov esi, 0xc000
	mov bx, ax
registerProcedure_loop:
	lodsw
	
	cmp esi, 0x100000
	jae registerProcedure_error
	
	test ax, ax
	jnz registerProcedure_loop
	
	mov word[esi-2], bx
	
	clc
	ret
	
registerProcedure_error:
	stc
	ret