; Global Functions
;	registerContainer -> EDI=PTR,AX=FLAGS,BL=TYPE,BH=OWNER -> AL=STATUS,DX=HANDLE
registerContainer:
	mov esi, 0x60002
	mov dx, -1
	mov cx, ax
registerContainer_iterate:
	lodsb
	inc dx
	add esi, 7
	cmp esi, 0xa0000
	jae registerContainer_err
	cmp al, 0
	jne registerContainer_iterate
	mov word[esi-0x0a], cx
	mov word[esi-0x08], bx
	mov dword[esi-0x06], edi
	mov al, 0
	ret
registerContainer_err:
	mov al, 1
	ret
	