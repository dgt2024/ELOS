initializeDrivers:
	mov esi, fileDescriptorTable_driver ; start
	mov ebp, fileDescriptorTable_end ; end
	mov edi, 0xf000

initializeDrivers_loop:
	push edi ; save driver ptr
	movzx edi, word[esi]
	shl edi, 4 ; segment

	mov al, 0
	mov ah, byte[esi+2]
	shr ah, 2 ; 512B sectors -> 4kB pages
	and ah, 0x0f ; limit to 16 pages
	or di, ax

	mov ax, 0x0010 ; DDHNDL
	mov bx, 0x0000 ; no one owns it, systemwide

	push esi
	call registerContainer
	pop esi
	pop edi

	mov word[edi], dx

	add edi, 2
	add esi, 3

	cmp esi, ebp
	jb initializeDrivers_loop
	ret