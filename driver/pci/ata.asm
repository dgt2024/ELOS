; ATA driver (PCI native and IDE legacy)
ata_fdt:
	dd ata_initFunc, 0, ata_readFunc, 0, ata_fnshFunc, 0, 0, 0
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

ata_initFunc:
	push ecx ; save PCI data

	mov ebx, ecx
	mov al, 0x01
	mov dh, 15
	int 0x33
	push edx

	mov word[ata_initFunc_pciData], dx ; dx=PCI DVHNDL

	mov eax, "PCI "
	mov dh, 14
	int 0x33

	mov ax, dx ; destination: PCI

	mov edi, ata_initFunc_pciData ; ata read PCI device
	mov cl, 0x8
	mov dh, 13
	mov bl, 2
	int 0x33

	movzx eax, byte[ata_deviceCount]
	lea ebp, [ata_devices+eax*8]

	mov al, byte[ata_initFunc_pciData+1]

	mov word[ebp], 0x1f0
	mov word[ebp+4], 0x3f6

	test al, 0x01
	jz ata_initFunc_nativePrimary

	push eax
	mov edi, ata_initFunc_pciData ; ata read PCI device
	mov cl, 0x10
	mov dh, 13
	mov bl, 2
	int 0x33

	mov ax, word[ata_initFunc_pciData] ; BAR0 address
	mov word[ebp], ax

	mov edi, ata_initFunc_pciData ; ata read PCI device
	mov cl, 0x14
	mov dh, 13
	mov bl, 2
	int 0x33

	mov ax, word[ata_initFunc_pciData] ; BAR0 address
	mov word[ebp+4], ax
	pop eax

ata_initFunc_nativePrimary:
	mov word[ebp+2], 0x170
	mov word[ebp+6], 0x376

	test al, 0x04
	jz ata_initFunc_nativeSecondary

	push eax
	mov edi, ata_initFunc_pciData ; ata read PCI device
	mov cl, 0x18
	mov dh, 13
	mov bl, 2
	int 0x33

	mov ax, word[ata_initFunc_pciData] ; BAR0 address
	mov word[ebp+2], ax

	mov edi, ata_initFunc_pciData ; ata read PCI device
	mov cl, 0x1c
	mov dh, 13
	mov bl, 2
	int 0x33

	mov ax, word[ata_initFunc_pciData] ; BAR0 address
	mov word[ebp+6], ax
	pop eax

ata_initFunc_nativeSecondary:
	mov dx, word[ebp+4]
	mov al, 2
	out dx, al

	mov dx, word[ebp+6]
	mov al, 2
	out dx, al

	pop edx
	mov ax, dx ; delete dummy
	mov dh, 16
	int 0x33

	pop ecx ; PCI device
	mov ebx, ecx

	mov ecx, 4 ; primary/secondary, master/slave
ata_initFunc_find:
	dec ecx
	push ecx ; find port (primary/secondary)
	and cl, 0x02
	mov dx, [ebp+ecx]
	pop ecx

	; code hand-compiled from https://wiki.osdev.org/PCI_IDE_Controller
	mov al, cl
	and al, 0x01
	shl al, 4
	or al, 0xa0 ; select drive (master/slave)

	add dx, 0x06 ; port+6
	out dx, al

	mov al, 0xec
	inc dx ; port+7
	out dx, al

	in al, dx
	cmp al, 0
	je ata_initFunc_nodev

ata_initFunc_poll:
	in al, dx

	test al, 0x01
	jnz ata_initFunc_nodev

	test al, 0x80
	jnz ata_initFunc_poll
	
	test al, 0x08
	jz ata_initFunc_poll

	sub dx, 7

	push edi
	mov ecx, 128
	lea edi, [ata_devices+512]
	rep insd
	pop edi

	push ebx
	push ecx
	push edx

	mov bl, byte[ata_deviceCount]
	or bl, cl
	mov al, 0x01
	mov dh, 15
	int 0x33

	cmp word[ata_mainDevice], 0
	jne ata_initFunc_notmain

	mov word[ata_mainDevice], dx

ata_initFunc_notmain:
	pop edx
	pop ecx
	pop ebx

	; print init on COM1
	mov edi, ata_initStr
	mov ecx, ata_initStr_end - ata_initStr
	mov ax, 0 ; linux' /dev/ttyS0
	mov dh, 13
	mov bl, 6
	int 0x33
ata_initFunc_nodev:
	inc ecx
	loop ata_initFunc_find

	add byte[ata_deviceCount], 4
	ret

ata_readFunc:
	call ata_useDevice
	add dx, 2 ; port+7
	mov al, 0x20 ; ATA_CMD_READ_PIO = 0x20
	out dx, al
	
	add dx, 5 ; port+12
	times 4 in al, dx ; wait 400ns

	sub dx, 5 ; port+7
ata_waitBsy:
	in al, dx

	test al, 0x80
	jnz ata_waitBsy

	mov ecx, 0x100
	sub dx, 7 ; port+0
	rep insw
	ret

ata_useDevice:
	push edx ; save device

	movzx eax, dl
	and al, 0x02

	movzx ebx, dl
	and bl, 0xfc
	shl ebx, 1

	mov dx, word[ata_devices+eax+ebx]

ata_useDevice_pollWait:
	add dx, 7 ; port+7
	in al, dx
	test al, 0x80
	jnz ata_useDevice_pollWait

	pop eax ; set slave bit
	dec dx ; port+6
	and al, 0x01
	shl eax, 4

	rol ecx, 8 ; get head

	or al, cl
	or al, 0xe0 ; AL=0xe0 | slave << 4 | head

	out dx, al

	sub dx, 4 ; port+2
	mov al, 1 ; 1 sector
	out dx, al

	mov eax, ecx
	mov ecx, 3
ata_useDevice_lbaset:
	shr eax, 8
	inc dx ; port+3, port+4, port+5

	out dx, al
	loop ata_useDevice_lbaset
	ret

ata_fnshFunc:
	cmp edx, "ATA "
	jne ata_fnshFunc_NA
	mov eax, edx
	mov dh, 14
	int 0x33
	
	mov ax, dx ; destination: LDFS
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

ata_pciData:
	db 0x6
	dw 0
	dd 0x000101 ; class 1, subclass 1

ata_initFunc_pciData:
	dw 0, 0

ata_deviceCount:
	db 0

ata_readFunc_data:
	db 0, 0, 0, 0, 0, 0

ata_devices: