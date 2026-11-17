registerContainer:
	; Find unused container
	mov esi, 0x20000 ; offset container.flags
	mov dx, -1 ; -1 as loop increments first
	mov cx, ax
	
	; DX=handle,CX=flags,ESI=object_pointer
registerContainer_iterate:
	lodsw
	inc dx
	add esi, 6
	
	cmp esi, 0xa0000
	jae registerContainer_err
	
	test ax, ax
	jne registerContainer_iterate
	
	; Write to container
	mov word[esi-0x08], cx
	mov word[esi-0x06], bx
	mov dword[esi-0x04], edi
	clc ; Success
	ret
	
registerContainer_err:
	stc ; Error
	ret
	
getRawContainer:
	movzx eax, ax
	
	; Null flags mean non-existent
	mov dx, word[eax * 8 + 0x20000] ; Container.flags
	test dx, dx
	jz getRawContainer_error
	
	mov edx, dword[eax * 8 + 0x20004] ; Container.pointer
	clc ; Success
	ret
	
getRawContainer_error:
	stc ; Error
	ret