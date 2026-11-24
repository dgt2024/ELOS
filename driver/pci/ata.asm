; ATA driver (PCI native and IDE legacy)
ata_fdt:
	dd ata_initFunc, 0, 0, 0, ata_fnshFunc, 0, 0, 0
times 0x20 - ($ - ata_fdt) db 0
	mov al, 0x00
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
	mov al, 0x01
	mov ebx, ecx
	mov dh, 15
	int 0x33

	cmp word[ata_mainDevice], 0
	jne ata_initFunc_notmain

	mov word[ata_mainDevice], dx

ata_initFunc_notmain:

	; print init on COM1
	mov edi, ata_initStr
	mov ecx, ata_initStr_end - ata_initStr
	mov ax, 1 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33
	ret

ata_fnshFunc:
	cmp edx, "ATA "
	jne ata_fnshFunc_NA
	mov eax, edx
	mov dh, 14
	int 0x33
	
	mov ax, dx ; destination: PCI
	mov dh, 16
	int 0x33

	mov eax, "LDFS"
	mov dh, 14
	int 0x33

	; print string2 on COM1
	mov ax, dx

	mov cx, word[ata_mainDevice]
	mov dh, 13
	mov bl, 7
	int 0x33
ata_fnshFunc_NA:
	ret

ata_mainDevice:
	dw 0

ata_initStr:
	db "ATA device found!", 10
ata_initStr_end: