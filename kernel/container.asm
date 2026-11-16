registerContainer:
	; Find unused container
	mov esi, 0x60000 ; Container.Flags
	mov dx, -1 ; 0 -1(incremented in start)
	mov cx, ax ; CX=Container Flags
	
	; Iterate
registerContainer_iterate:
	; Get data and iterate
	lodsw
	inc dx
	add esi, 6
	cmp esi, 0xa0000 ; Has overflown?
	jae registerContainer_err
	cmp al, 0 ; Are flags set?
	jne registerContainer_iterate
	mov word[esi-0x08], cx ; Set Flags
	mov word[esi-0x06], bx ; Set Type/Owner
	mov dword[esi-0x04], edi ; Set Pointer
	mov al, 0 ; Success
	ret
registerContainer_err:
	mov al, 1 ; Error
	ret
	