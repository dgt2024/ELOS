; Linked Data Filesystem
ldfs_fdt:
	dd 0, 0, ldfs_readFunc, 0, 0, 0, 0, ldfs_ctrlFunc
times 0x20 - ($ - ldfs_fdt) db 0
	mov al, 0x00
	mov ebx, "LDFS"
	mov dh, 15
	int 0x33
	ret

ldfs_readFunc:
	cli
	mov eax, dword[0x7df8]
	mov dword[ldfs_pwd], eax

	mov ax, word[ldfs_disk]
	mov word[ldfs_pwd+4], ax

	mov bl, 0x80

	pushad
	mov edi, ldfs_free
	mov ecx, dword[ldfs_pwd]
	mov ax, word[ldfs_disk]
	mov dh, 13
	mov bl, 2
	int 0x33
	popad

ldfs_readFunc_loop:
	mov dword[ldfs_readFunc_ptr], edi
	mov esi, ldfs_free

	movzx ebp, word[ldfs_pwd+4]
	lea ebp, [esi+ebp]
	mov edx, ecx

	mov al, '/'
	repne scasb

	je ldfs_readFunc_fileItem

	mov bl, 0

ldfs_readFunc_fileItem:
	sub edx, ecx
	sub edi, edx
	dec edx
ldfs_readFunc_findLoop:
	cmp byte[esi+3], dl
	jne ldfs_readFunc_nextItem
	
	test byte[esi+2], bl
	jnz ldfs_readFunc_nextItem

	pushad
	mov edi, ldfs_free+512
	mov ecx, dword[esi+4]
	mov ax, word[ldfs_disk]
	mov dh, 13
	mov bl, 2
	int 0x33
	popad

	push edi
	push esi
	push ecx

	mov ecx, edx
	mov esi, ldfs_free+512
ldfs_readFunc_strcmp:
	lodsb

	scasb
	jne ldfs_readFunc_nextItem_ESIPUSH

	loop ldfs_readFunc_strcmp

	mov edi, ldfs_free
	mov ecx, 512
	rep movsb

	pop ecx
	pop esi
	pop edi

	add edi, edx
	mov esi, ldfs_free

	inc edi

	cmp byte[edi], 0
	jne ldfs_readFunc_loop

ldfs_readFunc_end:
	mov esi, ldfs_free
	mov ecx, 512
	rep movsb
	ret

ldfs_readFunc_ptr:
	dd 0

ldfs_readFunc_nextItem_ESIPUSH:
	pop esi
ldfs_readFunc_nextItem:
	add esi, 16

	cmp esi, ebp
	ja ldfs_readFunc_unexistent

	cmp dword[esi], 0xffffffff
	jne ldfs_readFunc_findLoop

ldfs_readFunc_nextPage:
	cli
	jmp $

ldfs_readFunc_unexistent:
	cli
	jmp $

ldfs_pwd:
	dd 0
	dw 0

ldfs_ctrlFunc:
	push ecx
	mov word[ldfs_mainDevType], cx

	mov eax, "PCI "
	mov dh, 14
	int 0x33

	mov ax, dx ; destination: PCI

	mov edi, ldfs_mainDevType
	mov ecx, 0
	mov dh, 13
	mov bl, 2
	int 0x33

	mov eax, dword[ldfs_mainDevType]

	mov edi, ldfs_mainDevMessage_ven
	mov ecx, 4
	call intToStr

	mov edi, ldfs_mainDevMessage_dev
	mov ecx, 4
	call intToStr

	mov edi, ldfs_mainDevMessage
	mov ecx, ldfs_mainDevMessage_end - ldfs_mainDevMessage
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33
	pop ecx

	mov word[ldfs_disk], cx
	ret

ldfs_mainDevType:
	dw 0, 0

ldfs_mainDevMessage:
	db "Main disk device set to "
ldfs_mainDevMessage_dev:
	db "XXXX:"
ldfs_mainDevMessage_ven:
	db "XXXX", 10
ldfs_mainDevMessage_end:

ldfs_disk:
	dw 0

ldfs_free:
