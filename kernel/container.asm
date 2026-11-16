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
	mov al, 0 ; Success
	ret
	
registerContainer_err:
	mov al, 1 ; Error
	ret
	
getRawContainer:
	movzx eax, ax
	
	; Null flags mean non-existent
	mov dx, word[eax * 8 + 0x20000] ; Container.flags
	test dx, dx
	jz getRawContainer_error
	
	mov edx, dword[eax * 8 + 0x20004] ; Container.pointer
	mov al, 0 ; Success
	ret
	
getRawContainer_error:
	mov al, 1 ; Error
	ret