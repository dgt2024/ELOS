; PCI driver loader
pci_fdt:
	dd pci_initFunc, 0, pci_readFunc, 0, 0, 0, 0, 0
times 0x20 - ($ - pci_fdt) db 0
	mov edi, pci_initMessage
	mov ecx, pci_initMessage_end - pci_initMessage
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33

	mov al, 0x00
	mov ebx, "PCI "
	mov dh, 15
	int 0x33
	ret

pci_readFunc:
	movzx eax, word[edi]
	mov eax, dword[0x100004+eax*8]
	mov al, cl
	call pci_readPort
	stosd
	ret

pci_initFunc:
	pushad
	movzx esi, word[edi+1]
	lea esi, [0x100004+esi*8]
	mov edi, pci_devInitMessage_str
	mov ecx, 4
	rep movsb

	mov edi, pci_devInitMessage
	mov ecx, pci_devInitMessage_end - pci_devInitMessage
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33
	popad

	mov ebx, 0x80000000
	mov ecx, 0x10000

	test byte[edi], 0x08
	jz pci_initFunc_typeloop

pci_initFunc_loop:
	mov eax, ebx
	call pci_readPort

	test byte[edi], 0x04
	jz pci_initFunc_skipdevice

	cmp ax, word[edi+3]
	je pci_initFunc_found

pci_initFunc_skipdevice:

	cmp ax, word[edi+5]
	je pci_initFunc_found

	add ebx, 0x800
	loop pci_initFunc_loop
	ret

pci_initFunc_typeloop:
	mov bl, 0x08
	mov eax, ebx
	call pci_readPort

	rol eax, 8
	test byte[edi], 0x04
	jz pci_initFunc_skipclass

	cmp al, byte[edi+3]
	jne pci_initFunc_typeloopiterate

pci_initFunc_skipclass:
	rol eax, 8
	test byte[edi], 0x02
	jz pci_initFunc_skipsubclass

	cmp al, byte[edi+4]
	jne pci_initFunc_typeloopiterate

pci_initFunc_skipsubclass:
	rol eax, 8
	test byte[edi], 0x01
	jz pci_initFunc_skipprogif

	cmp al, byte[edi+5]
	jne pci_initFunc_typeloopiterate
pci_initFunc_skipprogif:
	jmp pci_initFunc_found

pci_initFunc_typeloopiterate:
	add ebx, 0x100
	loop pci_initFunc_typeloop

	pushad
	movzx esi, word[edi+1]
	lea esi, [0x100004+esi*8]
	mov edi, pci_devEndMessage_str
	mov ecx, 4
	rep movsb

	mov edi, pci_devEndMessage
	mov ecx, pci_devEndMessage_end - pci_devEndMessage
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33
	popad

	mov ecx, ebx
	mov ax, word[edi+1] ; PCI device waiting
	mov dh, 13
	mov bl, 4
	int 0x33
	ret

pci_initFunc_found:
	pushad
	mov ecx, ebx
	mov ax, word[edi+1] ; PCI device waiting
	mov dh, 13
	mov bl, 0
	int 0x33
	popad
	jmp pci_initFunc_typeloopiterate

pci_readPort:
	mov dx, 0xcf8
	out dx, eax

	mov dx, 0xcfc
	in eax, dx
	ret

pci_initMessage:
	db "Initializing PCI devices...", 10
pci_initMessage_end:

pci_devInitMessage:
	db "Probing for all devices type '"
pci_devInitMessage_str:
	db "XXXX'", 10
pci_devInitMessage_end:

pci_devEndMessage:
	db "Found all devices type '"
pci_devEndMessage_str:
	db "XXXX'", 10
pci_devEndMessage_end: