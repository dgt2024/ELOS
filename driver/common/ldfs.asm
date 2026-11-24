; Linked Data Filesystem
ldfs_fdt:
	dd 0, 0, 0, 0, 0, 0, 0, ldfs_ctrlFunc
times 0x20 - ($ - ldfs_fdt) db 0
	mov al, 0x00
	mov ebx, "LDFS"
	mov dh, 15
	int 0x33
	ret

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