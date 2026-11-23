ata_fdt:
	dd ata_initFunc, 0, 0, 0, 0, 0, 0, 0
times 0x20 - ($ - ata_fdt) db 0
	mov al, 0x01
	mov ebx, "ATA "
	mov dh, 15
	int 0x33

	mov word[ata_pciData+1], dx

	mov eax, "PCI "
	mov dh, 14
	int 0x33

	mov ax, dx ; destination: PCI

	mov edi, ata_pciData
	mov dh, 13
	mov bl, 0
	int 0x33
	ret

ata_pciData:
	db 0x6
	dw 0
	dd 0x000101 ; class 1, subclass 1

ata_initFunc:
	cli
	jmp $
	ret