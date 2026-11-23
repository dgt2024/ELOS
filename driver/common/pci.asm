pci_fdt:
	dd pci_initFunc, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - pci_fdt) db 0
	mov edi, pci_initMessage
	mov ecx, pci_initMessage_end - pci_initMessage
	mov ax, 1 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33

	mov al, 0x00
	mov ebx, "PCI "
	mov dh, 15
	int 0x33
	ret

pci_initFunc:
	cli
	jmp $

pci_initMessage:
	db "Initializing PCI devices...", 10
pci_initMessage_end: